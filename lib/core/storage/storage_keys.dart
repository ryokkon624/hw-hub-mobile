class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  // iOSアプリ削除時にSecureStorageが残る問題への対策フラグ
  static const String installFlag = 'install_flag';
}
