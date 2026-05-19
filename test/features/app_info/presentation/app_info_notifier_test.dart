import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/app_info/app_info_providers.dart';
import 'package:mockito/mockito.dart';

import '../app_info_mocks.mocks.dart';

ProviderContainer _makeContainer({required MockAppInfoRepository mockRepo}) {
  final container = ProviderContainer(
    overrides: [appInfoRepositoryProvider.overrideWithValue(mockRepo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockAppInfoRepository mockRepo;

  setUp(() {
    mockRepo = MockAppInfoRepository();
  });

  group('AppInfoNotifier.build()', () {
    test('初期状態: isLoadingApi=true、apiVersionはnull', () async {
      when(mockRepo.fetchApiVersion()).thenAnswer((_) async => '1.0.0');

      final container = _makeContainer(mockRepo: mockRepo);
      final state = container.read(appInfoNotifierProvider);

      expect(state.isLoadingApi, true);
      expect(state.apiVersion, isNull);
    });

    test('APIバージョン取得成功: apiVersionがセットされ isLoadingApi=false になる', () async {
      when(mockRepo.fetchApiVersion()).thenAnswer((_) async => '2.3.4');

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(appInfoNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(appInfoNotifierProvider);
      expect(state.apiVersion, '2.3.4');
      expect(state.isLoadingApi, false);
      sub.close();
    });

    test('APIバージョン取得成功・null返却: apiVersionはnull、isLoadingApi=false', () async {
      when(mockRepo.fetchApiVersion()).thenAnswer((_) async => null);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(appInfoNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(appInfoNotifierProvider);
      expect(state.apiVersion, isNull);
      expect(state.isLoadingApi, false);
      sub.close();
    });

    test(
      'APIバージョン取得失敗（AppException）: isLoadingApi=false、apiVersionはnull',
      () async {
        when(
          mockRepo.fetchApiVersion(),
        ).thenThrow(const NetworkException('ネットワークエラー'));

        final container = _makeContainer(mockRepo: mockRepo);
        final sub = container.listen(appInfoNotifierProvider, (_, _) {});
        await Future<void>.microtask(() {});
        await Future<void>.delayed(Duration.zero);

        final state = container.read(appInfoNotifierProvider);
        expect(state.apiVersion, isNull);
        expect(state.isLoadingApi, false);
        sub.close();
      },
    );

    test('APIバージョン取得失敗（予期しない例外）: isLoadingApi=false、apiVersionはnull', () async {
      when(mockRepo.fetchApiVersion()).thenThrow(Exception('予期しない例外'));

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(appInfoNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(appInfoNotifierProvider);
      expect(state.apiVersion, isNull);
      expect(state.isLoadingApi, false);
      sub.close();
    });
  });
}
