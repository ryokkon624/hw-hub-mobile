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
  // バックエンドが DB に保存するフルパス形式のキー値でレンダリングできることを検証する。
  // NotificationPublisher / NotificationAggregationService が
  // 'notifications.messages.xxx.title' / 'notifications.messages.xxx.body' 形式で保存する。

  testWidgets('taskAssigned フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.taskAssigned.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer
                      .renderBody('notifications.messages.taskAssigned.body', {
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
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('yourTaskWasTaken フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.yourTaskWasTaken.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
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

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('inquiryReplied フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.inquiryReplied.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody(
                    'notifications.messages.inquiryReplied.body',
                    {'inquiryId': '42', 'title': 'テスト問い合わせ'},
                  ),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('acceptInvitation フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.acceptInvitation.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody(
                    'notifications.messages.acceptInvitation.body',
                    {'householdName': '山田家', 'memberName': '太郎'},
                  ),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('declineInvitation フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.declineInvitation.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody(
                    'notifications.messages.declineInvitation.body',
                    {'householdName': '山田家', 'memberName': '花子'},
                  ),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('removedFromHousehold フルパスキー: タイトルと本文が正しくレンダリングされる', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.removedFromHousehold.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody(
                    'notifications.messages.removedFromHousehold.body',
                    {'householdName': '山田家'},
                  ),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('leftHousehold フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.leftHousehold.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody(
                    'notifications.messages.leftHousehold.body',
                    {'householdName': '山田家', 'memberName': '太郎'},
                  ),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('assigned2Owner フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.assigned2Owner.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody(
                    'notifications.messages.assigned2Owner.body',
                    {'householdName': '山田家'},
                  ),
                  key: const Key('body'),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.byKey(const Key('title')), findsOneWidget);
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('beDumpedTasks フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.beDumpedTasks.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer
                      .renderBody('notifications.messages.beDumpedTasks.body', {
                        'actorName': 'パパ',
                        'household': '自宅',
                        'date': '2026/05/01',
                        'count': '3',
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
    expect(find.byKey(const Key('body')), findsOneWidget);
  });

  testWidgets('generic フルパスキー: タイトルと本文が正しくレンダリングされる', (tester) async {
    await tester.pumpWidget(
      _buildWithL10n(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            final renderer = NotificationMessageRenderer(l10n: l10n);
            return Column(
              children: [
                Text(
                  renderer.renderTitle(
                    'notifications.messages.generic.title',
                    {},
                  ),
                  key: const Key('title'),
                ),
                Text(
                  renderer.renderBody('notifications.messages.generic.body', {
                    'household': '自宅',
                    'date': '2026/05/01',
                    'count': '1',
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
    expect(find.byKey(const Key('body')), findsOneWidget);
  });
}
