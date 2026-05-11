import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'email_verify_notifier.dart';

class EmailVerifyPage extends ConsumerWidget {
  const EmailVerifyPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(emailVerifyResultProvider(token));

    ref.listen(emailVerifyResultProvider(token), (_, next) {
      next.whenData((result) {
        final status = switch (result) {
          EmailVerifyResult.success => 'success',
          EmailVerifyResult.expired => 'expired',
          EmailVerifyResult.invalid => 'invalid',
        };
        context.go('/auth-result?type=emailVerify&status=$status');
      });
    });

    return Scaffold(
      body: Center(
        child: resultAsync.isLoading
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      ),
    );
  }
}
