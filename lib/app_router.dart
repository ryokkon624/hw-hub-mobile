import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_state.dart';
import 'core/di/providers.dart';
import 'features/shell/main_shell.dart';

// ログイン不要なパス（前方一致）
const _publicPrefixes = [
  '/login',
  '/signup',
  '/email-waiting',
  '/forgot-password',
  '/auth-result',
  '/email-verify',
  '/invite',
  '/password/reset',
];

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: _routes,
  );
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authNotifierProvider);
    if (authAsync.isLoading) return null;

    final isAuth = authAsync.valueOrNull is AuthAuthenticated;
    final path = state.matchedLocation;
    final isPublic = _publicPrefixes.any((p) => path.startsWith(p));

    if (!isAuth && !isPublic) return '/login';
    if (isAuth && path.startsWith('/login')) return '/';
    return null;
  }
}

final _routes = <RouteBase>[
  // ─── 未認証ルート ────────────────────────────────────────
  GoRoute(path: '/login',         builder: (_, _) => const _P('ログイン')),
  GoRoute(path: '/signup',        builder: (_, _) => const _P('サインアップ')),
  GoRoute(path: '/email-waiting', builder: (_, _) => const _P('認証メール待機')),
  GoRoute(
    path: '/forgot-password',
    builder: (_, _) => const _P('パスワード忘れ'),
    routes: [
      GoRoute(path: 'sent', builder: (_, _) => const _P('リセットメール送信')),
    ],
  ),
  GoRoute(path: '/auth-result', builder: (_, _) => const _P('認証結果')),

  // ─── ディープリンク（認証状態問わず受け取る）──────────────
  // /email-verify?token=<TOKEN>
  GoRoute(
    path: '/email-verify',
    builder: (_, state) => _P(
      'メール認証\ntoken: ${state.uri.queryParameters['token'] ?? ''}',
    ),
  ),
  // /invite/:token  ログイン状態で分岐はページ側で行う
  GoRoute(
    path: '/invite/:token',
    builder: (_, state) => _P(
      '招待受け取り\ntoken: ${state.pathParameters['token'] ?? ''}',
    ),
  ),
  // /password/reset?token=<TOKEN>
  GoRoute(
    path: '/password/reset',
    builder: (_, state) => _P(
      'パスワード再設定\ntoken: ${state.uri.queryParameters['token'] ?? ''}',
    ),
  ),

  // ─── 認証済みシェル（ボトムナビ）────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => MainShell(navigationShell: shell),
    branches: [
      // ホーム
      StatefulShellBranch(routes: [
        GoRoute(path: '/', builder: (_, _) => const _P('ホーム')),
      ]),
      // 家事分担
      StatefulShellBranch(routes: [
        GoRoute(path: '/housework', builder: (_, _) => const _P('家事分担')),
      ]),
      // My Tasks
      StatefulShellBranch(routes: [
        GoRoute(path: '/tasks', builder: (_, _) => const _P('My Tasks')),
      ]),
      // 買い物
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/shopping',
          builder: (_, _) => const _P('買い物リスト'),
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const _P('買い物アイテム作成')),
            GoRoute(
              path: ':id',
              builder: (_, s) => _P('買い物アイテム詳細 ${s.pathParameters['id']}'),
            ),
          ],
        ),
      ]),
      // 設定
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/settings',
          builder: (_, _) => const _P('設定'),
          routes: [
            GoRoute(path: 'account',   builder: (_, _) => const _P('アカウント設定')),
            GoRoute(path: 'household', builder: (_, _) => const _P('世帯設定')),
            GoRoute(
              path: 'housework',
              builder: (_, _) => const _P('家事設定一覧'),
              routes: [
                GoRoute(path: 'new', builder: (_, _) => const _P('家事新規作成')),
                GoRoute(
                  path: ':id',
                  builder: (_, s) => _P('家事編集 ${s.pathParameters['id']}'),
                ),
              ],
            ),
            GoRoute(
              path: 'inquiries',
              builder: (_, _) => const _P('問い合わせ一覧'),
              routes: [
                GoRoute(path: 'new', builder: (_, _) => const _P('問い合わせ新規作成')),
                GoRoute(
                  path: ':id',
                  builder: (_, s) => _P('問い合わせ詳細 ${s.pathParameters['id']}'),
                ),
              ],
            ),
            GoRoute(path: 'app-info', builder: (_, _) => const _P('アプリ情報')),
            GoRoute(path: 'terms',    builder: (_, _) => const _P('利用規約')),
            GoRoute(path: 'privacy',  builder: (_, _) => const _P('プライバシーポリシー')),
          ],
        ),
      ]),
    ],
  ),

  // ─── 認証済み（シェル外・全画面）────────────────────────
  GoRoute(path: '/notifications', builder: (_, _) => const _P('通知センター')),
];

// Phase 3で実装するまでの仮画面
class _P extends StatelessWidget {
  const _P(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name.split('\n').first)),
      body: Center(
        child: Text(name, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
      ),
    );
  }
}
