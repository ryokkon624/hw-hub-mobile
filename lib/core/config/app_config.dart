class AppConfig {
  AppConfig._();

  // flutter run --dart-define=BASE_URL=https://... で上書き可能
  // Android エミュレーターから見たホストのlocalhost = 10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
