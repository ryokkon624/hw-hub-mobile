import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/app_router.dart';
import 'package:hw_hub_mobile/features/notifications/presentation/widgets/notification_link_navigator.dart';

Widget _buildWithRouter({
  required Widget home,
  required List<GoRoute> extraRoutes,
}) {
  return MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        ...extraRoutes,
      ],
    ),
  );
}

void main() {
  group('NotificationLinkNavigator', () {
    testWidgets('linkType=MyTasks の場合 /tasks に遷移する', (tester) async {
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'MyTasks',
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [
            GoRoute(
              path: '/tasks',
              builder: (_, _) => const Scaffold(body: Text('tasks-page')),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      expect(find.text('tasks-page'), findsOneWidget);
    });

    testWidgets('linkType=Household の場合 /settings/household に遷移する', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'Household',
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings')),
              routes: [
                GoRoute(
                  path: 'household',
                  builder: (_, _) =>
                      const Scaffold(body: Text('household-page')),
                ),
              ],
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      expect(find.text('household-page'), findsOneWidget);
    });

    testWidgets('linkType=Invite の場合 /settings/household に遷移する', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'Invite',
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings')),
              routes: [
                GoRoute(
                  path: 'household',
                  builder: (_, _) =>
                      const Scaffold(body: Text('household-page')),
                ),
              ],
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      expect(find.text('household-page'), findsOneWidget);
    });

    testWidgets('linkType=Settings の場合 /settings/account に遷移する', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'Settings',
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const Scaffold(body: Text('settings')),
              routes: [
                GoRoute(
                  path: 'account',
                  builder: (_, _) => const Scaffold(body: Text('account-page')),
                ),
              ],
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      expect(find.text('account-page'), findsOneWidget);
    });

    testWidgets(
      'linkType=Inquiry, linkId=42 の場合 /settings/inquiries/42 に遷移する',
      (tester) async {
        await tester.pumpWidget(
          _buildWithRouter(
            home: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('btn'),
                onPressed: () => NotificationLinkNavigator.navigate(
                  context: context,
                  linkType: 'Inquiry',
                  linkId: 42,
                ),
                child: const Text('tap'),
              ),
            ),
            extraRoutes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const Scaffold(body: Text('settings')),
                routes: [
                  GoRoute(
                    path: 'inquiries',
                    builder: (_, _) => const Scaffold(body: Text('list')),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, _) =>
                            const Scaffold(body: Text('inquiry-detail-page')),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

        await tester.tap(find.byKey(const Key('btn')));
        await tester.pumpAndSettle();

        expect(find.text('inquiry-detail-page'), findsOneWidget);
      },
    );

    testWidgets('linkType=Inquiry, linkId=null の場合は遷移しない', (tester) async {
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'Inquiry',
                linkId: null,
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      // 遷移しないため元のボタンが表示されたまま
      expect(find.byKey(const Key('btn')), findsOneWidget);
    });

    testWidgets('linkType=None の場合は遷移しない', (tester) async {
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'None',
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn')), findsOneWidget);
    });

    testWidgets('不明なlinkTypeの場合は遷移しない', (tester) async {
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'UNKNOWN_TYPE',
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn')), findsOneWidget);
    });

    testWidgets('/notificationsから遷移するとき、canPopがtrueの場合はpopされてからpushされる', (
      tester,
    ) async {
      // /notifications ルートから通知をタップした場合に、通知センターが閉じてから遷移先に移動するかを確認。
      // ホーム画面から /notifications へ push した状態をシミュレートする。
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      key: const Key('open-notifications'),
                      onPressed: () => context.push(AppRoutes.notifications),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: AppRoutes.notifications,
                builder: (_, _) => Builder(
                  builder: (context) => Scaffold(
                    body: ElevatedButton(
                      key: const Key('btn'),
                      onPressed: () => NotificationLinkNavigator.navigate(
                        context: context,
                        linkType: 'MyTasks',
                      ),
                      child: const Text('tap'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/tasks',
                builder: (_, _) => const Scaffold(body: Text('tasks-page')),
              ),
            ],
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ホームから /notifications へ push
      await tester.tap(find.byKey(const Key('open-notifications')));
      await tester.pumpAndSettle();

      // 通知センター画面が表示されていることを確認
      expect(find.byKey(const Key('btn')), findsOneWidget);

      // 通知をタップ → pop(/notifications) → push(/tasks)
      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      // 遷移先(/tasks)に移動していること
      expect(find.text('tasks-page'), findsOneWidget);
    });

    testWidgets('/notifications以外から遷移するとき、popせずにpushされる', (tester) async {
      // /notifications 以外のルートから navigate() を呼んだ場合は pop しないことを確認
      await tester.pumpWidget(
        _buildWithRouter(
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('btn'),
              onPressed: () => NotificationLinkNavigator.navigate(
                context: context,
                linkType: 'MyTasks',
              ),
              child: const Text('tap'),
            ),
          ),
          extraRoutes: [
            GoRoute(
              path: '/tasks',
              builder: (_, _) => const Scaffold(body: Text('tasks-page')),
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pumpAndSettle();

      // /tasks へ遷移していること（pop して home に戻っていないこと）
      expect(find.text('tasks-page'), findsOneWidget);
    });
  });
}
