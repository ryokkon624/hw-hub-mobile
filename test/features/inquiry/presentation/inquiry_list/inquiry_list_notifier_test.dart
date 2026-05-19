import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/inquiry/data/inquiry_repository.dart';
import 'package:hw_hub_mobile/features/inquiry/inquiry_providers.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_list/inquiry_list_notifier.dart';
import 'package:mockito/mockito.dart';

import '../../inquiry_mocks.mocks.dart';

InquirySummaryDto _dto({int id = 1, String status = '00'}) => InquirySummaryDto(
  inquiryId: id,
  category: '10',
  status: status,
  title: 'テスト問い合わせ $id',
  createdAt: '2026-05-01T10:00:00',
);

ProviderContainer _makeContainer({required MockInquiryRepository mockRepo}) {
  final container = ProviderContainer(
    overrides: [inquiryRepositoryProvider.overrideWithValue(mockRepo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockInquiryRepository mockRepo;

  setUp(() {
    mockRepo = MockInquiryRepository();
  });

  group('InquiryListNotifier.build()', () {
    test('初期状態: isLoading=true、inquiriesは空', () async {
      when(mockRepo.fetchInquiries()).thenAnswer((_) async => [_dto()]);

      final container = _makeContainer(mockRepo: mockRepo);
      final state = container.read(inquiryListNotifierProvider);
      expect(state.isLoading, true);
      expect(state.inquiries, isEmpty);
    });

    test('ロード成功時: inquiriesがセットされ isLoading=false になる', () async {
      final dtos = [_dto(id: 1), _dto(id: 2, status: '10')];
      when(mockRepo.fetchInquiries()).thenAnswer((_) async => dtos);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryListNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(inquiryListNotifierProvider);
      expect(state.inquiries, hasLength(2));
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      sub.close();
    });

    test('ロード成功時・0件: inquiriesが空でも isLoading=false になる', () async {
      when(mockRepo.fetchInquiries()).thenAnswer((_) async => []);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryListNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(inquiryListNotifierProvider);
      expect(state.inquiries, isEmpty);
      expect(state.isLoading, false);
      sub.close();
    });

    test('ロード失敗時（AppException）: errorMessageがセットされる', () async {
      const exception = NetworkException('ネットワーク接続できません');
      when(mockRepo.fetchInquiries()).thenThrow(exception);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryListNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(inquiryListNotifierProvider);
      expect(state.errorMessage, exception.message);
      expect(state.isLoading, false);
      sub.close();
    });
  });

  group('InquiryListNotifier.reload()', () {
    test('リロード成功時: 一覧が更新される', () async {
      when(mockRepo.fetchInquiries()).thenAnswer((_) async => [_dto(id: 1)]);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryListNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      when(
        mockRepo.fetchInquiries(),
      ).thenAnswer((_) async => [_dto(id: 1), _dto(id: 2)]);

      await container.read(inquiryListNotifierProvider.notifier).reload();

      final state = container.read(inquiryListNotifierProvider);
      expect(state.inquiries, hasLength(2));
      sub.close();
    });

    test('リロード失敗時（AppException）: errorMessageがセットされる', () async {
      when(mockRepo.fetchInquiries()).thenAnswer((_) async => [_dto()]);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryListNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      const exception = NetworkException('接続エラー');
      when(mockRepo.fetchInquiries()).thenThrow(exception);

      await container.read(inquiryListNotifierProvider.notifier).reload();

      final state = container.read(inquiryListNotifierProvider);
      expect(state.errorMessage, exception.message);
      sub.close();
    });

    test('リロード失敗時（予期しない例外）: errorUnexpectedがセットされる', () async {
      when(mockRepo.fetchInquiries()).thenAnswer((_) async => [_dto()]);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryListNotifierProvider, (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      when(mockRepo.fetchInquiries()).thenThrow(Exception('予期しない例外'));

      await container.read(inquiryListNotifierProvider.notifier).reload();

      final state = container.read(inquiryListNotifierProvider);
      expect(state.errorMessage, 'errorUnexpected');
      sub.close();
    });
  });
}
