import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/inquiry/data/inquiry_repository.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_detail/inquiry_detail_notifier.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_detail/inquiry_detail_page.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_detail/inquiry_detail_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

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

// ローディング中 Fake Notifier
class _LoadingNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) => const InquiryDetailState();
}

// ロード失敗 Fake Notifier
class _ErrorNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) {
    Future.microtask(
      () => state = const InquiryDetailState(
        isLoading: false,
        errorMessage: 'ネットワークエラー',
        fetchFailed: true,
      ),
    );
    return const InquiryDetailState();
  }
}

// メッセージ有り Fake Notifier
class _LoadedNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) => InquiryDetailState(
    isLoading: false,
    detail: _detailDto(
      messages: [
        _messageDto(id: 1, senderType: 'AI'),
        _messageDto(id: 2, senderType: 'USER'),
      ],
    ),
  );
}

// メッセージ0件 Fake Notifier
class _LoadedEmptyNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto());
}

// クローズ済み Fake Notifier
class _ClosedNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto(status: '90'));
}

// AIが回答済み（エスカレートボタン表示） Fake Notifier
class _AiAnsweredNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto(status: '10'));
}

void main() {
  group('InquiryDetailPage', () {
    testWidgets('ローディング中: インジケータが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _LoadingNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ロード失敗時: 問い合わせ一覧へリダイレクトされる', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings/inquiries',
              builder: (_, _) =>
                  const Scaffold(body: Text('inquiry-list-page')),
            ),
            GoRoute(
              path: '/settings/inquiries/:id',
              builder: (_, _) => const InquiryDetailPage(inquiryId: 1),
            ),
          ],
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _ErrorNotifier()),
          ],
          initialLocation: '/settings/inquiries/1',
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('inquiry-list-page'), findsOneWidget);
    });

    testWidgets('ロード成功時: ヘッダーとメッセージリストが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('detailHeader')), findsOneWidget);
      expect(find.byKey(const Key('messageList')), findsOneWidget);
      expect(find.byKey(const Key('replyArea')), findsOneWidget);
      expect(find.byKey(const Key('replyField')), findsOneWidget);
      expect(find.byKey(const Key('sendButton')), findsOneWidget);
      expect(find.byKey(const Key('closeButton')), findsOneWidget);
    });

    testWidgets('メッセージ0件時: 返信エリアは表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _LoadedEmptyNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('detailHeader')), findsOneWidget);
      expect(find.byKey(const Key('replyArea')), findsOneWidget);
    });

    testWidgets('クローズ済み: 返信エリアが非表示になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _ClosedNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('replyArea')), findsNothing);
    });

    testWidgets('AIが回答済み: エスカレートボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _AiAnsweredNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('escalateButton')), findsOneWidget);
    });

    testWidgets('返信テキストが空: 送信ボタンが無効になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      final sendButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('sendButton')),
      );
      expect(sendButton.onPressed, isNull);
    });

    testWidgets('返信テキストを入力: 送信ボタンが有効になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(find.byKey(const Key('replyField')), 'テスト返信');
      await tester.pump();

      final sendButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('sendButton')),
      );
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('クローズ確認ダイアログ: closeButtonタップでダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('closeButton')));
      await tester.pumpAndSettle();

      // AlertDialogが表示されている
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('クローズ確認ダイアログ: キャンセルでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('closeButton')));
      await tester.pumpAndSettle();

      // キャンセルボタンをタップ
      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('エスカレート確認ダイアログ: escalateButtonタップでダイアログが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _AiAnsweredNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('escalateButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('エスカレート確認ダイアログ: キャンセルでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _AiAnsweredNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('escalateButton')));
      await tester.pumpAndSettle();

      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
