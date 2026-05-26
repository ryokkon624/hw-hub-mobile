import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/inquiry/data/inquiry_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

void main() {
  late MockDio mockDio;
  late InquiryRepositoryImpl repo;

  setUp(() {
    mockDio = MockDio();
    repo = InquiryRepositoryImpl(mockDio);
  });

  group('InquiryRepository.fetchInquiries()', () {
    test('成功時: 問い合わせ一覧を返す', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/inquiries')).thenAnswer(
        (_) async => Response(
          data: {
            'items': [
              {
                'inquiryId': 1,
                'category': '10',
                'status': '00',
                'title': 'テスト問い合わせ',
                'createdAt': '2026-05-01T10:00:00',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/inquiries'),
        ),
      );

      final result = await repo.fetchInquiries();

      expect(result, hasLength(1));
      expect(result.first.inquiryId, 1);
      expect(result.first.category, '10');
      expect(result.first.status, '00');
      expect(result.first.title, 'テスト問い合わせ');
    });

    test('空リスト時: 空のリストを返す', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/inquiries')).thenAnswer(
        (_) async => Response(
          data: {'items': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/inquiries'),
        ),
      );

      final result = await repo.fetchInquiries();

      expect(result, isEmpty);
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/inquiries')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/inquiries')),
      );

      expect(() => repo.fetchInquiries(), throwsA(isA<NetworkException>()));
    });

    test('DioException.error が AppException の場合: そのままスローする', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/inquiries')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/inquiries'),
          error: const ServerException(
            message: 'Server error',
            statusCode: 500,
          ),
        ),
      );

      expect(() => repo.fetchInquiries(), throwsA(isA<ServerException>()));
    });
  });

  group('InquiryRepository.createInquiry()', () {
    test('成功時: inquiryId を返す', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/inquiries',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'inquiryId': 42},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/inquiries'),
        ),
      );

      final result = await repo.createInquiry(
        category: '10',
        title: 'テスト',
        body: '内容',
        uiClient: 'mobile',
        uiVersion: '1.0.0',
        apiVersion: '2.0.0',
      );

      expect(result, 42);
    });

    test('uiClient/uiVersion/apiVersion が POST ペイロードに含まれる', () async {
      Map<String, dynamic>? capturedData;
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/inquiries',
          data: anyNamed('data'),
        ),
      ).thenAnswer((invocation) async {
        capturedData =
            invocation.namedArguments[const Symbol('data')]
                as Map<String, dynamic>;
        return Response(
          data: {'inquiryId': 1},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/api/inquiries'),
        );
      });

      await repo.createInquiry(
        category: '10',
        title: 'タイトル',
        body: '本文',
        uiClient: 'mobile',
        uiVersion: '1.2.3',
        apiVersion: '3.0.0',
      );

      expect(capturedData?['uiClient'], 'mobile');
      expect(capturedData?['uiVersion'], '1.2.3');
      expect(capturedData?['apiVersion'], '3.0.0');
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/inquiries',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/inquiries')),
      );

      expect(
        () => repo.createInquiry(
          category: '10',
          title: 'テスト',
          body: '内容',
          uiClient: 'mobile',
          uiVersion: '1.0.0',
          apiVersion: '2.0.0',
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('InquiryRepository.fetchInquiry()', () {
    test('成功時: 問い合わせ詳細を返す', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/inquiries/1')).thenAnswer(
        (_) async => Response(
          data: {
            'inquiryId': 1,
            'category': '10',
            'status': '10',
            'title': '詳細テスト',
            'createdAt': '2026-05-01T10:00:00',
            'uiClient': 'mobile',
            'uiVersion': '1.0.0',
            'apiVersion': '2.0.0',
            'messages': [
              {
                'messageId': 1,
                'seq': 1,
                'senderType': 'AI',
                'body': 'AIの返信です',
                'createdAt': '2026-05-01T10:05:00',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/inquiries/1'),
        ),
      );

      final result = await repo.fetchInquiry(1);

      expect(result.inquiryId, 1);
      expect(result.category, '10');
      expect(result.status, '10');
      expect(result.uiClient, 'mobile');
      expect(result.uiVersion, '1.0.0');
      expect(result.apiVersion, '2.0.0');
      expect(result.messages, hasLength(1));
      expect(result.messages.first.senderType, 'AI');
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/inquiries/1')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/api/inquiries/1')),
      );

      expect(() => repo.fetchInquiry(1), throwsA(isA<NetworkException>()));
    });
  });

  group('InquiryRepository.addMessage()', () {
    test('成功時: 正常終了する', () async {
      when(
        mockDio.post<void>('/api/inquiries/1/messages', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/inquiries/1/messages'),
        ),
      );

      await expectLater(repo.addMessage(1, '返信内容'), completes);
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(
        mockDio.post<void>('/api/inquiries/1/messages', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/inquiries/1/messages'),
        ),
      );

      expect(
        () => repo.addMessage(1, '返信内容'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('InquiryRepository.closeInquiry()', () {
    test('成功時: 正常終了する', () async {
      when(mockDio.post<void>('/api/inquiries/1/close')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/inquiries/1/close'),
        ),
      );

      await expectLater(repo.closeInquiry(1), completes);
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(mockDio.post<void>('/api/inquiries/1/close')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/inquiries/1/close'),
        ),
      );

      expect(() => repo.closeInquiry(1), throwsA(isA<NetworkException>()));
    });
  });

  group('InquiryRepository.escalateToStaff()', () {
    test('成功時: 正常終了する', () async {
      when(mockDio.post<void>('/api/inquiries/1/escalate')).thenAnswer(
        (_) async => Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/inquiries/1/escalate'),
        ),
      );

      await expectLater(repo.escalateToStaff(1), completes);
    });

    test('DioException 時: NetworkException をスローする', () async {
      when(mockDio.post<void>('/api/inquiries/1/escalate')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/inquiries/1/escalate'),
        ),
      );

      expect(() => repo.escalateToStaff(1), throwsA(isA<NetworkException>()));
    });
  });
}
