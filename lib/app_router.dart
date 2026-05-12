import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_state.dart';
import 'core/di/providers.dart';
import 'features/auth/presentation/auth_result/auth_result_page.dart';
import 'features/auth/presentation/email_verify/email_verify_page.dart';
import 'features/auth/presentation/email_verify_wait/email_verify_wait_page.dart';
import 'features/auth/presentation/invitation/invitation_page.dart';
import 'features/auth/presentation/login/login_page.dart';
import 'features/auth/presentation/password_forgot/password_forgot_page.dart';
import 'features/auth/presentation/password_reset/password_reset_page.dart';
import 'features/auth/presentation/password_reset_sent/password_reset_sent_page.dart';
import 'features/auth/presentation/signup/signup_page.dart';
import 'features/home/presentation/home_page.dart';
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
  GoRoute(
    path: '/login',
    builder: (_, state) =>
        LoginPage(notice: state.uri.queryParameters['notice']),
  ),
  GoRoute(
    path: '/signup',
    builder: (_, state) => SignupPage(
      invitationToken: state.uri.queryParameters['invitationToken'],
    ),
  ),
  GoRoute(
    path: '/email-waiting',
    builder: (_, state) =>
        EmailVerifyWaitPage(email: state.uri.queryParameters['email'] ?? ''),
  ),
  GoRoute(
    path: '/forgot-password',
    builder: (_, state) =>
        PasswordForgotPage(initialEmail: state.uri.queryParameters['email']),
    routes: [
      GoRoute(
        path: 'sent',
        builder: (_, state) => PasswordResetSentPage(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/auth-result',
    builder: (_, state) => AuthResultPage(
      type: state.uri.queryParameters['type'] ?? '',
      status: state.uri.queryParameters['status'] ?? 'invalid',
    ),
  ),

  // ─── ディープリンク（認証状態問わず受け取る）──────────────
  GoRoute(
    path: '/email-verify',
    builder: (_, state) =>
        EmailVerifyPage(token: state.uri.queryParameters['token'] ?? ''),
  ),
  GoRoute(
    path: '/invite/:token',
    builder: (_, state) =>
        InvitationPage(token: state.pathParameters['token'] ?? ''),
  ),
  GoRoute(
    path: '/password/reset',
    builder: (_, state) =>
        PasswordResetPage(token: state.uri.queryParameters['token'] ?? ''),
  ),

  // ─── 認証済みシェル（ボトムナビ）────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => MainShell(navigationShell: shell),
    branches: [
      // ホーム
      StatefulShellBranch(
        routes: [GoRoute(path: '/', builder: (_, _) => const HomePage())],
      ),
      // 家事分担
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/housework', builder: (_, _) => const _P('家事分担')),
        ],
      ),
      // My Tasks
      StatefulShellBranch(
        routes: [
          GoRoute(path: '/tasks', builder: (_, _) => const _P('My Tasks')),
        ],
      ),
      // 買い物
      StatefulShellBranch(
        routes: [
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
        ],
      ),
      // 設定
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) => const _P('設定'),
            routes: [
              GoRoute(path: 'account', builder: (_, _) => const _P('アカウント設定')),
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
                  GoRoute(
                    path: 'new',
                    builder: (_, _) => const _P('問い合わせ新規作成'),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => _P('問い合わせ詳細 ${s.pathParameters['id']}'),
                  ),
                ],
              ),
              GoRoute(path: 'app-info', builder: (_, _) => const _P('アプリ情報')),
              GoRoute(path: 'terms', builder: (_, _) => const _P('利用規約')),
              GoRoute(
                path: 'privacy',
                builder: (_, _) => const _P('プライバシーポリシー'),
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // ─── 認証済み（シェル外・全画面）────────────────────────
  GoRoute(path: '/notifications', builder: (_, _) => const _P('通知センター')),
];

abstract final class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
  static const emailWaiting = '/email-waiting';
  static const forgotPassword = '/forgot-password';
  static const forgotPasswordSent = '/forgot-password/sent';
  static const authResult = '/auth-result';
  static const emailVerify = '/email-verify';
  static const inviteToken = '/invite/:token';
  static const passwordReset = '/password/reset';

  static const home = '/';
  static const housework = '/housework';
  static const tasks = '/tasks';
  static const shopping = '/shopping';
  static const shoppingNew = '/shopping/new';
  static String shoppingDetail(String id) => '/shopping/$id';
  static const settings = '/settings';
  static const settingsAccount = '/settings/account';
  static const settingsHousehold = '/settings/household';
  static const settingsHousework = '/settings/housework';
  static const settingsHouseworkNew = '/settings/housework/new';
  static String settingsHouseworkDetail(String id) => '/settings/housework/$id';
  static const settingsInquiries = '/settings/inquiries';
  static const settingsInquiriesNew = '/settings/inquiries/new';
  static String settingsInquiryDetail(String id) => '/settings/inquiries/$id';
  static const settingsAppInfo = '/settings/app-info';
  static const settingsTerms = '/settings/terms';
  static const settingsPrivacy = '/settings/privacy';

  static const notifications = '/notifications';

  static String invite(String token) => '/invite/$token';
}

// Phase 4以降で実装するまでの仮画面
class _P extends StatelessWidget {
  const _P(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name.split('\n').first)),
      body: Center(
        child: Text(
          name,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
