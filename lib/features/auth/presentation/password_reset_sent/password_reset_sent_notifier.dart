import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'password_reset_sent_state.dart';

final passwordResetSentNotifierProvider = NotifierProvider.autoDispose
    .family<PasswordResetSentNotifier, PasswordResetSentState, String>(
        PasswordResetSentNotifier.new);

class PasswordResetSentNotifier
    extends AutoDisposeFamilyNotifier<PasswordResetSentState, String> {
  @override
  PasswordResetSentState build(String email) =>
      const PasswordResetSentState();

  Future<void> resend() async {
    if (state.isSending) return;
    state = state.copyWith(
        isSending: true, errorMessage: null, resentSuccess: false);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: arg);
      state = state.copyWith(isSending: false, resentSuccess: true);
    } on AppException catch (e) {
      state = state.copyWith(isSending: false, errorMessage: e.message);
    }
  }
}
