import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';

enum EmailVerifyResult { success, expired, invalid }

final emailVerifyResultProvider =
    FutureProvider.autoDispose.family<EmailVerifyResult, String>((ref, token) async {
  if (token.isEmpty) return EmailVerifyResult.invalid;
  try {
    await ref.read(authRepositoryProvider).verifyEmail(token: token);
    return EmailVerifyResult.success;
  } on ApiException catch (e) {
    if (e.code == 'EMAIL_VERIFY_EXPIRED') return EmailVerifyResult.expired;
    return EmailVerifyResult.invalid;
  } on AppException {
    return EmailVerifyResult.invalid;
  }
});
