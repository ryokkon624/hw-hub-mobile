import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/housework_settings_repository.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/mocks.mocks.dart';

RequestOptions _req(String path) => RequestOptions(path: path);

Map<String, dynamic> _houseworkJson({
  int houseworkId = 1,
  String category = 'CLEAN',
  String recurrenceType = '1',
}) => {
  'houseworkId': houseworkId,
  'householdId': 10,
  'name': 'テスト家事$houseworkId',
  'description': '説明$houseworkId',
  'category': category,
  'recurrenceType': recurrenceType,
  'weeklyDays': 42,
  'dayOfMonth': null,
  'nthWeek': null,
  'weekday': null,
  'startDate': '2025-01-01',
  'endDate': '2099-12-31',
  'defaultAssigneeUserId': null,
};

Map<String, dynamic> _templateJson({int id = 1}) => {
  'houseworkTemplateId': id,
  'nameJa': 'テンプレート$id',
  'nameEn': 'Template$id',
  'nameEs': 'Plantilla$id',
  'descriptionJa': '説明Ja',
  'descriptionEn': 'Desc En',
  'descriptionEs': 'Desc Es',
  'recommendationJa': null,
  'recommendationEn': null,
  'recommendationEs': null,
  'category': 'CLEAN',
  'recurrenceType': '1',
  'weeklyDays': 42,
  'dayOfMonth': null,
  'nthWeek': null,
  'weekday': null,
};

void main() {
  late MockDio mockDio;
  late HouseworkSettingsRepository repo;

  setUp(() {
    mockDio = MockDio();
    repo = HouseworkSettingsRepositoryImpl(mockDio);
  });

  // =============================
  // fetchHouseworks
  // =============================

  group('fetchHouseworks()', () {
    test('成功時: 家事一覧を返す', () async {
      when(
        mockDio.get<List<dynamic>>(
          '/api/houseworks',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: _req('/api/houseworks'),
          statusCode: 200,
          data: [
            _houseworkJson(houseworkId: 1),
            _houseworkJson(houseworkId: 2),
          ],
        ),
      );

      final result = await repo.fetchHouseworks(householdId: 10);
      expect(result, hasLength(2));
      expect(result.first.houseworkId, 1);
      expect(result.first.name, 'テスト家事1');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.get<List<dynamic>>(
          '/api/houseworks',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/houseworks'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchHouseworks(householdId: 10),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // =============================
  // fetchHousework
  // =============================

  group('fetchHousework()', () {
    test('成功時: 家事1件を返す', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/houseworks/1')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: _req('/api/houseworks/1'),
          statusCode: 200,
          data: _houseworkJson(houseworkId: 1),
        ),
      );

      final result = await repo.fetchHousework(houseworkId: 1);
      expect(result.houseworkId, 1);
      expect(result.name, 'テスト家事1');
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.get<Map<String, dynamic>>('/api/houseworks/1')).thenThrow(
        DioException(
          requestOptions: _req('/api/houseworks/1'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchHousework(houseworkId: 1),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // =============================
  // fetchMembers
  // =============================

  group('fetchMembers()', () {
    test('成功時: メンバー一覧を返す', () async {
      when(mockDio.get<List<dynamic>>('/api/households/10/members')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: _req('/api/households/10/members'),
          statusCode: 200,
          data: [
            {
              'householdId': 10,
              'userId': 1,
              'displayName': '山田太郎',
              'status': 'ACTIVE',
              'role': 'OWNER',
            },
          ],
        ),
      );

      final result = await repo.fetchMembers(householdId: 10);
      expect(result, hasLength(1));
      expect(result.first.userId, 1);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.get<List<dynamic>>('/api/households/10/members')).thenThrow(
        DioException(
          requestOptions: _req('/api/households/10/members'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.fetchMembers(householdId: 10),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // =============================
  // createHousework
  // =============================

  group('createHousework()', () {
    test('成功時: 作成された家事を返す', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/houseworks',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: _req('/api/houseworks'),
          statusCode: 201,
          data: _houseworkJson(houseworkId: 99),
        ),
      );

      final result = await repo.createHousework(
        householdId: 10,
        name: 'テスト家事',
        description: '説明',
        category: 'CLEAN',
        recurrenceType: '1',
        weeklyDays: 42,
        dayOfMonth: null,
        nthWeek: null,
        weekday: null,
        startDate: '2025-01-01',
        endDate: '2099-12-31',
        defaultAssigneeUserId: null,
      );

      expect(result.houseworkId, 99);
    });

    test(
      'オプション引数（dayOfMonth/nthWeek/weekday/defaultAssigneeUserId）が設定される',
      () async {
        when(
          mockDio.post<Map<String, dynamic>>(
            '/api/houseworks',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: _req('/api/houseworks'),
            statusCode: 201,
            data: _houseworkJson(houseworkId: 100, recurrenceType: '2'),
          ),
        );

        final result = await repo.createHousework(
          householdId: 10,
          name: 'テスト家事月次',
          description: null,
          category: 'CLEAN',
          recurrenceType: '2',
          weeklyDays: null,
          dayOfMonth: 15,
          nthWeek: 2,
          weekday: 3,
          startDate: '2025-01-01',
          endDate: '2099-12-31',
          defaultAssigneeUserId: 1,
        );

        expect(result.houseworkId, 100);
      },
    );

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.post<Map<String, dynamic>>(
          '/api/houseworks',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/houseworks'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.createHousework(
          householdId: 10,
          name: 'テスト家事',
          description: null,
          category: 'CLEAN',
          recurrenceType: '1',
          weeklyDays: 42,
          dayOfMonth: null,
          nthWeek: null,
          weekday: null,
          startDate: '2025-01-01',
          endDate: '2099-12-31',
          defaultAssigneeUserId: null,
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // =============================
  // updateHousework
  // =============================

  group('updateHousework()', () {
    test('成功時: 更新された家事を返す', () async {
      when(
        mockDio.put<Map<String, dynamic>>(
          '/api/houseworks/1',
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: _req('/api/houseworks/1'),
          statusCode: 200,
          data: _houseworkJson(houseworkId: 1),
        ),
      );

      final result = await repo.updateHousework(
        houseworkId: 1,
        householdId: 10,
        name: 'テスト家事',
        description: '説明',
        category: 'CLEAN',
        recurrenceType: '1',
        weeklyDays: 42,
        dayOfMonth: null,
        nthWeek: null,
        weekday: null,
        startDate: '2025-01-01',
        endDate: '2099-12-31',
        defaultAssigneeUserId: null,
      );

      expect(result.houseworkId, 1);
    });

    test(
      'オプション引数（dayOfMonth/nthWeek/weekday/defaultAssigneeUserId）が設定される',
      () async {
        when(
          mockDio.put<Map<String, dynamic>>(
            '/api/houseworks/1',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: _req('/api/houseworks/1'),
            statusCode: 200,
            data: _houseworkJson(houseworkId: 1, recurrenceType: '3'),
          ),
        );

        final result = await repo.updateHousework(
          houseworkId: 1,
          householdId: 10,
          name: 'テスト家事第n週',
          description: null,
          category: 'CLEAN',
          recurrenceType: '3',
          weeklyDays: null,
          dayOfMonth: 10,
          nthWeek: 3,
          weekday: 5,
          startDate: '2025-01-01',
          endDate: '2099-12-31',
          defaultAssigneeUserId: 2,
        );

        expect(result.houseworkId, 1);
      },
    );

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(
        mockDio.put<Map<String, dynamic>>(
          '/api/houseworks/1',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: _req('/api/houseworks/1'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(
        () => repo.updateHousework(
          houseworkId: 1,
          householdId: 10,
          name: 'テスト家事',
          description: null,
          category: 'CLEAN',
          recurrenceType: '1',
          weeklyDays: 42,
          dayOfMonth: null,
          nthWeek: null,
          weekday: null,
          startDate: '2025-01-01',
          endDate: '2099-12-31',
          defaultAssigneeUserId: null,
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // =============================
  // fetchTemplates
  // =============================

  group('fetchTemplates()', () {
    test('成功時: テンプレート一覧を返す', () async {
      when(mockDio.get<List<dynamic>>('/api/housework-templates')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: _req('/api/housework-templates'),
          statusCode: 200,
          data: [_templateJson(id: 1), _templateJson(id: 2)],
        ),
      );

      final result = await repo.fetchTemplates();
      expect(result, hasLength(2));
      expect(result.first.houseworkTemplateId, 1);
    });

    test('DioExceptionが発生した場合: NetworkExceptionをthrowする', () async {
      when(mockDio.get<List<dynamic>>('/api/housework-templates')).thenThrow(
        DioException(
          requestOptions: _req('/api/housework-templates'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(() => repo.fetchTemplates(), throwsA(isA<NetworkException>()));
    });
  });
}
