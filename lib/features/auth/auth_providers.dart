import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/network/s3_url_resolver.dart';
import 'data/auth_api.dart';
import 'data/auth_repository.dart';
import 'presentation/email_verify_wait/email_verify_wait_notifier.dart';
import 'presentation/email_verify_wait/email_verify_wait_state.dart';
import 'presentation/invitation/invitation_notifier.dart';
import 'presentation/invitation/invitation_state.dart';
import 'presentation/login/login_notifier.dart';
import 'presentation/login/login_state.dart';
import 'presentation/password_forgot/password_forgot_notifier.dart';
import 'presentation/password_forgot/password_forgot_state.dart';
import 'presentation/password_reset/password_reset_notifier.dart';
import 'presentation/password_reset/password_reset_state.dart';
import 'presentation/password_reset_sent/password_reset_sent_notifier.dart';
import 'presentation/password_reset_sent/password_reset_sent_state.dart';
import 'presentation/signup/signup_notifier.dart';
import 'presentation/signup/signup_state.dart';

export 'presentation/email_verify/email_verify_notifier.dart';
export 'presentation/email_verify_wait/email_verify_wait_notifier.dart';
export 'presentation/email_verify_wait/email_verify_wait_state.dart';
export 'presentation/invitation/invitation_notifier.dart';
export 'presentation/invitation/invitation_state.dart';
export 'presentation/login/login_notifier.dart';
export 'presentation/login/login_state.dart';
export 'presentation/password_forgot/password_forgot_notifier.dart';
export 'presentation/password_forgot/password_forgot_state.dart';
export 'presentation/password_reset/password_reset_notifier.dart';
export 'presentation/password_reset/password_reset_state.dart';
export 'presentation/password_reset_sent/password_reset_sent_notifier.dart';
export 'presentation/password_reset_sent/password_reset_sent_state.dart';
export 'presentation/signup/signup_notifier.dart';
export 'presentation/signup/signup_state.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(authApiProvider),
    s3UrlResolver: S3UrlResolver(isDebug: kDebugMode),
  );
});

final loginNotifierProvider =
    NotifierProvider.autoDispose<LoginNotifier, LoginState>(LoginNotifier.new);

final signupNotifierProvider = NotifierProvider<SignupNotifier, SignupState>(
  SignupNotifier.new,
);

final passwordForgotNotifierProvider =
    NotifierProvider<PasswordForgotNotifier, PasswordForgotState>(
      PasswordForgotNotifier.new,
    );

final passwordResetNotifierProvider =
    NotifierProvider<PasswordResetNotifier, PasswordResetState>(
      PasswordResetNotifier.new,
    );

final passwordResetSentNotifierProvider = NotifierProvider.autoDispose
    .family<PasswordResetSentNotifier, PasswordResetSentState, String>(
      PasswordResetSentNotifier.new,
    );

final invitationNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<InvitationNotifier, InvitationState, String>(
      InvitationNotifier.new,
    );

final emailVerifyWaitNotifierProvider = NotifierProvider.autoDispose
    .family<EmailVerifyWaitNotifier, EmailVerifyWaitState, String>(
      EmailVerifyWaitNotifier.new,
    );

// emailVerifyResultProvider is a FutureProvider defined in email_verify_notifier.dart
// and re-exported via the export above.
