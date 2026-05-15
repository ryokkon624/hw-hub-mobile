import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/theme/app_color_scheme.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/shopping/data/shopping_repository.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/shopping_list_state.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/swipeable_shopping_card.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

/// テスト用のアイテムを生成するヘルパー
ShoppingItemDto _item({
  int id = 1,
  String name = 'テストアイテム',
  String? storeType,
  String status = '0',
  String? memo,
  String? favorite = '0',
  bool hasImage = false,
}) => ShoppingItemDto(
  shoppingItemId: id,
  householdId: 1,
  name: name,
  memo: memo,
  storeType: storeType,
  status: status,
  favorite: favorite,
  purchasedAt: null,
  createdAt: '2026-05-01T10:00:00',
  hasImage: hasImage,
);

Widget _buildCard({
  required ShoppingItemDto item,
  ShoppingTab variant = ShoppingTab.unpurchased,
  bool enableSwipe = true,
  DismissDirection direction = DismissDirection.horizontal,
  VoidCallback? onTap,
  VoidCallback? onFavoriteTap,
  Future<bool> Function()? onPrimarySwipe,
  Future<bool> Function()? onSecondarySwipe,
}) => MaterialApp(
  locale: const Locale('ja'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.light,
  home: Scaffold(
    body: SwipeableShoppingCard(
      item: item,
      variant: variant,
      enableSwipe: enableSwipe,
      direction: direction,
      onTap: onTap ?? () {},
      onFavoriteTap: onFavoriteTap ?? () {},
      onPrimarySwipe: onPrimarySwipe ?? () async => true,
      onSecondarySwipe: onSecondarySwipe ?? () async => true,
    ),
  ),
);

void main() {
  group('SwipeableShoppingCard - 背景色（#89）', () {
    testWidgets('スーパー(storeType=1)のカードはpaletteEmeraldSoftが背景色に使われる', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard(item: _item(storeType: '1')));
      await tester.pump();

      final colors = AppColorScheme.light();
      // カード本体（_CardBody の Container）を探す
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasEmeraldBg = containers.any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == colors.paletteEmeraldSoft,
      );
      expect(hasEmeraldBg, isTrue);
    });

    testWidgets('オンライン(storeType=2)のカードはpaletteBlueSoftが背景色に使われる', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard(item: _item(storeType: '2')));
      await tester.pump();

      final colors = AppColorScheme.light();
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBlueBg = containers.any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == colors.paletteBlueSoft,
      );
      expect(hasBlueBg, isTrue);
    });

    testWidgets('ドラッグストア(storeType=3)のカードはpaletteRoseSoftが背景色に使われる', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard(item: _item(storeType: '3')));
      await tester.pump();

      final colors = AppColorScheme.light();
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasRoseBg = containers.any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == colors.paletteRoseSoft,
      );
      expect(hasRoseBg, isTrue);
    });

    testWidgets('購入場所なし(storeType=null)はsurfaceCardが背景色に使われる', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(storeType: null)));
      await tester.pump();

      final colors = AppColorScheme.light();
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSurfaceCardBg = containers.any(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration! as BoxDecoration).color == colors.surfaceCard,
      );
      expect(hasSurfaceCardBg, isTrue);
    });

    testWidgets('カラーバー（幅4pxのContainer）が表示されない（#89 AC2）', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(storeType: '1')));
      await tester.pump();

      // 幅4pxのContainerが存在しないことを確認
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasColorBar = containers.any(
        (c) => c.constraints?.maxWidth == 4 || c.constraints?.minWidth == 4,
      );
      expect(hasColorBar, isFalse);
    });
  });

  group('SwipeableShoppingCard - enableSwipe=falseのとき（#90）', () {
    testWidgets('enableSwipe=falseのときDismissibleが存在しない', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(), enableSwipe: false));
      await tester.pump();

      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('enableSwipe=trueのときDismissibleが存在する', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(), enableSwipe: true));
      await tester.pump();

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgets('enableSwipe=falseのときアイテム名が表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(
          item: _item(name: 'スーパーのもの', storeType: '1'),
          enableSwipe: false,
        ),
      );
      await tester.pump();

      expect(find.text('スーパーのもの'), findsOneWidget);
    });

    testWidgets('enableSwipe=falseのときonTapが呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildCard(
          item: _item(name: 'タップテスト'),
          enableSwipe: false,
          onTap: () => tapped = true,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('タップテスト'));
      expect(tapped, isTrue);
    });
  });

  group('SwipeableShoppingCard - directionパラメータ（#91）', () {
    testWidgets('direction=endToStartのときDismissibleのdirectionがendToStartになる', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildCard(
          item: _item(),
          enableSwipe: true,
          direction: DismissDirection.endToStart,
        ),
      );
      await tester.pump();

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.endToStart);
    });

    testWidgets(
      'direction=horizontalのときDismissibleのdirectionがhorizontalになる（デフォルト動作）',
      (tester) async {
        await tester.pumpWidget(_buildCard(item: _item(), enableSwipe: true));
        await tester.pump();

        final dismissible = tester.widget<Dismissible>(
          find.byType(Dismissible),
        );
        expect(dismissible.direction, DismissDirection.horizontal);
      },
    );

    testWidgets('directionパラメータを指定しない場合（デフォルト）はhorizontalになる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: Scaffold(
            body: SwipeableShoppingCard(
              item: _item(),
              variant: ShoppingTab.unpurchased,
              enableSwipe: true,
              onTap: () {},
              onFavoriteTap: () {},
              onPrimarySwipe: () async => true,
              onSecondarySwipe: () async => true,
            ),
          ),
        ),
      );
      await tester.pump();

      final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
      expect(dismissible.direction, DismissDirection.horizontal);
    });
  });

  group('SwipeableShoppingCard - カード内容の表示', () {
    testWidgets('アイテム名が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(name: 'オリーブオイル')));
      await tester.pump();
      expect(find.text('オリーブオイル'), findsOneWidget);
    });

    testWidgets('メモがある場合メモが表示される', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(memo: 'いつものやつ')));
      await tester.pump();
      expect(find.text('いつものやつ'), findsOneWidget);
    });

    testWidgets('お気に入り済みのアイテムにstarアイコンが表示される', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(favorite: '1')));
      await tester.pump();
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('お気に入り未設定はstar_borderアイコンが表示される', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(favorite: '0')));
      await tester.pump();
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('hasImage=trueのとき画像アイコンが表示される', (tester) async {
      await tester.pumpWidget(_buildCard(item: _item(hasImage: true)));
      await tester.pump();
      expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
    });
  });
}
