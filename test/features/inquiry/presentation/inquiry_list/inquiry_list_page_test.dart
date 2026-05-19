import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/inquiry/data/inquiry_repository.dart';
import 'package:hw_hub_mobile/features/inquiry/inquiry_providers.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_list/inquiry_list_notifier.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_list/inquiry_list_page.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/widget_test_helpers.dart';

// ロード成功（2件）の Fake Notifier
class _LoadedNotifier extends InquiryListNotifier {
  @override
  InquiryListState build() => InquiryListState(
    isLoading: false,
    inquiries: [
      InquirySummaryDto(
        inquiryId: 1,
        category: '10',
        status: '00',
        title: 'テスト問い合わせ1',
        createdAt: '2026-05-01T10:00:00',
      ),
      InquirySummaryDto(
        inquiryId: 2,
        category: '40',
        status: '10',
        title: 'バグ報告',
        createdAt: '2026-05-02T15:30:00',
      ),
    ],
  );
}

// 0件の Fake Notifier
class _EmptyNotifier extends InquiryListNotifier {
  @override
  InquiryListState build() =>
      const InquiryListState(isLoading: false, inquiries: []);
}

// ローディング中の Fake Notifier
class _LoadingNotifier extends InquiryListNotifier {
  @override
  InquiryListState build() => const InquiryListState(isLoading: true);
}

void main() {
  group('InquiryListPage', () {
    testWidgets('ロード成功時: 問い合わせ一覧が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings/inquiries',
              builder: (_, _) => const InquiryListPage(),
            ),
            GoRoute(
              path: '/settings/inquiries/new',
              builder: (_, _) => const Scaffold(body: Text('new-inquiry-page')),
            ),
            GoRoute(
              path: '/settings/inquiries/:id',
              builder: (_, _) =>
                  const Scaffold(body: Text('inquiry-detail-page')),
            ),
          ],
          overrides: [
            inquiryListNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
          initialLocation: '/settings/inquiries',
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('inquiryList')), findsOneWidget);
      expect(find.byKey(const ValueKey(1)), findsOneWidget);
      expect(find.byKey(const ValueKey(2)), findsOneWidget);
    });

    testWidgets('0件時: 空状態ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryListPage(),
          overrides: [
            inquiryListNotifierProvider.overrideWith(() => _EmptyNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('emptyState')), findsOneWidget);
      expect(find.byKey(const Key('inquiryList')), findsNothing);
    });

    testWidgets('ローディング中: CircularProgressIndicator が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const InquiryListPage(),
          overrides: [
            inquiryListNotifierProvider.overrideWith(() => _LoadingNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('emptyState')), findsNothing);
    });

    testWidgets('新規お問い合わせボタンタップで新規作成画面へ遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings/inquiries',
              builder: (_, _) => const InquiryListPage(),
            ),
            GoRoute(
              path: '/settings/inquiries/new',
              builder: (_, _) => const Scaffold(body: Text('new-inquiry-page')),
            ),
          ],
          overrides: [
            inquiryListNotifierProvider.overrideWith(() => _EmptyNotifier()),
          ],
          initialLocation: '/settings/inquiries',
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('newInquiryButton')));
      await tester.pumpAndSettle();

      expect(find.text('new-inquiry-page'), findsOneWidget);
    });

    testWidgets('問い合わせタップで詳細画面へ遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(
              path: '/settings/inquiries',
              builder: (_, _) => const InquiryListPage(),
            ),
            GoRoute(
              path: '/settings/inquiries/new',
              builder: (_, _) => const Scaffold(body: Text('new-page')),
            ),
            GoRoute(
              path: '/settings/inquiries/:id',
              builder: (_, _) =>
                  const Scaffold(body: Text('inquiry-detail-page')),
            ),
          ],
          overrides: [
            inquiryListNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
          initialLocation: '/settings/inquiries',
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();

      expect(find.text('inquiry-detail-page'), findsOneWidget);
    });
  });
}
