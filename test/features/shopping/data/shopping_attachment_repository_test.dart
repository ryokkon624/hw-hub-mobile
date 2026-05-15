import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_attachment_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

RequestOptions _req(String path) => RequestOptions(path: path);

void main() {
  late MockDio mockDio;
  late MockDio mockS3Dio;
  late ShoppingAttachmentRepository repo;

  setUp(() {
    mockDio = MockDio();
    mockS3Dio = MockDio();
    repo = ShoppingAttachmentRepositoryImpl(mockDio, mockS3Dio);
  });

  group('ShoppingAttachmentRepository.createUploadUrl()', () {
    test('成功時: CreateUploadUrlResponse を返す', () async {
      when(
        mockDio.post<dynamic>(
          '/api/shopping-items/1/attachments/upload-url',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/1/attachments/upload-url'),
          statusCode: 200,
          data: {
            'uploadUrl': 'https://s3.example.com/upload?sig=xxx',
            'fileKey': 'shopping/1/abc.jpg',
          },
        ),
      );

      final req = const CreateUploadUrlRequest(
        fileName: 'abc.jpg',
        mimeType: 'image/jpeg',
      );
      final result = await repo.createUploadUrl(itemId: 1, req: req);
      expect(result.uploadUrl, contains('s3.example.com'));
      expect(result.fileKey, 'shopping/1/abc.jpg');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.post<dynamic>(
          '/api/shopping-items/1/attachments/upload-url',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/1/attachments/upload-url'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.createUploadUrl(
          itemId: 1,
          req: const CreateUploadUrlRequest(
            fileName: 'abc.jpg',
            mimeType: 'image/jpeg',
          ),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ShoppingAttachmentRepository.uploadToS3()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockS3Dio.put<dynamic>(
          'https://s3.example.com/upload',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('https://s3.example.com/upload'),
          statusCode: 200,
          data: null,
        ),
      );

      await expectLater(
        repo.uploadToS3(
          uploadUrl: 'https://s3.example.com/upload',
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        ),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockS3Dio.put<dynamic>(
          'https://s3.example.com/upload',
          data: anyNamed('data'),
          options: anyNamed('options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('https://s3.example.com/upload'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.uploadToS3(
          uploadUrl: 'https://s3.example.com/upload',
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ShoppingAttachmentRepository.createAttachment()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.post<dynamic>(
          '/api/shopping-items/1/attachments',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/1/attachments'),
          statusCode: 200,
          data: {'id': 100},
        ),
      );

      final req = const CreateAttachmentRequest(
        fileKey: 'shopping/1/abc.jpg',
        fileName: 'abc.jpg',
        mimeType: 'image/jpeg',
      );
      await expectLater(repo.createAttachment(itemId: 1, req: req), completes);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.post<dynamic>(
          '/api/shopping-items/1/attachments',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/1/attachments'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.createAttachment(
          itemId: 1,
          req: const CreateAttachmentRequest(
            fileKey: 'shopping/1/abc.jpg',
            fileName: 'abc.jpg',
            mimeType: 'image/jpeg',
          ),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ShoppingAttachmentRepository.listAttachments()', () {
    test('成功時: 添付ファイルリストを返す', () async {
      when(
        mockDio.get<dynamic>('/api/shopping-items/1/attachments'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/1/attachments'),
          statusCode: 200,
          data: [
            {
              'id': 1,
              'fileName': 'abc.jpg',
              'imageUrl': 'https://cdn.example.com/abc.jpg',
              'sortOrder': 0,
            },
          ],
        ),
      );

      final result = await repo.listAttachments(itemId: 1);
      expect(result, hasLength(1));
      expect(result.first.fileName, 'abc.jpg');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.get<dynamic>('/api/shopping-items/1/attachments')).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/1/attachments'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.listAttachments(itemId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('ShoppingAttachmentRepository.deleteAttachment()', () {
    test('成功時: 例外なく完了する', () async {
      when(
        mockDio.delete<dynamic>('/api/shopping-items/1/attachments/10'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: _req('/api/shopping-items/1/attachments/10'),
          statusCode: 204,
          data: null,
        ),
      );

      await expectLater(
        repo.deleteAttachment(itemId: 1, attachmentId: 10),
        completes,
      );
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.delete<dynamic>('/api/shopping-items/1/attachments/10'),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/shopping-items/1/attachments/10'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.deleteAttachment(itemId: 1, attachmentId: 10),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
