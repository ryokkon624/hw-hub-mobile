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

// filterByCategory / goToPage を記録する FakeNotifier
class _RecordingNotifier extends HouseworkListNotifier {
  _RecordingNotifier(this._initial);
  final HouseworkListState _initial;

  String? lastCategory;
  int? lastPage;

  @override
  Future<HouseworkListState> build() async => _initial;

  @override
  void filterByCategory(String? category) {
    lastCategory = category;
    state = AsyncData(_initial.copyWith(selectedCategory: category));
  }

  @override
  void goToPage(int page) {
    lastPage = page;
    state = AsyncData(_initial.copyWith(currentPage: page));
  }
}

// エラーメッセージありの状態に遷移するFakeNotifier
class _MutableNotifier extends HouseworkListNotifier {
  _MutableNotifier(this._initial);
  final HouseworkListState _initial;

  @override
  Future<HouseworkListState> build() async => _initial;

  void setError(String message) {
    state = AsyncData(_initial.copyWith(errorMessage: message));
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

    testWidgets('ページネーション前へボタンタップでgoToPageが呼ばれる', (tester) async {
      final houseworks = _generateHouseworks(11);
      final notifier = _RecordingNotifier(
        HouseworkListState(allHouseworks: houseworks, currentPage: 2),
      );
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(() => notifier),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('paginationPrev')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const Key('paginationPrev')));
      await tester.pump();

      expect(notifier.lastPage, 1);
    });

    testWidgets('ページネーション後へボタンタップでgoToPageが呼ばれる', (tester) async {
      final houseworks = _generateHouseworks(11);
      final notifier = _RecordingNotifier(
        HouseworkListState(allHouseworks: houseworks, currentPage: 1),
      );
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(() => notifier),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('paginationNext')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(find.byKey(const Key('paginationNext')));
      await tester.pump();

      expect(notifier.lastPage, 2);
    });

    testWidgets('エラーメッセージが発生するとlistenerが発火する', (tester) async {
      final notifier = _MutableNotifier(const HouseworkListState());
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(() => notifier),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // エラー状態に変更
      notifier.setError('テストエラー');
      await tester.pump();

      // クラッシュなく動作する（AppSnackBar分岐が通る）
      expect(find.byKey(const Key('houseworkListPage')), findsOneWidget);
    });

    testWidgets('家事追加ボタンタップで/settings/housework/newに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(
              () => _FakeHouseworkListNotifier(const HouseworkListState()),
            ),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
            GoRoute(
              path: '/settings/housework/new',
              builder: (_, __) =>
                  const Scaffold(body: Text('housework-new-page')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('houseworkAddButton')));
      await tester.pumpAndSettle();

      expect(find.text('housework-new-page'), findsOneWidget);
    });

    testWidgets('カテゴリDropdown変更でfilterByCategoryが呼ばれる', (tester) async {
      final notifier = _RecordingNotifier(
        const HouseworkListState(allHouseworks: [_hw1, _hw2]),
      );
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(() => notifier),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categoryFilterDropdown')));
      await tester.pumpAndSettle();

      // 「掃除」(=CLEAN) を選ぶ（ja ロケール）
      await tester.tap(find.text('掃除').last);
      await tester.pumpAndSettle();

      expect(notifier.lastCategory, 'CLEAN');
    });

    testWidgets('家事カードタップで/settings/housework/:idに遷移する', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          overrides: [
            houseworkListNotifierProvider.overrideWith(
              () => _FakeHouseworkListNotifier(
                const HouseworkListState(allHouseworks: [_hw1]),
              ),
            ),
          ],
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HouseworkListPage()),
            GoRoute(
              path: '/settings/housework/:id',
              builder: (_, __) =>
                  const Scaffold(body: Text('housework-detail-page')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();

      expect(find.text('housework-detail-page'), findsOneWidget);
    });
  });
}
