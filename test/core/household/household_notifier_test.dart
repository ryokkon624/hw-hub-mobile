import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.mocks.dart';

/// テスト用の /api/users/me/households レスポンスJSON
List<Map<String, dynamic>> _householdsJson(List<Household> households) {
  return households
      .map((h) => {'householdId': h.id, 'name': h.name, 'ownerUserId': 1})
      .toList();
}

ProviderContainer _makeContainer(Dio dio) {
  final container = ProviderContainer(
    overrides: [dioProvider.overrideWithValue(dio)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockDio mockDio;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDio = MockDio();
  });

  group('HouseholdNotifier.build()', () {
    test('API呼び出し成功時: 世帯リストを返し先頭をselectedとして設定する', () async {
      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: _householdsJson(const [
            Household(id: 1, name: '山田家'),
            Household(id: 2, name: '田中家'),
          ]),
        ),
      );

      final container = _makeContainer(mockDio);
      final state = await container.read(householdNotifierProvider.future);

      expect(state.households, hasLength(2));
      expect(state.households.first.id, 1);
      expect(state.households.first.name, '山田家');
      expect(state.selectedHousehold?.id, 1);
    });

    test('SharedPreferencesに選択IDが保存済みの場合: 保存済みの世帯を復元する', () async {
      SharedPreferences.setMockInitialValues({'selected_household_id': 2});
      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: _householdsJson(const [
            Household(id: 1, name: '山田家'),
            Household(id: 2, name: '田中家'),
          ]),
        ),
      );

      final container = _makeContainer(mockDio);
      final state = await container.read(householdNotifierProvider.future);

      expect(state.selectedHousehold?.id, 2);
      expect(state.selectedHousehold?.name, '田中家');
    });

    test('保存済みIDが現在の所属世帯にない場合: 先頭にフォールバック', () async {
      SharedPreferences.setMockInitialValues({'selected_household_id': 999});
      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: _householdsJson(const [Household(id: 1, name: '山田家')]),
        ),
      );

      final container = _makeContainer(mockDio);
      final state = await container.read(householdNotifierProvider.future);

      expect(state.selectedHousehold?.id, 1);
    });

    test('世帯リストが空の場合: selectedHouseholdはnull', () async {
      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: <dynamic>[],
        ),
      );

      final container = _makeContainer(mockDio);
      final state = await container.read(householdNotifierProvider.future);

      expect(state.households, isEmpty);
      expect(state.selectedHousehold, isNull);
    });

    test('APIがDioExceptionを投げた場合: AsyncErrorになる', () async {
      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          type: DioExceptionType.connectionError,
        ),
      );

      final container = _makeContainer(mockDio);

      // build() が AsyncError になることを確認
      container.listen(householdNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final result = container.read(householdNotifierProvider);
      expect(result.hasError, isTrue);
    });
  });

  group('HouseholdNotifier.select()', () {
    test('select()でselectedHouseholdが更新される', () async {
      const h1 = Household(id: 1, name: '山田家');
      const h2 = Household(id: 2, name: '田中家');

      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: _householdsJson(const [h1, h2]),
        ),
      );

      final container = _makeContainer(mockDio);
      await container.read(householdNotifierProvider.future);

      await container.read(householdNotifierProvider.notifier).select(h2);

      final updated = container.read(householdNotifierProvider).value!;
      expect(updated.selectedHousehold, h2);
    });

    test('select()でSharedPreferencesにIDが保存される（int値）', () async {
      const h = Household(id: 42, name: 'テスト家');

      when(mockDio.get<List<dynamic>>('/api/users/me/households')).thenAnswer(
        (_) async => Response<List<dynamic>>(
          requestOptions: RequestOptions(path: '/api/users/me/households'),
          statusCode: 200,
          data: _householdsJson(const [h]),
        ),
      );

      final container = _makeContainer(mockDio);
      await container.read(householdNotifierProvider.future);
      await container.read(householdNotifierProvider.notifier).select(h);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('selected_household_id'), 42);
    });
  });
}
