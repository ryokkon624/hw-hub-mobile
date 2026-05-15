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
import 'package:hw_hub_mobile/features/shell/widgets/household_indicator_bar.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(household) async {}
}

/// 複数世帯の状態（インジケーターバーが表示される条件）
final _multiHouseholdState = HouseholdState(
  households: const [
    Household(id: 1, name: '我が家'),
    Household(id: 2, name: '実家'),
  ],
  selectedHousehold: const Household(id: 1, name: '我が家'),
);

List<Override> _overrides() => [
  householdNotifierProvider.overrideWith(
    () => _FakeHouseholdNotifier(_multiHouseholdState),
  ),
];

GoRouter _buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/shopping',
                builder: (_, _) => const Scaffold(body: Text('shopping-list')),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (_, _) =>
                        const Scaffold(body: Text('shopping-new')),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => Scaffold(
                      body: Text('shopping-detail-${s.pathParameters['id']}'),
                    ),
                  ),
                ],
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
  group('MainShell - HouseholdIndicatorBar 表示制御（#98）', () {
    testWidgets('買い物一覧（/shopping）では HouseholdIndicatorBar が表示される', (
      tester,
    ) async {
      final router = _buildRouter('/shopping');
      await tester.pumpWidget(_buildApp(router));
      await tester.pumpAndSettle();
      await tester.pump();

      expect(find.byType(HouseholdIndicatorBar), findsOneWidget);
      // 複数世帯なので世帯名が表示される
      expect(find.text('我が家'), findsOneWidget);
    });

    testWidgets('買い物アイテム追加画面（/shopping/new）では HouseholdIndicatorBar が非表示になる', (
      tester,
    ) async {
      final router = _buildRouter('/shopping');
      await tester.pumpWidget(_buildApp(router));
      await tester.pumpAndSettle();
      await tester.pump();

      // /shopping/new に遷移
      router.go('/shopping/new');
      await tester.pumpAndSettle();

      // shopping-new ページが表示される
      expect(find.text('shopping-new'), findsOneWidget);
      // HouseholdIndicatorBar が非表示（世帯名が表示されない）
      expect(find.text('我が家'), findsNothing);
    });

    testWidgets('買い物アイテム詳細（/shopping/:id）では HouseholdIndicatorBar が非表示になる', (
      tester,
    ) async {
      final router = _buildRouter('/shopping');
      await tester.pumpWidget(_buildApp(router));
      await tester.pumpAndSettle();
      await tester.pump();

      // /shopping/42 に遷移
      router.go('/shopping/42');
      await tester.pumpAndSettle();

      expect(find.text('shopping-detail-42'), findsOneWidget);
      expect(find.text('我が家'), findsNothing);
    });
  });
}
