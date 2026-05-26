import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/inquiry/data/inquiry_repository.dart';
import 'package:hw_hub_mobile/features/inquiry/inquiry_providers.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_detail/inquiry_detail_page.dart';

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
  uiClient: 'mobile',
  uiVersion: '1.0.0',
  apiVersion: '2.0.0',
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

// closed=true を設定する Fake Notifier
class _ClosedTransitionNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) {
    Future.microtask(
      () => state = InquiryDetailState(
        isLoading: false,
        detail: _detailDto(status: '90'),
        closed: true,
      ),
    );
    return InquiryDetailState(isLoading: false, detail: _detailDto());
  }
}

// escalated=true を設定する Fake Notifier
class _EscalatedTransitionNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) {
    Future.microtask(
      () => state = InquiryDetailState(
        isLoading: false,
        detail: _detailDto(status: '20'),
        escalated: true,
      ),
    );
    return InquiryDetailState(
      isLoading: false,
      detail: _detailDto(status: '10'),
    );
  }
}

// errorMessage を設定する Fake Notifier（fetchFailedはfalse）
class _ErrorMessageNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) {
    Future.microtask(
      () => state = InquiryDetailState(
        isLoading: false,
        detail: _detailDto(),
        errorMessage: 'APIエラーが発生しました',
      ),
    );
    return InquiryDetailState(isLoading: false, detail: _detailDto());
  }
}

// close() を記録する Fake Notifier
class _RecordingCloseNotifier extends InquiryDetailNotifier {
  bool closeCalled = false;

  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto());

  @override
  Future<void> close() async {
    closeCalled = true;
  }
}

// escalate() を記録する Fake Notifier
class _RecordingEscalateNotifier extends InquiryDetailNotifier {
  bool escalateCalled = false;

  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto(status: '10'));

  @override
  Future<void> escalate() async {
    escalateCalled = true;
  }
}

// sendReply() を記録する Fake Notifier
class _RecordingSendReplyNotifier extends InquiryDetailNotifier {
  String? lastBody;

  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto());

  @override
  Future<void> sendReply(String body) async {
    lastBody = body;
  }
}

// replySent を手動でトリガーする Fake Notifier
class _ReplySentManualNotifier extends InquiryDetailNotifier {
  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto());

  void triggerReplySent() {
    state = InquiryDetailState(
      isLoading: false,
      detail: _detailDto(),
      replySent: true,
    );
  }

  @override
  void clearReplySent() {
    state = state.copyWith(replySent: false);
  }
}

// reload() を記録する Fake Notifier
class _RecordingReloadNotifier extends InquiryDetailNotifier {
  bool reloadCalled = false;

  @override
  InquiryDetailState build(int arg) =>
      InquiryDetailState(isLoading: false, detail: _detailDto());

  @override
  Future<void> reload() async {
    reloadCalled = true;
  }
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

    testWidgets('クローズ確認ダイアログ: 確認ボタンタップでclose()が呼ばれる', (tester) async {
      final notifier = _RecordingCloseNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('closeButton')));
      await tester.pumpAndSettle();

      // 確認ボタン（最後のTextButton）をタップ
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(notifier.closeCalled, isTrue);
    });

    testWidgets('エスカレート確認ダイアログ: 確認ボタンタップでescalate()が呼ばれる', (tester) async {
      final notifier = _RecordingEscalateNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('escalateButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      expect(notifier.escalateCalled, isTrue);
    });

    testWidgets('送信ボタンタップでsendReply()が呼ばれる', (tester) async {
      final notifier = _RecordingSendReplyNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      await tester.enterText(find.byKey(const Key('replyField')), 'テスト返信内容');
      await tester.pump();

      await tester.tap(find.byKey(const Key('sendButton')));
      await tester.pump();

      expect(notifier.lastBody, 'テスト返信内容');
    });

    testWidgets('replySentがtrueになると返信フィールドがクリアされる', (tester) async {
      final notifier = _ReplySentManualNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          withSnackBarKey: true,
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump(); // initial state built
      await tester.enterText(find.byKey(const Key('replyField')), '入力テキスト');
      await tester.pump(); // text visible

      notifier.triggerReplySent();
      await tester.pump(); // listener fires: _replyController.clear()
      await tester.pump(); // widget rebuild after controller change

      expect(find.text('入力テキスト'), findsNothing);
    });

    testWidgets('closedがtrueになるとスナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          withSnackBarKey: true,
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _ClosedTransitionNotifier(),
            ),
          ],
        ),
      );
      await tester.pump(); // initial state
      await tester.pump(); // microtask: closed=true

      // closed snackBar が表示される
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('escalatedがtrueになるとスナックバーが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          withSnackBarKey: true,
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _EscalatedTransitionNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(); // microtask: escalated=true

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('errorMessage(fetchFailed=false)が設定されるとエラースナックバーが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          withSnackBarKey: true,
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(
              () => _ErrorMessageNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(); // microtask: errorMessage set

      expect(find.text('APIエラーが発生しました'), findsOneWidget);
    });

    testWidgets('RefreshIndicatorがonRefresh時にreloadを呼ぶ', (tester) async {
      final notifier = _RecordingReloadNotifier();
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pump();

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 400));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(notifier.reloadCalled, isTrue);
    });

    testWidgets('クライアント情報セクションが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryDetailPage(inquiryId: 1),
          overrides: [
            inquiryDetailNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('clientInfoSection')), findsOneWidget);
    });
  });
}
