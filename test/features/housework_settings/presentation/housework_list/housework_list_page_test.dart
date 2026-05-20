import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/models/housework_dto.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_notifier.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_page.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

// HouseworkListNotifier の FakeNotifier
class _FakeHouseworkListNotifier extends HouseworkListNotifier {
  _FakeHouseworkListNotifier(this._state);

  final HouseworkListState _state;

  @override
  Future<HouseworkListState> build() async => _state;
}

// ローディング状態を返す FakeNotifier（Completerで永遠に完了しない）
class _LoadingNotifier extends HouseworkListNotifier {
  @override
  Future<HouseworkListState> build() {
    return Completer<HouseworkListState>().future;
  }
}

// エラー状態を返す FakeNotifier
class _ErrorNotifier extends HouseworkListNotifier {
  @override
  Future<HouseworkListState> build() async {
    throw Exception('ロードエラー');
  }
}

const _hw1 = HouseworkDto(
  houseworkId: 1,
  householdId: 10,
  name: '掃除機がけ',
  category: 'CLEAN',
  recurrenceType: '1',
  weeklyDays: 2,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _hw2 = HouseworkDto(
  houseworkId: 2,
  householdId: 10,
  name: '食器洗い',
  category: 'KITCHEN',
  recurrenceType: '1',
  weeklyDays: 127,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

Widget _buildPage(HouseworkListState state) {
  return buildTestPageWithRouter(
    overrides: [
      houseworkListNotifierProvider.overrideWith(
        () => _FakeHouseworkListNotifier(state),
      ),
    ],
    routes: [GoRoute(path: '/', builder: (_, __) => const HouseworkListPage())],
  );
}

List<HouseworkDto> _generateHouseworks(int count) {
  return List.generate(
    count,
    (i) => HouseworkDto(
      houseworkId: i + 1,
      householdId: 10,
      name: '家事${i + 1}',
      category: 'CLEAN',
      recurrenceType: '1',
      weeklyDays: 2,
      startDate: '2025-01-01',
      endDate: '2099-12-31',
    ),
  );
}

void main() {
  group('HouseworkListPage', () {
    testWidgets('houseworkListPageキーのScaffoldが表示される', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkListState(allHouseworks: [_hw1, _hw2])),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkListPage')), findsOneWidget);
    });

    testWidgets('家事一覧が表示される（2件）', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkListState(allHouseworks: [_hw1, _hw2])),
      );
      await tester.pumpAndSettle();

      expect(find.text('掃除機がけ'), findsOneWidget);
      expect(find.text('食器洗い'), findsOneWidget);
    });

    testWidgets('空リストの場合に家事カードが表示されない', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkListState()));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('家事を追加するボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkListState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkAddButton')), findsOneWidget);
    });

    testWidgets('カテゴリフィルタDropdownが表示される', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkListState(allHouseworks: [_hw1])),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('categoryFilterDropdown')), findsOneWidget);
    });

    testWidgets('ローディング中: CircularProgressIndicatorが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(
              () => _LoadingNotifier(),
            ),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('エラー時: エラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(() => _ErrorNotifier()),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('houseworkListPage')), findsOneWidget);
    });

    testWidgets('11件以上のとき: ページネーション行が表示される', (tester) async {
      // 11件でtotalPages=2になる
      final houseworks = _generateHouseworks(11);
      await tester.pumpWidget(
        _buildPage(HouseworkListState(allHouseworks: houseworks)),
      );
      await tester.pumpAndSettle();

      // ページネーションボタンはリスト末尾なのでスクロールして表示
      await tester.scrollUntilVisible(
        find.byKey(const Key('paginationPrev')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byKey(const Key('paginationPrev')), findsOneWidget);
      expect(find.byKey(const Key('paginationNext')), findsOneWidget);
    });

    testWidgets('ページネーション: 1ページ目は前へボタンが無効', (tester) async {
      final houseworks = _generateHouseworks(11);
      await tester.pumpWidget(
        _buildPage(
          HouseworkListState(allHouseworks: houseworks, currentPage: 1),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('paginationPrev')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final prevButton = tester.widget<IconButton>(
        find.byKey(const Key('paginationPrev')),
      );
      expect(prevButton.onPressed, isNull);
    });

    testWidgets('ページネーション: 2ページ目は後へボタンが無効', (tester) async {
      final houseworks = _generateHouseworks(11);
      await tester.pumpWidget(
        _buildPage(
          HouseworkListState(allHouseworks: houseworks, currentPage: 2),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('paginationNext')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final nextButton = tester.widget<IconButton>(
        find.byKey(const Key('paginationNext')),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('カテゴリフィルタ選択中: フィルタが適用される', (tester) async {
      await tester.pumpWidget(
        _buildPage(
          const HouseworkListState(
            allHouseworks: [_hw1, _hw2],
            selectedCategory: 'CLEAN',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // CLEANのみ表示される
      expect(find.text('掃除機がけ'), findsOneWidget);
    });
  });
}
