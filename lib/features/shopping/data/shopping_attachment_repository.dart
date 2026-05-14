import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/app_exception.dart';
import 'models/create_attachment_request.dart';
import 'models/create_upload_url_request.dart';
import 'models/create_upload_url_response.dart';
import 'models/shopping_attachment_dto.dart';

export 'models/create_upload_url_request.dart';
export 'models/create_upload_url_response.dart';
export 'models/create_attachment_request.dart';
export 'models/shopping_attachment_dto.dart';

abstract class ShoppingAttachmentRepository {
  /// Presigned URL を発行する。
  Future<CreateUploadUrlResponse> createUploadUrl({
    required int itemId,
    required CreateUploadUrlRequest req,
  });

  /// S3 に画像を直接 PUT する（インターセプターなしの素の Dio を使用）。
  Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  });

  /// attachment メタデータを登録する。
  Future<void> createAttachment({
    required int itemId,
    required CreateAttachmentRequest req,
  });

  /// 添付ファイル一覧を取得する。
  Future<List<ShoppingAttachmentDto>> listAttachments({required int itemId});

  /// 添付ファイルを削除する。
  Future<void> deleteAttachment({
    required int itemId,
    required int attachmentId,
  });
}

class ShoppingAttachmentRepositoryImpl implements ShoppingAttachmentRepository {
  ShoppingAttachmentRepositoryImpl(this._dio, this._s3Dio);

  final Dio _dio; // 認証付き Dio（通常のアプリ用）
  final Dio _s3Dio; // インターセプターなし素 Dio（S3 直接 PUT 用）

  @override
  Future<CreateUploadUrlResponse> createUploadUrl({
    required int itemId,
    required CreateUploadUrlRequest req,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/shopping-items/$itemId/attachments/upload-url',
        data: req.toJson(),
      );
      return CreateUploadUrlResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  String _resolveS3Url(String url) {
    if (!kDebugMode) return url;
    return url
        .replaceFirst('localhost', '10.0.2.2')
        .replaceFirst('127.0.0.1', '10.0.2.2');
  }

  @override
  Future<void> uploadToS3({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      await _s3Dio.put<dynamic>(
        _resolveS3Url(uploadUrl),
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: {'Content-Type': mimeType, 'Content-Length': bytes.length},
        ),
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> createAttachment({
    required int itemId,
    required CreateAttachmentRequest req,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/shopping-items/$itemId/attachments',
        data: req.toJson(),
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<List<ShoppingAttachmentDto>> listAttachments({
    required int itemId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/shopping-items/$itemId/attachments',
      );
      return (response.data as List<dynamic>)
          .map((e) => ShoppingAttachmentDto.fromJson(e as Map<String, dynamic>))
          .map(
            (dto) => ShoppingAttachmentDto(
              id: dto.id,
              fileName: dto.fileName,
              imageUrl: _resolveS3Url(dto.imageUrl),
              sortOrder: dto.sortOrder,
            ),
          )
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> deleteAttachment({
    required int itemId,
    required int attachmentId,
  }) async {
    try {
      await _dio.delete<dynamic>(
        '/api/shopping-items/$itemId/attachments/$attachmentId',
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
