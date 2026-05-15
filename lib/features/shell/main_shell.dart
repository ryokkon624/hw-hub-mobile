import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_router.dart';
import '../../core/theme/app_color_scheme.dart';
import 'widgets/household_indicator_bar.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// 現在のルートで HouseholdIndicatorBar を非表示にするか判定する。
  /// 買い物アイテム追加・詳細画面では非表示。
  bool _shouldHideIndicator(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return location == AppRoutes.shoppingNew ||
        location.startsWith('/shopping/') &&
            location != AppRoutes.shopping &&
            location != AppRoutes.shoppingNew;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final hideIndicator = _shouldHideIndicator(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          hideIndicator
              ? const SizedBox.shrink()
              : const HouseholdIndicatorBar(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            backgroundColor: colors.surfaceCard,
            indicatorColor: colors.primary50,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: colors.primary),
                label: 'ホーム',
              ),
              NavigationDestination(
                icon: const Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment, color: colors.primary),
                label: '家事分担',
              ),
              NavigationDestination(
                icon: const Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle, color: colors.primary),
                label: 'タスク',
              ),
              NavigationDestination(
                icon: const Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart, color: colors.primary),
                label: '買い物',
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings, color: colors.primary),
                label: '設定',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
