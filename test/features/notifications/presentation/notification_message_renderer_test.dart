import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/widgets/notification_message_renderer.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

Widget _buildWithL10n(Widget child) => MaterialApp(
  locale: const Locale('ja'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('taskAssigned キー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle('taskAssigned', {}),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody('taskAssigned', {
                    'actorName': 'ママ',
                    'household': '自宅',
                    'date': '2026/05/01',
                    'count': '2',
                  }),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(
      (tester.widget(find.byKey(const Key('title'))) as Text).data,
      'タスクが割り当てられました',
    );
    expect(
      (tester.widget(find.byKey(const Key('body'))) as Text).data,
      'ママによってタスクが割り当てられました。おうち: 自宅, 日付: 2026/05/01, 件数: 2件',
    );
  });

  testWidgets('yourTaskWasTaken キー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle('yourTaskWasTaken', {}),
                  key: const Key('title'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(
      (tester.widget(find.byKey(const Key('title'))) as Text).data,
      '他メンバーがあなたのタスクを奪いました',
    );
  });

  testWidgets('不明なキー: キー文字列をそのまま返す（Web版と同じ挙動）', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle('unknownKey', {}),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody('unknownKey', {}),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(
      (tester.widget(find.byKey(const Key('title'))) as Text).data,
      'unknownKey',
    );
    expect(
      (tester.widget(find.byKey(const Key('body'))) as Text).data,
      'unknownKey',
    );
  });

  testWidgets('inquiryReplied キー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle('inquiryReplied', {}),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody('inquiryReplied', {
                    'inquiryId': '42',
                    'title': 'テスト問い合わせ',
                  }),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(
      (tester.widget(find.byKey(const Key('title'))) as Text).data,
      '問い合わせに返信が届きました',
    );
    expect(
      (tester.widget(find.byKey(const Key('body'))) as Text).data,
      '#42「テスト問い合わせ」に返信が届いています。内容をご確認ください。',
    );
  });
}
