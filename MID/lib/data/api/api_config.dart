import 'package:flutter/foundation.dart';

/// Backend base URL.
/// - Web (production, same host): empty → `/api/v1`
/// - Local native/web: `http://127.0.0.1:8000`
/// Override: `--dart-define=API_BASE_URL=https://example.com`
class ApiConfig {
  static const String _fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '__unset__',
  );

  static String get baseUrl {
    if (_fromEnv != '__unset__') return _fromEnv;
    // Local debug (Chrome/desktop) → FastAPI :8000
    if (kDebugMode) return 'http://127.0.0.1:8000';
    // Production web: same host via nginx
    if (kIsWeb) return '';
    return 'http://127.0.0.1:8000';
  }

  static const String apiPrefix = '/api/v1';

  static String get apiRoot => '$baseUrl$apiPrefix';
}
