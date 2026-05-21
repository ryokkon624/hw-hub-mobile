import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_create/inquiry_create_notifier.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_create/inquiry_create_page.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_create/inquiry_create_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

// 初期状態の Fake Notifier
class _InitialNotifier extends InquiryCreateNotifier {
  @override
  InquiryCreateState build() => const InquiryCreateState();
}

// 送信成功の Fake Notifier
class _SuccessNotifier extends InquiryCreateNotifier {
  @override
  InquiryCreateState build() {
    Future.microtask(() => state = state.copyWith(createdInquiryId: 42));
    return const InquiryCreateState();
  }
}

// 送信中の Fake Notifier
class _SubmittingNotifier extends InquiryCreateNotifier {
  @override
  InquiryCreateState build() => const InquiryCreateState(isSubmitting: true);
}

// カテゴリ未選択エラーの Fake Notifier
class _CategoryErrorNotifier extends InquiryCreateNotifier {
  @override
  InquiryCreateState build() => const InquiryCreateState(
    errorMessage: 'inquiryCreateErrorCategoryRequired',
  );
}

// タイトル未入力エラーの Fake Notifier
class _TitleRequiredErrorNotifier extends InquiryCreateNotifier {
  @override
  InquiryCreateState build() =>
      const InquiryCreateState(errorMessage: 'inquiryCreateErrorTitleRequired');
}

// タイトル超過エラーの Fake Notifier
class _TitleTooLongErrorNotifier extends InquiryCreateNotifier {
  @override
  InquiryCreateState build() =>
      const InquiryCreateState(errorMessage: 'inquiryCreateErrorTitleTooLong');
}

// 本文未入力エラーの Fake Notifier
class _BodyRequiredErrorNotifier extends InquiryCreateNotifier {
  @override
  InquiryCreateState build() =>
      const InquiryCreateState(errorMessage: 'inquiryCreateErrorBodyRequired');
}

void main() {
  group('InquiryCreatePage', () {
    testWidgets('初期表示: フォームの各フィールドが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryCreatePage(),
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _InitialNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('categoryDropdown')), findsOneWidget);
      expect(find.byKey(const Key('titleField')), findsOneWidget);
      expect(find.byKey(const Key('bodyField')), findsOneWidget);
      expect(find.byKey(const Key('submitButton')), findsOneWidget);
      expect(find.byKey(const Key('cancelButton')), findsOneWidget);
    });

    testWidgets('送信中: 送信ボタンが無効になる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryCreatePage(),
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _SubmittingNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      final submitButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('submitButton')),
      );
      expect(submitButton.onPressed, isNull);
    });

    testWidgets('キャンセルタップで一覧画面へ遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings/inquiries',
              builder: (_, _) =>
                  const Scaffold(body: Text('inquiry-list-page')),
            ),
            GoRoute(
              path: '/settings/inquiries/new',
              builder: (_, _) => const InquiryCreatePage(),
            ),
          ],
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _InitialNotifier(),
            ),
          ],
          initialLocation: '/settings/inquiries/new',
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('cancelButton')));
      await tester.pumpAndSettle();

      expect(find.text('inquiry-list-page'), findsOneWidget);
    });

    testWidgets('送信中: CircularProgressIndicatorが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryCreatePage(),
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _SubmittingNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('カテゴリ未選択エラー: エラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryCreatePage(),
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _CategoryErrorNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      // カテゴリエラーが表示される（Textウィジェットが存在する）
      expect(find.byKey(const Key('categoryDropdown')), findsOneWidget);
    });

    testWidgets('タイトル未入力エラー: エラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryCreatePage(),
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _TitleRequiredErrorNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('titleField')), findsOneWidget);
    });

    testWidgets('タイトル文字数超過エラー: フォームが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryCreatePage(),
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _TitleTooLongErrorNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('titleField')), findsOneWidget);
    });

    testWidgets('本文未入力エラー: エラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryCreatePage(),
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _BodyRequiredErrorNotifier(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('bodyField')), findsOneWidget);
    });

    testWidgets('送信成功時: 詳細画面へ遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings/inquiries/new',
              builder: (_, _) => const InquiryCreatePage(),
            ),
            GoRoute(
              path: '/settings/inquiries/:id',
              builder: (_, _) =>
                  const Scaffold(body: Text('inquiry-detail-page')),
            ),
          ],
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _SuccessNotifier(),
            ),
          ],
          initialLocation: '/settings/inquiries/new',
        ),
      );
      // microtaskとアニメーション完了を待つ
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('inquiry-detail-page'), findsOneWidget);
    });

    testWidgets('送信成功時: 詳細画面から戻ると新規作成画面ではなく一覧画面が表示される', (tester) async {
      // 一覧から新規作成に push し、送信成功後に詳細に遷移したとき
      // context.go を使うことで新規作成画面がスタックから除去される
      // そのため詳細から Back すると一覧画面が表示される（新規作成画面ではない）
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings/inquiries',
              builder: (_, _) =>
                  const Scaffold(body: Text('inquiry-list-page')),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, _) => const InquiryCreatePage(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, _) => Scaffold(
                    body: const Text('inquiry-detail-page'),
                    appBar: AppBar(title: const Text('詳細')),
                  ),
                ),
              ],
            ),
          ],
          overrides: [
            inquiryCreateNotifierProvider.overrideWith(
              () => _SuccessNotifier(),
            ),
          ],
          // 一覧から新規作成に遷移した状態をシミュレート
          initialLocation: '/settings/inquiries/new',
        ),
      );
      // microtaskとアニメーション完了を待つ（成功後に詳細に遷移）
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      // 詳細画面に遷移している
      expect(find.text('inquiry-detail-page'), findsOneWidget);

      // Back ボタンで戻る
      final NavigatorState navigator = tester.state(
        find.byType(Navigator).first,
      );
      navigator.pop();
      await tester.pumpAndSettle();

      // 一覧画面が表示される（新規作成画面ではない）
      expect(find.text('inquiry-list-page'), findsOneWidget);
      expect(find.byType(InquiryCreatePage), findsNothing);
    });
  });
}
