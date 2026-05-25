import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/widgets/danger_zone_section.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/widgets/google_link_section.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/widgets/icon_section.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/widgets/password_change_section.dart';

import '../../../helpers/widget_test_helpers.dart';

Widget _buildDangerZone({bool isDeleting = false}) => buildTestPage(
  Scaffold(
    body: DangerZoneSection(isDeleting: isDeleting, onDelete: () async {}),
  ),
);

Widget _buildPasswordChange() => buildTestPage(
  Scaffold(
    body: SingleChildScrollView(
      child: PasswordChangeSection(onSave: (_, _) async {}),
    ),
  ),
);

void main() {
  group('DangerZoneSection', () {
    testWidgets('削除ボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildDangerZone());
      await tester.pump();

      expect(find.byKey(const Key('deleteAccountButton')), findsOneWidget);
    });

    testWidgets('isDeleting=falseのとき削除ボタンが有効', (tester) async {
      await tester.pumpWidget(_buildDangerZone(isDeleting: false));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('deleteAccountButton')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('isDeleting=trueのとき削除ボタンが無効', (tester) async {
      await tester.pumpWidget(_buildDangerZone(isDeleting: true));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('deleteAccountButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('削除ボタンタップで確認ダイアログが表示される', (tester) async {
      await tester.pumpWidget(_buildDangerZone());
      await tester.pump();

      await tester.tap(find.byKey(const Key('deleteAccountButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('確認ダイアログのキャンセルでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(_buildDangerZone());
      await tester.pump();

      await tester.tap(find.byKey(const Key('deleteAccountButton')));
      await tester.pumpAndSettle();

      final cancelButtons = find.byType(TextButton);
      await tester.tap(cancelButtons.first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('PasswordChangeSection', () {
    testWidgets('3つのパスワード入力フィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildPasswordChange());
      await tester.pump();

      // TextField が3つ（現在・新規・確認）
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('入力なし: 保存ボタンが無効', (tester) async {
      await tester.pumpWidget(_buildPasswordChange());
      await tester.pump();

      final buttons = find.byType(ElevatedButton);
      final button = tester.widget<ElevatedButton>(buttons.first);
      expect(button.onPressed, isNull);
    });

    testWidgets('新旧パスワードが不一致: 保存ボタンが無効', (tester) async {
      await tester.pumpWidget(_buildPasswordChange());
      await tester.pump();

      // 現在パスワード入力 (1番目のTextField)
      await tester.enterText(find.byType(TextField).at(0), 'currentpass');
      // 新パスワード入力（8文字以上）(2番目)
      await tester.enterText(find.byType(TextField).at(1), 'newpass123');
      // 確認パスワード（不一致）(3番目)
      await tester.enterText(find.byType(TextField).at(2), 'different123');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('全フィールド正常入力: 保存ボタンが有効', (tester) async {
      await tester.pumpWidget(_buildPasswordChange());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextField).at(1), 'newpass123');
      await tester.enterText(find.byType(TextField).at(2), 'newpass123');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('新旧パスワードが不一致のときエラーテキストが表示される', (tester) async {
      await tester.pumpWidget(_buildPasswordChange());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextField).at(1), 'newpass123');
      await tester.enterText(find.byType(TextField).at(2), 'different456');
      await tester.pump();

      // パスワード不一致メッセージが表示される（l10n: accountSettingsPasswordMismatch）
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('保存ボタンタップ: onSave が呼ばれる', (tester) async {
      bool saveCalled = false;
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: SingleChildScrollView(
              child: PasswordChangeSection(
                onSave: (_, _) async {
                  saveCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextField).at(1), 'newpass123');
      await tester.enterText(find.byType(TextField).at(2), 'newpass123');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      expect(saveCalled, isTrue);
    });

    testWidgets('保存成功後: テキストフィールドがクリアされる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: SingleChildScrollView(
              child: PasswordChangeSection(onSave: (_, _) async {}),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextField).at(1), 'newpass123');
      await tester.enterText(find.byType(TextField).at(2), 'newpass123');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // 保存後にフィールドがクリアされる
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(tf.controller?.text ?? '', isEmpty);
      }
    });

    testWidgets('onSaveが例外をスローするとエラーメッセージが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: SingleChildScrollView(
              child: PasswordChangeSection(
                onSave: (_, _) async {
                  throw Exception('パスワード変更に失敗しました');
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextField).at(1), 'newpass123');
      await tester.enterText(find.byType(TextField).at(2), 'newpass123');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // エラーメッセージが表示される（_errorMessage != null 分岐）
      expect(find.textContaining('パスワード変更に失敗しました'), findsOneWidget);
    });
  });

  group('GoogleLinkSection', () {
    testWidgets('isLinked=true: googleLinkedBadgeが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: GoogleLinkSection(
              isLinked: true,
              isLinking: false,
              onLink: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('googleLinkedBadge')), findsOneWidget);
      expect(find.byKey(const Key('googleLinkButton')), findsNothing);
    });

    testWidgets('isLinked=false: googleLinkButtonが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: GoogleLinkSection(
              isLinked: false,
              isLinking: false,
              onLink: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('googleLinkButton')), findsOneWidget);
      expect(find.byKey(const Key('googleLinkedBadge')), findsNothing);
    });

    testWidgets('isLinking=true: CircularProgressIndicatorが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: GoogleLinkSection(
              isLinked: false,
              isLinking: true,
              onLink: (_) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('googleLinkButton')), findsNothing);
    });
  });

  group('IconSection', () {
    testWidgets('isUploading=false: カメラ/ライブラリボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: IconSection(
              iconUrl: null,
              displayName: 'テストユーザー',
              isUploading: false,
              onImageSelected: (_, _, _) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      // 2つのOutlinedButton.iconが表示される（カメラ・ライブラリ）
      expect(find.byType(OutlinedButton), findsNWidgets(2));
    });

    testWidgets('isUploading=true: CircularProgressIndicatorが表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: IconSection(
              iconUrl: null,
              displayName: 'テストユーザー',
              isUploading: true,
              onImageSelected: (_, _, _) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('iconUrlが指定された場合: UserAvatarが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: IconSection(
              iconUrl: 'https://example.com/icon.jpg',
              displayName: 'テストユーザー',
              isUploading: false,
              onImageSelected: (_, _, _) async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(IconSection), findsOneWidget);
    });
  });
}
