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
  });
}
