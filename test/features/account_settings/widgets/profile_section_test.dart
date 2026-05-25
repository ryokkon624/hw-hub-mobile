import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/account_settings/data/models/user_profile_dto.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/widgets/profile_section.dart';

import '../../../helpers/widget_test_helpers.dart';

const _profile = UserProfileDto(
  userId: 1,
  email: 'test@example.com',
  authProvider: 'LOCAL',
  displayName: 'テスト太郎',
  locale: 'ja',
  iconUrl: null,
);

Widget _buildSection({
  UserProfileDto profile = _profile,
  Future<void> Function(String, String)? onSave,
}) {
  return buildTestPage(
    Scaffold(
      body: SingleChildScrollView(
        child: ProfileSection(
          profile: profile,
          onSave: onSave ?? (_, _) async {},
        ),
      ),
    ),
  );
}

void main() {
  group('ProfileSection', () {
    testWidgets('表示名テキストフィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('初期値として profile.displayName がセットされている', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'テスト太郎');
    });

    testWidgets('初期状態（変更なし）: 保存ボタンが無効', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('表示名を変更すると保存ボタンが有効になる', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '新しい名前');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('空白のみの名前を入力すると保存ボタンが無効のまま', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('言語選択DropdownButtonFormFieldが表示される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('保存ボタンをタップするとonSaveが呼ばれる', (tester) async {
      bool saveCalled = false;
      await tester.pumpWidget(
        _buildSection(
          onSave: (displayName, locale) async {
            saveCalled = true;
          },
        ),
      );
      await tester.pump();

      // 名前を変更して保存ボタンを有効にする
      await tester.enterText(find.byType(TextField), '新しい名前');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(saveCalled, isTrue);
    });

    testWidgets('言語Dropdownの変更で選択値が更新される', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // 英語を選択（2番目）
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      // 保存ボタンが有効になる（locale変更でdirty）
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('didUpdateWidget: 親からprofileが変わるとコントローラが更新される', (tester) async {
      const profile1 = UserProfileDto(
        userId: 1,
        email: 'test@example.com',
        authProvider: 'LOCAL',
        displayName: '初期名前',
        locale: 'ja',
        iconUrl: null,
      );
      const profile2 = UserProfileDto(
        userId: 1,
        email: 'test@example.com',
        authProvider: 'LOCAL',
        displayName: '更新後の名前',
        locale: 'en',
        iconUrl: null,
      );

      UserProfileDto currentProfile = profile1;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => buildTestPage(
            Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () => setState(() => currentProfile = profile2),
                    child: const Text('change'),
                  ),
                  SingleChildScrollView(
                    child: ProfileSection(
                      profile: currentProfile,
                      onSave: (_, _) async {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 初期状態確認
      expect(
        (tester.widget<TextField>(find.byType(TextField))).controller?.text,
        '初期名前',
      );

      // profile2 に変更
      await tester.tap(find.text('change'));
      await tester.pump();

      // didUpdateWidget が呼ばれコントローラが更新される
      expect(
        (tester.widget<TextField>(find.byType(TextField))).controller?.text,
        '更新後の名前',
      );
    });
  });
}
