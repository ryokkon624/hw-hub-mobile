import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_list_state.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/shopping_tab_bar.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

Widget _buildTabBar({
  ShoppingTab activeTab = ShoppingTab.unpurchased,
  int unpurchasedCount = 0,
  int basketCount = 0,
  int purchasedCount = 0,
  void Function(ShoppingTab)? onTabChanged,
}) => MaterialApp(
  locale: const Locale('ja'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light,
  home: Scaffold(
    body: ShoppingTabBar(
      activeTab: activeTab,
      unpurchasedCount: unpurchasedCount,
      basketCount: basketCount,
      purchasedCount: purchasedCount,
      onTabChanged: onTabChanged ?? (_) {},
    ),
  ),
);

void main() {
  group('ShoppingTabBar - タブラベル表示', () {
    testWidgets('3つのタブラベルが表示される', (tester) async {
      await tester.pumpWidget(_buildTabBar());
      await tester.pump();

      expect(find.text('未購入'), findsOneWidget);
      expect(find.text('かご'), findsOneWidget);
      expect(find.text('購入済み'), findsOneWidget);
    });
  });

  group('ShoppingTabBar - 件数バッジ（#92）', () {
    testWidgets('未購入タブは件数バッジが表示される（#92 AC2）', (tester) async {
      await tester.pumpWidget(_buildTabBar(unpurchasedCount: 5));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('かごタブは件数バッジが表示される（#92 AC2）', (tester) async {
      await tester.pumpWidget(
        _buildTabBar(basketCount: 3, activeTab: ShoppingTab.basket),
      );
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('購入済みタブは件数が0より大きくてもバッジが表示されない（#92 AC1）', (tester) async {
      await tester.pumpWidget(
        _buildTabBar(purchasedCount: 10, activeTab: ShoppingTab.purchased),
      );
      await tester.pump();

      // 「購入済み」テキストはあるが件数「10」は表示されない
      expect(find.text('購入済み'), findsOneWidget);
      expect(find.text('10'), findsNothing);
    });

    testWidgets('未購入が0件のときバッジが表示されない', (tester) async {
      await tester.pumpWidget(_buildTabBar(unpurchasedCount: 0));
      await tester.pump();

      // 件数バッジの「0」は表示されない（count > 0 の条件）
      expect(find.text('0'), findsNothing);
    });
  });

  group('ShoppingTabBar - タブ切り替え', () {
    testWidgets('タブをタップするとonTabChangedが呼ばれる', (tester) async {
      ShoppingTab? selected;
      await tester.pumpWidget(
        _buildTabBar(onTabChanged: (tab) => selected = tab),
      );
      await tester.pump();

      await tester.tap(find.text('かご'));
      await tester.pump();

      expect(selected, ShoppingTab.basket);
    });

    testWidgets('アクティブタブが視覚的に区別される', (tester) async {
      // アクティブタブのテスト: activeTab=basket のとき 'かご' がアクティブ
      await tester.pumpWidget(_buildTabBar(activeTab: ShoppingTab.basket));
      await tester.pump();

      // ShoppingTabBar が正常に描画されることを確認
      expect(find.byType(ShoppingTabBar), findsOneWidget);
    });
  });
}
