import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:body_calendar/core/config/cloud_sync_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum CloudSyncVisualState {
  synced,
  syncing,
  unsynced,
  unavailable,
}

class CloudSyncResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? summary;
  final DateTime? syncedAt;

  const CloudSyncResult({
    required this.success,
    required this.message,
    this.summary,
    this.syncedAt,
  });
}

class CloudSyncService extends ChangeNotifier {
  CloudSyncService(this._prefs);

  final SharedPreferences _prefs;

  static const String _deviceIdKey = 'cloud_sync_device_id';
  static const String _lastUploadedAtKey = 'cloud_sync_last_uploaded_at';
  static const String _lastDownloadedAtKey = 'cloud_sync_last_downloaded_at';
  static const String _lastLocalChangeAtKey = 'cloud_sync_last_local_change_at';
  static const String _isDirtyKey = 'cloud_sync_is_dirty';
  static const String _lastErrorKey = 'cloud_sync_last_error';
  static const Duration _autoUploadDebounce = Duration(seconds: 2);
  static const Duration _interactiveSignInTimeout = Duration(minutes: 2);
  static const List<String> _trackedExactKeys = [
    'workout_routines',
    'custom_exercises',
    'use_lbs',
    'isDarkMode',
    'first_record_date',
    'enable_workout_recommendation',
    _deviceIdKey,
    _lastUploadedAtKey,
    _lastDownloadedAtKey,
  ];
  static const List<String> _trackedPrefixes = [
    'workouts_',
    'exercise_sets_',
    'recorded_dates_',
    'body_change_record_',
  ];

  Timer? _autoUploadTimer;
  bool _isUploading = false;

  bool get isSyncing => _isUploading;
  bool get isDirty =>
      _prefs.getBool(_isDirtyKey) ?? _computeDirtyFromTimestamps();
  String? get lastLocalChangeAt => _prefs.getString(_lastLocalChangeAtKey);
  String? get lastError => _prefs.getString(_lastErrorKey);

  CloudSyncVisualState get visualState {
    if (!isAvailable) {
      return CloudSyncVisualState.unavailable;
    }
    if (_isUploading) {
      return CloudSyncVisualState.syncing;
    }
    if (isDirty || lastUploadedAt == null) {
      return CloudSyncVisualState.unsynced;
    }
    return CloudSyncVisualState.synced;
  }

  String get statusLabel {
    switch (visualState) {
      case CloudSyncVisualState.synced:
        return lastUploadedAt == null
            ? '클라우드 동기화 완료'
            : '마지막 동기화 ${lastUploadedAt!}';
      case CloudSyncVisualState.syncing:
        return '클라우드 동기화 중';
      case CloudSyncVisualState.unsynced:
        if (!isSignedIn) {
          return '로그인 후 자동 동기화 가능';
        }
        return lastError?.isNotEmpty == true
            ? '동기화 필요 · ${lastError!}'
            : '동기화가 최신이 아니에요';
      case CloudSyncVisualState.unavailable:
        return 'Supabase 설정이 없어 클라우드 동기화를 사용할 수 없어요.';
    }
  }

  bool get isAvailable => CloudSyncConfig.isConfigured;

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => isAvailable ? _client.auth.currentUser : null;

  bool get isSignedIn => currentUser != null;

  String? get currentUserEmail => currentUser?.email;

  String? get lastUploadedAt => _prefs.getString(_lastUploadedAtKey);

  String? get lastDownloadedAt => _prefs.getString(_lastDownloadedAtKey);

  Future<CloudSyncResult> uploadSnapshot(
      {bool allowInteractiveSignIn = true}) async {
    _isUploading = true;
    notifyListeners();

    try {
      if (!isAvailable) {
        return const CloudSyncResult(
          success: false,
          message: 'Supabase 설정이 없어 클라우드 업로드를 사용할 수 없어요.',
        );
      }

      final authResult = allowInteractiveSignIn
          ? await ensureSignedInWithGoogle()
          : await ensureSignedInSilently();
      if (!authResult.success) {
        await _prefs.setString(_lastErrorKey, authResult.message);
        return authResult;
      }

      final user = currentUser;
      if (user == null) {
        return const CloudSyncResult(
          success: false,
          message: '로그인 세션을 확인하지 못했어요.',
        );
      }

      final snapshot = await exportSnapshot();
      final now = DateTime.now().toUtc();

      await _client.from('user_sync_snapshots').upsert({
        'user_id': user.id,
        'email': user.email,
        'display_name':
            user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
        'provider': user.appMetadata['provider'],
        'device_id': snapshot['deviceId'],
        'backup_version': snapshot['version'],
        'summary': snapshot['summary'],
        'payload': snapshot['preferences'],
        'synced_at': now.toIso8601String(),
      }, onConflict: 'user_id');

      await _prefs.setString(_lastUploadedAtKey, now.toIso8601String());
      await _prefs.setBool(_isDirtyKey, false);
      await _prefs.remove(_lastErrorKey);

      return CloudSyncResult(
        success: true,
        message: '운동 데이터를 클라우드에 업로드했어요.',
        summary: Map<String, dynamic>.from(snapshot['summary'] as Map),
        syncedAt: now,
      );
    } catch (error) {
      final message = '클라우드 업로드 중 문제가 생겼어요: $error';
      await _prefs.setString(_lastErrorKey, message);
      return CloudSyncResult(
        success: false,
        message: message,
      );
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<CloudSyncResult> restoreLatestSnapshot() async {
    if (!isAvailable) {
      return const CloudSyncResult(
        success: false,
        message: 'Supabase 설정이 없어 클라우드 복원을 사용할 수 없어요.',
      );
    }

    final authResult = await ensureSignedInWithGoogle();
    if (!authResult.success) {
      return authResult;
    }

    final user = currentUser;
    if (user == null) {
      return const CloudSyncResult(
        success: false,
        message: '로그인 세션을 확인하지 못했어요.',
      );
    }

    final response = await _client
        .from('user_sync_snapshots')
        .select('payload, summary, synced_at')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      return const CloudSyncResult(
        success: false,
        message: '클라우드에 저장된 백업이 아직 없어요.',
      );
    }

    final payload = Map<String, dynamic>.from(response['payload'] as Map);
    await restoreSnapshot(payload);

    final syncedAtRaw = response['synced_at'] as String?;
    final syncedAt =
        syncedAtRaw != null ? DateTime.tryParse(syncedAtRaw) : null;
    await _prefs.setString(
      _lastDownloadedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await _prefs.setBool(_isDirtyKey, false);
    await _prefs.remove(_lastErrorKey);
    notifyListeners();

    return CloudSyncResult(
      success: true,
      message: '클라우드 백업을 이 기기에 복원했어요. 앱을 다시 열면 가장 안정적이에요.',
      summary:
          Map<String, dynamic>.from(response['summary'] as Map? ?? const {}),
      syncedAt: syncedAt,
    );
  }

  Future<CloudSyncResult> ensureSignedInWithGoogle() async {
    if (!isAvailable) {
      return const CloudSyncResult(
        success: false,
        message: 'Supabase 설정이 비어 있어요.',
      );
    }

    if (currentUser != null) {
      return CloudSyncResult(
        success: true,
        message: '이미 로그인되어 있어요.',
      );
    }

    final completer = Completer<CloudSyncResult>();
    final appLinks = AppLinks();
    Timer? sessionPollTimer;
    StreamSubscription<Uri>? deepLinkSubscription;
    late final StreamSubscription<AuthState> subscription;

    void completeIfSignedIn([String message = 'Google 로그인을 완료했어요.']) {
      if (currentUser != null && !completer.isCompleted) {
        completer.complete(CloudSyncResult(
          success: true,
          message: message,
        ));
      }
    }

    bool isAuthCallbackUri(Uri uri) {
      final expected = Uri.parse(CloudSyncConfig.supabaseRedirectUrl);
      final sameScheme = uri.scheme == expected.scheme;
      final expectedHost = expected.host;
      final sameHost = expectedHost.isEmpty || uri.host == expectedHost;
      return sameScheme && sameHost;
    }

    Future<void> handleAuthCallback(Uri uri) async {
      if (!isAuthCallbackUri(uri)) return;
      if (!uri.queryParameters.containsKey('code') &&
          !uri.fragment.contains('access_token') &&
          !uri.fragment.contains('error_description')) {
        return;
      }

      try {
        await _client.auth.getSessionFromUrl(uri);
      } catch (error) {
        debugPrint('CloudSyncService.handleAuthCallback failed: $error');
      } finally {
        completeIfSignedIn();
      }
    }

    Future<void> tryHandleLatestAuthLink() async {
      try {
        final latestUri = await appLinks.getLatestLink();
        if (latestUri != null) {
          await handleAuthCallback(latestUri);
        }
      } catch (error) {
        debugPrint('CloudSyncService.getLatestLink failed: $error');
      }
    }

    subscription = _client.auth.onAuthStateChange.listen((event) {
      if (event.session?.user != null) {
        completeIfSignedIn();
      }
    });

    try {
      deepLinkSubscription = appLinks.uriLinkStream.listen(
        (uri) {
          if (uri != null) {
            handleAuthCallback(uri);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('CloudSyncService.uriLinkStream error: $error');
        },
      );

      await tryHandleLatestAuthLink();

      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: CloudSyncConfig.supabaseRedirectUrl,
        scopes: 'email profile',
      );

      if (!launched) {
        if (!completer.isCompleted) {
          completer.complete(const CloudSyncResult(
            success: false,
            message: 'Google 로그인 창을 열지 못했어요.',
          ));
        }
      } else {
        completeIfSignedIn();
        sessionPollTimer = Timer.periodic(
          const Duration(milliseconds: 400),
          (_) {
            unawaited(tryHandleLatestAuthLink());
            completeIfSignedIn();
          },
        );
      }

      return await completer.future.timeout(
        _interactiveSignInTimeout,
        onTimeout: () => CloudSyncResult(
          success: currentUser != null,
          message: currentUser != null
              ? 'Google 로그인은 되었지만 확인 신호가 늦어서, 현재 세션으로 계속 진행할게요.'
              : 'Google 로그인이 아직 앱으로 돌아오지 않았어요. 브라우저에서 로그인을 마치고 앱으로 돌아와 다시 시도해 주세요.',
        ),
      );
    } catch (error) {
      return CloudSyncResult(
        success: false,
        message: 'Google 로그인 중 문제가 생겼어요: $error',
      );
    } finally {
      sessionPollTimer?.cancel();
      await deepLinkSubscription?.cancel();
      await subscription.cancel();
    }
  }

  Future<CloudSyncResult> ensureSignedInSilently() async {
    if (!isAvailable) {
      return const CloudSyncResult(
        success: false,
        message: 'Supabase 설정이 비어 있어요.',
      );
    }

    if (currentUser != null) {
      return const CloudSyncResult(
        success: true,
        message: '이미 로그인되어 있어요.',
      );
    }

    return const CloudSyncResult(
      success: false,
      message: '자동 동기화를 하려면 먼저 Google 로그인이 필요해요.',
    );
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<void> notifyLocalChange({bool scheduleUpload = true}) async {
    if (!_computeTrackedDataExists()) {
      return;
    }

    await _prefs.setString(
      _lastLocalChangeAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await _prefs.setBool(_isDirtyKey, true);
    await _prefs.remove(_lastErrorKey);
    notifyListeners();

    if (scheduleUpload) {
      scheduleAutoUpload();
    }
  }

  void scheduleAutoUpload() {
    _autoUploadTimer?.cancel();
    if (!isAvailable || !isSignedIn) {
      notifyListeners();
      return;
    }

    _autoUploadTimer = Timer(_autoUploadDebounce, () async {
      final result = await uploadSnapshot(allowInteractiveSignIn: false);
      if (!result.success) {
        notifyListeners();
      }
    });
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    final serializablePrefs = <String, dynamic>{};
    final keys = _prefs.getKeys().toList()..sort();
    for (final key in keys) {
      final value = _prefs.get(key);
      if (value is List<String>) {
        serializablePrefs[key] = List<String>.from(value);
      } else if (value is String ||
          value is bool ||
          value is int ||
          value is double) {
        serializablePrefs[key] = value;
      }
    }

    final summary = _buildSummary(serializablePrefs);
    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'deviceId': await _getOrCreateDeviceId(),
      'summary': summary,
      'preferences': serializablePrefs,
    };
  }

  Future<void> restoreSnapshot(Map<String, dynamic> payload) async {
    final currentKeys = _prefs.getKeys().where(_isTrackedAppKey).toList();
    for (final key in currentKeys) {
      await _prefs.remove(key);
    }

    final entries = payload.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      final value = entry.value;
      if (value is bool) {
        await _prefs.setBool(entry.key, value);
      } else if (value is int) {
        await _prefs.setInt(entry.key, value);
      } else if (value is double) {
        await _prefs.setDouble(entry.key, value);
      } else if (value is String) {
        await _prefs.setString(entry.key, value);
      } else if (value is List) {
        await _prefs.setStringList(
          entry.key,
          value.map((item) => item.toString()).toList(),
        );
      } else if (value != null) {
        await _prefs.setString(entry.key, jsonEncode(value));
      }
    }
  }

  Map<String, dynamic> _buildSummary(Map<String, dynamic> prefs) {
    final workoutDayKeys =
        prefs.keys.where((key) => key.startsWith('workouts_')).toList();
    final exerciseSetKeys =
        prefs.keys.where((key) => key.startsWith('exercise_sets_')).toList();
    final bodyRecordKeys = prefs.keys
        .where((key) => key.startsWith('body_change_record_'))
        .toList();
    final recordedDateKeys =
        prefs.keys.where((key) => key.startsWith('recorded_dates_')).toList();

    int workoutEntryCount = 0;
    for (final key in workoutDayKeys) {
      final value = prefs[key];
      if (value is List) {
        workoutEntryCount += value.length;
      }
    }

    return {
      'totalPreferenceKeys': prefs.length,
      'workoutDayCount': workoutDayKeys.length,
      'workoutEntryCount': workoutEntryCount,
      'exerciseSetKeyCount': exerciseSetKeys.length,
      'bodyMetricKeyCount': bodyRecordKeys.length,
      'recordedExerciseCount': recordedDateKeys.length,
    };
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final deviceId = const Uuid().v4();
    await _prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  bool _isTrackedAppKey(String key) {
    if (_trackedExactKeys.contains(key)) {
      return true;
    }
    return _trackedPrefixes.any(key.startsWith);
  }

  bool _computeDirtyFromTimestamps() {
    final localRaw = _prefs.getString(_lastLocalChangeAtKey);
    final uploadedRaw = _prefs.getString(_lastUploadedAtKey);
    if (localRaw == null) {
      return false;
    }
    if (uploadedRaw == null) {
      return true;
    }

    final local = DateTime.tryParse(localRaw);
    final uploaded = DateTime.tryParse(uploadedRaw);
    if (local == null) {
      return false;
    }
    if (uploaded == null) {
      return true;
    }
    return local.isAfter(uploaded);
  }

  bool _computeTrackedDataExists() {
    return _prefs.getKeys().any(_isTrackedAppKey);
  }
}
