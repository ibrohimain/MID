/// Backend base URL.
/// Chrome/desktop: localhost. Android emulator: 10.0.2.2.
/// Override: flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String apiPrefix = '/api/v1';

  static String get apiRoot => '$baseUrl$apiPrefix';
}
