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
import 'features/account_settings/presentation/account_settings/account_settings_page.dart';
import 'features/settings/presentation/settings_top/settings_top_page.dart';
import 'features/shell/main_shell.dart';
import 'features/shopping/presentation/shopping_item_detail/shopping_item_detail_page.dart';
import 'features/shopping/presentation/shopping_item_new/shopping_item_new_page.dart';
import 'features/shopping/presentation/shopping_list_page.dart';
import 'features/housework_assign/presentation/housework_assign_page.dart';
import 'features/notifications/presentation/notification_center/notification_center_page.dart';
import 'features/tasks/presentation/my_tasks_page.dart';
import 'features/household_settings/presentation/household_settings/household_settings_page.dart';
import 'features/housework_settings/presentation/housework_list/housework_list_page.dart';
import 'features/housework_settings/presentation/housework_create/housework_create_page.dart';
import 'features/housework_settings/presentation/housework_edit/housework_edit_page.dart';
import 'features/inquiry/presentation/inquiry_list/inquiry_list_page.dart';
import 'features/inquiry/presentation/inquiry_create/inquiry_create_page.dart';
import 'features/inquiry/presentation/inquiry_detail/inquiry_detail_page.dart';
import 'features/app_info/presentation/app_info_page.dart';
import 'features/app_info/presentation/terms_page.dart';
import 'features/app_info/presentation/privacy_policy_page.dart';

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
    path: AppRoutes.login,
    builder: (_, state) =>
        LoginPage(notice: state.uri.queryParameters['notice']),
  ),
  GoRoute(
    path: AppRoutes.signup,
    builder: (_, state) => SignupPage(
      invitationToken: state.uri.queryParameters['invitationToken'],
    ),
  ),
  GoRoute(
    path: AppRoutes.emailWaiting,
    builder: (_, state) =>
        EmailVerifyWaitPage(email: state.uri.queryParameters['email'] ?? ''),
  ),
  GoRoute(
    path: AppRoutes.forgotPassword,
    builder: (_, state) =>
        PasswordForgotPage(initialEmail: state.uri.queryParameters['email']),
    routes: [
      GoRoute(
        path: AppRoutes._forgotPasswordSentRelative,
        builder: (_, state) => PasswordResetSentPage(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.authResult,
    builder: (_, state) => AuthResultPage(
      type: state.uri.queryParameters['type'] ?? '',
      status: state.uri.queryParameters['status'] ?? 'invalid',
    ),
  ),

  // ─── ディープリンク（認証状態問わず受け取る）──────────────
  GoRoute(
    path: AppRoutes.emailVerify,
    builder: (_, state) =>
        EmailVerifyPage(token: state.uri.queryParameters['token'] ?? ''),
  ),
  GoRoute(
    path: AppRoutes.inviteToken,
    builder: (_, state) =>
        InvitationPage(token: state.pathParameters['token'] ?? ''),
  ),
  GoRoute(
    path: AppRoutes.passwordReset,
    builder: (_, state) =>
        PasswordResetPage(token: state.uri.queryParameters['token'] ?? ''),
  ),

  // ─── 認証済みシェル（ボトムナビ）────────────────────────
  StatefulShellRoute.indexedStack(
    builder: (_, _, shell) => MainShell(navigationShell: shell),
    branches: [
      // ホーム
      StatefulShellBranch(
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
        ],
      ),
      // 家事分担
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.housework,
            builder: (_, _) => const HouseworkAssignPage(),
          ),
        ],
      ),
      // My Tasks
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.tasks,
            builder: (_, _) => const MyTasksPage(),
          ),
        ],
      ),
      // 買い物
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.shopping,
            builder: (_, _) => const ShoppingListPage(),
            routes: [
              GoRoute(
                path: AppRoutes._shoppingNewRelative,
                builder: (_, _) => const ShoppingItemNewPage(),
              ),
              GoRoute(
                path: AppRoutes._shoppingDetailRelative,
                builder: (_, s) => ShoppingItemDetailPage(
                  itemId: int.parse(s.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
      ),
      // 設定
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsTopPage(),
            routes: [
              GoRoute(
                path: AppRoutes._settingsAccountRelative,
                builder: (_, _) => const AccountSettingsPage(),
              ),
              GoRoute(
                path: AppRoutes._settingsHouseholdRelative,
                builder: (_, _) => const HouseholdSettingsPage(),
              ),
              GoRoute(
                path: AppRoutes._settingsHouseworkRelative,
                builder: (_, _) => const HouseworkListPage(),
                routes: [
                  GoRoute(
                    path: AppRoutes._settingsHouseworkNewRelative,
                    builder: (_, _) => const HouseworkCreatePage(),
                  ),
                  GoRoute(
                    path: AppRoutes._settingsHouseworkDetailRelative,
                    builder: (_, s) => HouseworkEditPage(
                      houseworkId: int.parse(s.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes._settingsInquiriesRelative,
                builder: (_, _) => const InquiryListPage(),
                routes: [
                  GoRoute(
                    path: AppRoutes._settingsInquiriesNewRelative,
                    builder: (_, _) => const InquiryCreatePage(),
                  ),
                  GoRoute(
                    path: AppRoutes._settingsInquiryDetailRelative,
                    builder: (_, s) => InquiryDetailPage(
                      inquiryId: int.parse(s.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes._settingsAppInfoRelative,
                builder: (_, _) => const AppInfoPage(),
              ),
              GoRoute(
                path: AppRoutes._settingsTermsRelative,
                builder: (_, _) => const TermsPage(),
              ),
              GoRoute(
                path: AppRoutes._settingsPrivacyRelative,
                builder: (_, _) => const PrivacyPolicyPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  ),

  // ─── 認証済み（シェル外・全画面）────────────────────────
  GoRoute(
    path: AppRoutes.notifications,
    builder: (_, _) => const NotificationCenterPage(),
  ),
];

abstract final class AppRoutes {
  // ─── 絶対パス（context.go / context.push 用）────────────
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

  // ─── 相対パス（GoRoute(path: ...) のサブルート用）──────
  static const _forgotPasswordSentRelative = 'sent';
  static const _shoppingNewRelative = 'new';
  static const _shoppingDetailRelative = ':id';
  static const _settingsAccountRelative = 'account';
  static const _settingsHouseholdRelative = 'household';
  static const _settingsHouseworkRelative = 'housework';
  static const _settingsHouseworkNewRelative = 'new';
  static const _settingsHouseworkDetailRelative = ':id';
  static const _settingsInquiriesRelative = 'inquiries';
  static const _settingsInquiriesNewRelative = 'new';
  static const _settingsInquiryDetailRelative = ':id';
  static const _settingsAppInfoRelative = 'app-info';
  static const _settingsTermsRelative = 'terms';
  static const _settingsPrivacyRelative = 'privacy';
}
