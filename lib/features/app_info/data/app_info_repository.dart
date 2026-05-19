import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';

abstract class AppInfoRepository {
  /// /actuator/info から API バージョンを取得する。
  /// 取得できない場合は null を返す。
  Future<String?> fetchApiVersion();
}

class AppInfoRepositoryImpl implements AppInfoRepository {
  AppInfoRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<String?> fetchApiVersion() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/actuator/info');
      final data = response.data;
      if (data == null) return null;
      final app = data['app'];
      if (app == null || app is! Map) return null;
      return app['version'] as String?;
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
