import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/ui/app_dialog.dart';

import '../../helpers/widget_test_helpers.dart';

void main() {
  group('AppDialog.alert', () {
    testWidgets('タイトル・メッセージ・デフォルトOKボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppDialog.alert(
                  context,
                  title: 'アラートタイトル',
                  message: 'アラートメッセージ',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('アラートタイトル'), findsOneWidget);
      expect(find.text('アラートメッセージ'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('OKボタンタップでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppDialog.alert(
                  context,
                  title: 'タイトル',
                  message: 'メッセージ',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('カスタムokLabelが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppDialog.alert(
                  context,
                  title: 'タイトル',
                  message: 'メッセージ',
                  okLabel: '閉じる',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('閉じる'), findsOneWidget);
      expect(find.text('OK'), findsNothing);
    });

    testWidgets('カスタムokLabelタップでダイアログが閉じる', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppDialog.alert(
                  context,
                  title: 'タイトル',
                  message: 'メッセージ',
                  okLabel: '閉じる',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('AppDialog.confirm isDanger', () {
    testWidgets('isDanger=trueのとき確認ボタン・キャンセルボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppDialog.confirm(
                  context,
                  title: '削除確認',
                  message: '本当に削除しますか？',
                  confirmLabel: '削除',
                  isDanger: true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('削除確認'), findsOneWidget);
      expect(find.text('本当に削除しますか？'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
    });

    testWidgets('isDanger=true: 確認ボタンタップでtrueを返す', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await AppDialog.confirm(
                    context,
                    title: '削除確認',
                    message: '削除します',
                    confirmLabel: '削除',
                    isDanger: true,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('isDanger=true: キャンセルタップでfalseを返す', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await AppDialog.confirm(
                    context,
                    title: '削除確認',
                    message: '削除します',
                    confirmLabel: '削除',
                    isDanger: true,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
