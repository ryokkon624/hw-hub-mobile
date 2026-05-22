import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/inquiry/data/inquiry_repository.dart';
import 'package:hw_hub_mobile/features/inquiry/inquiry_providers.dart';
import 'package:mockito/mockito.dart';

import '../../inquiry_mocks.mocks.dart';

InquiryDetailDto _detailDto({
  int id = 1,
  String status = '00',
  List<InquiryMessageDto>? messages,
}) => InquiryDetailDto(
  inquiryId: id,
  category: '10',
  status: status,
  title: 'テスト問い合わせ',
  createdAt: '2026-05-01T10:00:00',
  messages: messages ?? [],
);

InquiryMessageDto _messageDto({int id = 1, String senderType = 'AI'}) =>
    InquiryMessageDto(
      messageId: id,
      seq: id,
      senderType: senderType,
      body: 'メッセージ $id',
      createdAt: '2026-05-01T10:05:00',
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

  group('InquiryDetailNotifier.build()', () {
    test('初期状態: isLoading=true', () async {
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => _detailDto());

      final container = _makeContainer(mockRepo: mockRepo);
      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.isLoading, true);
      expect(state.detail, isNull);
    });

    test('ロード成功時: detailがセットされ isLoading=false になる', () async {
      final dto = _detailDto(messages: [_messageDto()]);
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => dto);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.detail, isNotNull);
      expect(state.detail!.inquiryId, 1);
      expect(state.detail!.messages, hasLength(1));
      expect(state.isLoading, false);
      sub.close();
    });

    test('ロード失敗時（AppException）: errorMessageがセットされる', () async {
      const exception = NetworkException('ネットワークエラー');
      when(mockRepo.fetchInquiry(1)).thenThrow(exception);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.errorMessage, exception.message);
      expect(state.isLoading, false);
      expect(state.fetchFailed, true);
      sub.close();
    });
  });

  group('InquiryDetailNotifier.sendReply()', () {
    test('返信送信成功時: detailが再取得され replySentがtrue になる', () async {
      final dto = _detailDto(messages: [_messageDto()]);
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => dto);
      when(mockRepo.addMessage(1, '返信内容')).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      // 2回目fetchで新しいメッセージ
      when(mockRepo.fetchInquiry(1)).thenAnswer(
        (_) async => _detailDto(
          messages: [
            _messageDto(),
            _messageDto(id: 2, senderType: 'USER'),
          ],
        ),
      );

      await container
          .read(inquiryDetailNotifierProvider(1).notifier)
          .sendReply('返信内容');

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.replySent, true);
      expect(state.detail!.messages, hasLength(2));
      sub.close();
    });

    test('返信送信失敗時（AppException）: errorMessageがセットされる', () async {
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => _detailDto());
      const exception = NetworkException('送信エラー');
      when(mockRepo.addMessage(1, '返信')).thenThrow(exception);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      await container
          .read(inquiryDetailNotifierProvider(1).notifier)
          .sendReply('返信');

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.errorMessage, exception.message);
      sub.close();
    });
  });

  group('InquiryDetailNotifier.close()', () {
    test('クローズ成功時: detailが再取得され closedがtrue になる', () async {
      when(
        mockRepo.fetchInquiry(1),
      ).thenAnswer((_) async => _detailDto(status: '10'));
      when(mockRepo.closeInquiry(1)).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      when(
        mockRepo.fetchInquiry(1),
      ).thenAnswer((_) async => _detailDto(status: '90'));

      await container.read(inquiryDetailNotifierProvider(1).notifier).close();

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.closed, true);
      expect(state.detail!.status, '90');
      sub.close();
    });

    test('クローズ失敗時（AppException）: errorMessageがセットされる', () async {
      when(
        mockRepo.fetchInquiry(1),
      ).thenAnswer((_) async => _detailDto(status: '10'));
      const exception = NetworkException('クローズ失敗');
      when(mockRepo.closeInquiry(1)).thenThrow(exception);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      await container.read(inquiryDetailNotifierProvider(1).notifier).close();

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.errorMessage, exception.message);
      sub.close();
    });
  });

  group('InquiryDetailNotifier.escalate()', () {
    test('エスカレート成功時: detailが再取得され escalatedがtrue になる', () async {
      when(
        mockRepo.fetchInquiry(1),
      ).thenAnswer((_) async => _detailDto(status: '10'));
      when(mockRepo.escalateToStaff(1)).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      when(
        mockRepo.fetchInquiry(1),
      ).thenAnswer((_) async => _detailDto(status: '20'));

      await container
          .read(inquiryDetailNotifierProvider(1).notifier)
          .escalate();

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.escalated, true);
      expect(state.detail!.status, '20');
      sub.close();
    });

    test('エスカレート失敗時（AppException）: errorMessageがセットされる', () async {
      when(
        mockRepo.fetchInquiry(1),
      ).thenAnswer((_) async => _detailDto(status: '10'));
      const exception = NetworkException('エスカレート失敗');
      when(mockRepo.escalateToStaff(1)).thenThrow(exception);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      await container
          .read(inquiryDetailNotifierProvider(1).notifier)
          .escalate();

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.errorMessage, exception.message);
      sub.close();
    });
  });

  group('InquiryDetailNotifier.reload()', () {
    test('リロード成功時: detailが更新され isLoading=false になる', () async {
      final initialDto = _detailDto(status: '00');
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => initialDto);

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      // 2回目のAPI呼び出しで別のデータを返す
      final updatedDto = _detailDto(status: '20', messages: [_messageDto()]);
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => updatedDto);

      await container.read(inquiryDetailNotifierProvider(1).notifier).reload();

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.isLoading, false);
      expect(state.detail!.status, '20');
      expect(state.detail!.messages, hasLength(1));
      sub.close();
    });

    test('リロード失敗時（AppException）: errorMessageがセットされる', () async {
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => _detailDto());

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      const exception = NetworkException('接続エラー');
      when(mockRepo.fetchInquiry(1)).thenThrow(exception);

      await container.read(inquiryDetailNotifierProvider(1).notifier).reload();

      final state = container.read(inquiryDetailNotifierProvider(1));
      expect(state.errorMessage, exception.message);
      expect(state.isLoading, false);
      sub.close();
    });
  });

  group('InquiryDetailNotifier.clearReplySent()', () {
    test('replySentをfalseに戻す', () async {
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => _detailDto());
      when(mockRepo.addMessage(1, '返信')).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo: mockRepo);
      final sub = container.listen(inquiryDetailNotifierProvider(1), (_, _) {});
      await Future<void>.microtask(() {});
      await Future<void>.delayed(Duration.zero);

      // 一度replySentをtrue にする
      when(mockRepo.fetchInquiry(1)).thenAnswer((_) async => _detailDto());
      await container
          .read(inquiryDetailNotifierProvider(1).notifier)
          .sendReply('返信');
      expect(container.read(inquiryDetailNotifierProvider(1)).replySent, true);

      container
          .read(inquiryDetailNotifierProvider(1).notifier)
          .clearReplySent();
      expect(container.read(inquiryDetailNotifierProvider(1)).replySent, false);

      sub.close();
    });
  });
}
