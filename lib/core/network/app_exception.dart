sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// ネットワーク疎通エラー（タイムアウト・接続不可など）
final class NetworkException extends AppException {
  const NetworkException([super.message = 'ネットワークエラーが発生しました']);
}

/// 401 Unauthorized
final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = '認証が必要です']);
}

/// 4xx / 5xx のサーバーエラー
final class ServerException extends AppException {
  const ServerException({required String message, this.statusCode})
    : super(message);

  final int? statusCode;
}

/// APIが返すビジネスエラー（バリデーション違反など）
final class ApiException extends AppException {
  const ApiException(super.message, {this.code});

  final String? code;
}
