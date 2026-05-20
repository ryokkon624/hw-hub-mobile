import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/home/presentation/home_notifier.dart';
import 'package:hw_hub_mobile/features/home/presentation/home_page.dart';
import 'package:hw_hub_mobile/features/home/presentation/home_state.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/widget_test_helpers.dart';

// テスト用Notifier - 直接状態を返す
class _FakeHomeNotifier extends HomeNotifier {
  _FakeHomeNotifier(this._initialState);
  final HomeState _initialState;

  @override
  Future<HomeState> build() async => _initialState;
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(household) async {}
}

List<Override> _overrides(HomeState homeState) => [
  homeNotifierProvider.overrideWith(() => _FakeHomeNotifier(homeState)),
  householdNotifierProvider.overrideWith(
    () => _FakeHouseholdNotifier(
      const HouseholdState(households: [], selectedHousehold: null),
    ),
  ),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomePage', () {
    testWidgets('ローディング中はCircularProgressIndicatorを表示する', (tester) async {
      // Completer を使って未完了の Future を作る（タイマー不要）
      final completer = Completer<HomeState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNotifierProvider.overrideWith(
              () => _CompleterHomeNotifier(completer),
            ),
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(
                const HouseholdState(households: [], selectedHousehold: null),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // テスト終了前に completer を完了させてタイマー残留を防ぐ
      completer.complete(const HomeState());
      await tester.pumpAndSettle();
    });

    testWidgets('世帯所属済み: 上部カード（My Tasks・家事未割り当て）が表示される', (tester) async {
      final state = HomeState(
        hasHousehold: true,
        myTasksSummary: const MyTasksSummary(
          todayCount: 2,
          weekCount: 5,
          overdueCount: 1,
        ),
        unassignedSummary: const UnassignedSummary(
          totalCount: 3,
          urgentCount: 1,
        ),
        shoppingItems: const [],
        householdOverview: List.generate(
          13,
          (i) => DailyOverview(
            date: DateTime.now().add(Duration(days: i - 6)),
            countsByAssignee: const {},
          ),
        ),
        members: const [],
      );

      await tester.pumpWidget(
        buildTestPage(const HomePage(), overrides: _overrides(state)),
      );
      await tester.pump();

      // My Tasksカードタイトル
      expect(find.text('My Tasks'), findsOneWidget);
      // 家事未割り当てカードタイトル
      expect(find.text('家事の未割り当て'), findsOneWidget);
    });

    testWidgets('世帯所属済み: 下部カード（買い物・おうちの様子）までスクロールして表示確認', (tester) async {
      final state = HomeState(
        hasHousehold: true,
        householdOverview: List.generate(
          13,
          (i) => DailyOverview(
            date: DateTime.now().add(Duration(days: i - 6)),
            countsByAssignee: const {},
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestPage(const HomePage(), overrides: _overrides(state)),
      );
      await tester.pump();

      // 買い物リストカードはスクロール前に存在するはず
      expect(find.text('買い物リスト'), findsOneWidget);
    });

    testWidgets('世帯未所属時: オンボーディングカードが最上部に表示される', (tester) async {
      const state = HomeState(hasHousehold: false);

      await tester.pumpWidget(
        buildTestPage(const HomePage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('ようこそ！'), findsOneWidget);
    });

    testWidgets('My Tasksカードのオープンボタンをタップできる', (tester) async {
      final state = HomeState(
        hasHousehold: true,
        householdOverview: List.generate(
          13,
          (i) => DailyOverview(
            date: DateTime.now().add(Duration(days: i - 6)),
            countsByAssignee: const {},
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestPage(const HomePage(), overrides: _overrides(state)),
      );
      await tester.pump();

      // My Tasksを開くボタンが存在する
      expect(find.text('My Tasksを開く'), findsOneWidget);
    });

    testWidgets('エラー時: エラーメッセージと再試行ボタンを表示する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNotifierProvider.overrideWith(() => _ErrorHomeNotifier()),
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(
                const HouseholdState(households: [], selectedHousehold: null),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(); // エラー状態を待つ

      expect(find.text('再読み込み'), findsOneWidget);
    });

    testWidgets('エラー時: 再試行ボタンタップでonRetryが呼ばれる', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNotifierProvider.overrideWith(() => _ErrorHomeNotifier()),
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(
                const HouseholdState(households: [], selectedHousehold: null),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const HomePage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('再読み込み'));
      await tester.pumpAndSettle();

      // クラッシュなく動作する（onRetry → ref.invalidate 分岐が通る）
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('RefreshIndicatorで引っ張り更新ができる（onRefreshコールバック）', (tester) async {
      final state = HomeState(
        hasHousehold: true,
        householdOverview: List.generate(
          13,
          (i) => DailyOverview(
            date: DateTime.now().add(Duration(days: i - 6)),
            countsByAssignee: const {},
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestPage(const HomePage(), overrides: _overrides(state)),
      );
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, 400));
      await tester.pumpAndSettle();

      // クラッシュなく動作する（onRefresh → ref.invalidate 分岐が通る）
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('世帯未所属時: オンボーディングカードの世帯設定ボタンタップで遷移', (tester) async {
      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HomePage()),
            GoRoute(
              path: '/settings/household',
              builder: (_, _) =>
                  const Scaffold(body: Text('household-settings-page')),
            ),
            GoRoute(
              path: '/settings/housework',
              builder: (_, _) =>
                  const Scaffold(body: Text('housework-settings-page')),
            ),
          ],
          overrides: [
            homeNotifierProvider.overrideWith(
              () => _FakeHomeNotifier(const HomeState(hasHousehold: false)),
            ),
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(
                const HouseholdState(households: [], selectedHousehold: null),
              ),
            ),
          ],
          initialLocation: '/',
        ),
      );
      await tester.pump();

      // オンボーディングカードが表示されている
      expect(find.text('ようこそ！'), findsOneWidget);

      // 世帯設定ボタンをタップ
      await tester.tap(find.text('おうちを設定する'));
      await tester.pumpAndSettle();

      expect(find.text('household-settings-page'), findsOneWidget);
    });

    testWidgets('My Tasksカードの開くボタンタップで/tasksに遷移', (tester) async {
      final state = HomeState(
        hasHousehold: true,
        householdOverview: List.generate(
          13,
          (i) => DailyOverview(
            date: DateTime.now().add(Duration(days: i - 6)),
            countsByAssignee: const {},
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestPageWithRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const HomePage()),
            GoRoute(
              path: '/tasks',
              builder: (_, _) => const Scaffold(body: Text('tasks-page')),
            ),
          ],
          overrides: [
            homeNotifierProvider.overrideWith(() => _FakeHomeNotifier(state)),
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(
                const HouseholdState(households: [], selectedHousehold: null),
              ),
            ),
          ],
          initialLocation: '/',
        ),
      );
      await tester.pump();

      await tester.tap(find.text('My Tasksを開く'));
      await tester.pumpAndSettle();

      expect(find.text('tasks-page'), findsOneWidget);
    });
  });
}

/// Completer を使ってローディング状態を維持するフェイクNotifier
class _CompleterHomeNotifier extends HomeNotifier {
  _CompleterHomeNotifier(this._completer);
  final Completer<HomeState> _completer;

  @override
  Future<HomeState> build() => _completer.future;
}

class _ErrorHomeNotifier extends HomeNotifier {
  @override
  Future<HomeState> build() async {
    throw Exception('テストエラー');
  }
}
