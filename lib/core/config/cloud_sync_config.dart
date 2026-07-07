import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CloudSyncConfig {
  static CloudSyncConfig instance = const CloudSyncConfig._internal(
    url: String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
    redirectUrl: String.fromEnvironment(
      'SUPABASE_REDIRECT_URL',
      defaultValue: 'bodycalendar://login-callback/',
    ),
    sourceName: 'dart-define',
  );

  static Future<void> load() async {
    if (isConfigured) {
      return;
    }

    const candidatePaths = [
      'assets/config/local.supabase.json',
      '.config/local.supabase.json',
    ];

    for (final path in candidatePaths) {
      try {
        final rawJson = await rootBundle.loadString(path);
        final json = jsonDecode(rawJson) as Map<String, dynamic>;
        final url = (json['SUPABASE_URL'] as String? ?? '').trim();
        final anonKey = (json['SUPABASE_ANON_KEY'] as String? ?? '').trim();
        final redirectUrl =
            (json['SUPABASE_REDIRECT_URL'] as String? ?? '').trim();

        if (url.isEmpty || anonKey.isEmpty) {
          continue;
        }

        instance = CloudSyncConfig._internal(
          url: url,
          anonKey: anonKey,
          redirectUrl: redirectUrl.isEmpty
              ? 'bodycalendar://login-callback/'
              : redirectUrl,
          sourceName: 'asset:$path',
        );
        return;
      } catch (error) {
        debugPrint('CloudSyncConfig.load skipped for $path: $error');
      }
    }
  }

  static String get supabaseUrl => instance.url;
  static String get supabaseAnonKey => instance.anonKey;
  static String get supabaseRedirectUrl => instance.redirectUrl;
  static bool get isConfigured =>
      instance.url.isNotEmpty && instance.anonKey.isNotEmpty;
  static String get source => instance.sourceName;

  final String url;
  final String anonKey;
  final String redirectUrl;
  final String sourceName;

  const CloudSyncConfig._internal({
    required this.url,
    required this.anonKey,
    required this.redirectUrl,
    required this.sourceName,
  });
}
