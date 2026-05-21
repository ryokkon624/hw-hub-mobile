/// 開発環境（LocalStack）でバックエンドが返す S3 URL を
/// Android エミュレーターから到達可能なアドレスに変換するクラス。
///
/// バックエンドは LocalStack の URL（`http://localhost:4566/...`）をそのまま返すが、
/// Android エミュレーターから `localhost` は到達できないため `10.0.2.2` に変換する。
/// 本番環境（`kDebugMode == false`）では変換しない。
class S3UrlResolver {
  const S3UrlResolver({required this.isDebug});

  final bool isDebug;

  /// S3 URL を変換する。null の場合は null を返す。
  String? resolve(String? url) {
    if (url == null) return null;
    if (!isDebug) return url;
    return url
        .replaceFirst('localhost', '10.0.2.2')
        .replaceFirst('127.0.0.1', '10.0.2.2');
  }
}
