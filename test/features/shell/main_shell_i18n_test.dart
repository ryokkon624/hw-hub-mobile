import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/shell/main_shell.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(household) async {}
}

final _singleHouseholdState = HouseholdState(
  households: const [Household(id: 1, name: '我が家')],
  selectedHousehold: const Household(id: 1, name: '我が家'),
);

List<Override> _overrides() => [
  householdNotifierProvider.overrideWith(
    () => _FakeHouseholdNotifier(_singleHouseholdState),
  ),
];

/// NavigationBarが表示されるシンプルなGoRouterを組む。
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, _) => const Scaffold(body: Text('home')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/housework',
                builder: (_, _) => const Scaffold(body: Text('housework')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (_, _) => const Scaffold(body: Text('tasks')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (_, _) => const Scaffold(body: Text('shopping')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const Scaffold(body: Text('settings')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _buildApp(GoRouter router) {
  return ProviderScope(
    overrides: _overrides(),
    child: MaterialApp.router(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      routerConfig: router,
    ),
  );
}

void main() {
  group('MainShell - ナビゲーションラベルのi18n対応（#109）', () {
    testWidgets('ナビゲーションバーのラベルがAppLocalizationsから取得されている（日本語）', (tester) async {
      final router = _buildRouter();
      await tester.pumpWidget(_buildApp(router));
      await tester.pumpAndSettle();

      // 日本語ロケールで各ラベルが表示されること
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('家事分担'), findsOneWidget);
      expect(find.text('タスク'), findsOneWidget);
      expect(find.text('買い物'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('NavigationDestinationのラベルがハードコードされていない（英語ロケールで日本語が出ないこと）', (
      tester,
    ) async {
      final router = _buildRouter();
      // 英語ロケールで描画
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(),
          child: MaterialApp.router(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 英語ロケールでは日本語ラベルが出ないこと（ハードコードされていないことの証明）
      expect(find.text('ホーム'), findsNothing);
      expect(find.text('家事分担'), findsNothing);
      expect(find.text('タスク'), findsNothing);
      // '買い物' も出ないこと
      expect(find.text('買い物'), findsNothing);
      expect(find.text('設定'), findsNothing);
    });
  });
}
