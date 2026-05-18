import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/ui/user_avatar.dart';

import '../../helpers/widget_test_helpers.dart';

Widget _buildAvatar({
  String? iconUrl,
  required String label,
  bool isUnassigned = false,
  UserAvatarSize size = UserAvatarSize.md,
}) => buildTestPage(
  UserAvatar(
    iconUrl: iconUrl,
    label: label,
    isUnassigned: isUnassigned,
    size: size,
  ),
);

void main() {
  group('UserAvatar AC1: iconUrlが設定されている場合', () {
    testWidgets('AC1: iconUrlが設定されている場合はImage.networkが表示される', (tester) async {
      await tester.pumpWidget(
        _buildAvatar(iconUrl: 'https://example.com/icon.png', label: 'テストユーザー'),
      );
      await tester.pump();

      // Image.network が表示される
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('AC1: iconUrlがnullの場合はイニシャルが表示される', (tester) async {
      await tester.pumpWidget(_buildAvatar(iconUrl: null, label: 'テストユーザー'));
      await tester.pumpAndSettle();

      // Image は表示されない
      expect(find.byType(Image), findsNothing);
      // イニシャル（先頭2文字）が表示される
      expect(find.text('テス'), findsOneWidget);
    });
  });

  group('UserAvatar AC2: イニシャル表示', () {
    testWidgets('AC2: iconUrlなしの場合はlabelの先頭2文字が表示される', (tester) async {
      await tester.pumpWidget(
        _buildAvatar(iconUrl: null, label: 'Taro Yamada'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ta'), findsOneWidget);
    });

    testWidgets('AC2: label が1文字の場合はその1文字が表示される', (tester) async {
      await tester.pumpWidget(_buildAvatar(iconUrl: null, label: 'A'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('AC2: 未割当の場合は「未」ラベルが表示される', (tester) async {
      await tester.pumpWidget(
        _buildAvatar(iconUrl: null, label: '未割当', isUnassigned: true),
      );
      await tester.pumpAndSettle();
      // 未割当バッジには label のイニシャルではなくARBキーのテキストが表示される
      expect(find.text('未'), findsOneWidget);
    });
  });

  group('UserAvatar サイズ', () {
    testWidgets('sm サイズで UserAvatar が表示される', (tester) async {
      await tester.pumpWidget(
        _buildAvatar(iconUrl: null, label: 'Test', size: UserAvatarSize.sm),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('lg サイズで UserAvatar が表示される', (tester) async {
      await tester.pumpWidget(
        _buildAvatar(iconUrl: null, label: 'Test', size: UserAvatarSize.lg),
      );
      await tester.pumpAndSettle();
      expect(find.byType(UserAvatar), findsOneWidget);
    });
  });
}
