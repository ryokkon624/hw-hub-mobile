import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  });
}
