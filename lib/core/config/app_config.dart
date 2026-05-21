class AppConfig {
  AppConfig._();

  // flutter run --dart-define=BASE_URL=https://... で上書き可能
  // Android エミュレーターから見たホストのlocalhost = 10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  // flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxx で設定する
  // Google Cloud Console の OAuth 2.0 Web クライアントID（バックエンド検証に使用）
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
