import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'export includes complete app data and excludes credentials and metadata',
      () async {
    SharedPreferences.setMockInitialValues({
      'workouts': <String>['legacy workout'],
      'workouts_2026-10-22': <String>['daily workout'],
      'exercise_sets_벤치 프레스_2026-10-22': <String>['set'],
      'recorded_dates_벤치 프레스': <String>['2026-10-22'],
      'body_change_record_체중': <String>['body'],
      'workout_routines': <String>['routine'],
      'custom_exercises': <String>['exercise'],
      'use_lbs': true,
      'isDarkMode': true,
      'first_record_date': '2026-10-22',
      'enable_workout_recommendation': false,
      'supabase.auth.token': 'secret-session',
      'supabase.auth.token-code-verifier': 'secret-pkce',
      'cloud_sync_device_id': 'device-id',
      'cloud_sync_last_uploaded_at': 'metadata',
      'rest_fab_visible': true,
      'unrelated_plugin_key': 'do-not-export',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = CloudSyncService(prefs);

    final snapshot = await service.exportSnapshot();
    final exported = Map<String, dynamic>.from(snapshot['preferences'] as Map);

    expect(snapshot['version'], CloudSyncService.snapshotVersion);
    expect(snapshot, isNot(contains('deviceId')));
    expect(
      exported.keys,
      containsAll(<String>[
        'workouts',
        'workouts_2026-10-22',
        'exercise_sets_벤치 프레스_2026-10-22',
        'recorded_dates_벤치 프레스',
        'body_change_record_체중',
        'workout_routines',
        'custom_exercises',
        'use_lbs',
        'isDarkMode',
        'first_record_date',
        'enable_workout_recommendation',
      ]),
    );
    expect(exported, isNot(contains('supabase.auth.token')));
    expect(exported, isNot(contains('supabase.auth.token-code-verifier')));
    expect(exported, isNot(contains('cloud_sync_device_id')));
    expect(exported, isNot(contains('cloud_sync_last_uploaded_at')));
    expect(exported, isNot(contains('rest_fab_visible')));
    expect(exported, isNot(contains('unrelated_plugin_key')));
  });

  test('restore sanitizes legacy payload without touching local credentials',
      () async {
    SharedPreferences.setMockInitialValues({
      'workouts_2026-01-01': <String>['old workout'],
      'body_change_record_체중': <String>['old body'],
      'supabase.auth.token': 'local-session',
      'cloud_sync_device_id': 'local-device',
      'cloud_sync_last_uploaded_at': 'local-metadata',
      'unrelated_plugin_key': 'keep-me',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = CloudSyncService(prefs);

    await service.restoreSnapshot({
      'workouts_2026-10-22': <String>['restored workout'],
      'workout_routines': <String>['restored routine'],
      'isDarkMode': true,
      'supabase.auth.token': 'remote-session',
      'supabase.auth.token-code-verifier': 'remote-pkce',
      'cloud_sync_device_id': 'remote-device',
      'cloud_sync_last_uploaded_at': 'remote-metadata',
      'unrelated_plugin_key': 'replace-me',
    });

    expect(prefs.containsKey('workouts_2026-01-01'), isFalse);
    expect(prefs.containsKey('body_change_record_체중'), isFalse);
    expect(
      prefs.getStringList('workouts_2026-10-22'),
      <String>['restored workout'],
    );
    expect(
      prefs.getStringList('workout_routines'),
      <String>['restored routine'],
    );
    expect(prefs.getBool('isDarkMode'), isTrue);
    expect(prefs.getString('supabase.auth.token'), 'local-session');
    expect(prefs.containsKey('supabase.auth.token-code-verifier'), isFalse);
    expect(prefs.getString('cloud_sync_device_id'), 'local-device');
    expect(prefs.getString('cloud_sync_last_uploaded_at'), 'local-metadata');
    expect(prefs.getString('unrelated_plugin_key'), 'keep-me');
  });

  test('malformed allowed values are rejected before local data is changed',
      () async {
    SharedPreferences.setMockInitialValues({
      'workouts_2026-10-22': <String>['keep workout'],
      'isDarkMode': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = CloudSyncService(prefs);

    await expectLater(
      service.restoreSnapshot({
        'workouts_2026-10-23': <Object>[
          <String, Object>{'not': 'a SharedPreferences value'}
        ],
        'isDarkMode': 'not-a-boolean',
      }),
      throwsFormatException,
    );

    expect(
      prefs.getStringList('workouts_2026-10-22'),
      <String>['keep workout'],
    );
    expect(prefs.getBool('isDarkMode'), isFalse);
  });

  test('file restore validates versions and migrates the original safe format',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = CloudSyncService(prefs);

    await service.restoreExportedSnapshot({
      'version': 1,
      'workouts': <String>['legacy workout'],
      'routines': <String>['legacy routine'],
    });
    expect(prefs.getStringList('workouts'), <String>['legacy workout']);
    expect(prefs.getStringList('workout_routines'), <String>['legacy routine']);

    expect(
      () => service.restoreExportedSnapshot({
        'version': CloudSyncService.snapshotVersion + 1,
        'preferences': <String, dynamic>{},
      }),
      throwsFormatException,
    );
  });

  test('sync metadata cleanup preserves local workout data and auth storage',
      () async {
    SharedPreferences.setMockInitialValues({
      'workouts_2026-10-22': <String>['workout'],
      'supabase.auth.token': 'session',
      'cloud_sync_device_id': 'device',
      'cloud_sync_last_uploaded_at': 'uploaded',
      'cloud_sync_last_downloaded_at': 'downloaded',
      'cloud_sync_last_local_change_at': 'changed',
      'cloud_sync_is_dirty': true,
      'cloud_sync_last_error': 'error',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = CloudSyncService(prefs);

    await service.clearSyncMetadata();

    expect(prefs.getStringList('workouts_2026-10-22'), <String>['workout']);
    expect(prefs.getString('supabase.auth.token'), 'session');
    expect(prefs.containsKey('cloud_sync_device_id'), isFalse);
    expect(prefs.containsKey('cloud_sync_last_uploaded_at'), isFalse);
    expect(prefs.containsKey('cloud_sync_last_downloaded_at'), isFalse);
    expect(prefs.containsKey('cloud_sync_last_local_change_at'), isFalse);
    expect(prefs.containsKey('cloud_sync_is_dirty'), isFalse);
    expect(prefs.containsKey('cloud_sync_last_error'), isFalse);
  });
}
