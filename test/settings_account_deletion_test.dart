import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:body_calendar/features/settings/bloc/theme_bloc.dart';
import 'package:body_calendar/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCloudSyncService extends CloudSyncService {
  _FakeCloudSyncService(SharedPreferences prefs) : super(prefs);

  bool deleteCalled = false;

  @override
  bool get isAvailable => true;

  @override
  String? get currentUserEmail => 'tester@example.com';

  @override
  Future<CloudSyncResult> deleteAccount() async {
    deleteCalled = true;
    return const CloudSyncResult(
      success: true,
      message: '클라우드 계정과 저장된 데이터를 삭제했어요.',
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('signed-in user confirms destructive cloud account deletion',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final service = _FakeCloudSyncService(prefs);
    GetIt.I.registerSingleton<SharedPreferences>(prefs);
    GetIt.I.registerSingleton<CloudSyncService>(service);

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => ThemeBloc(prefs),
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete-cloud-account')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delete-cloud-account')));
    await tester.pumpAndSettle();
    expect(find.text('클라우드 계정을 삭제할까요?'), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('confirm-delete-cloud-account')));
    await tester.pumpAndSettle();

    expect(service.deleteCalled, isTrue);
    expect(find.text('클라우드 계정을 삭제할까요?'), findsNothing);
  });
}
