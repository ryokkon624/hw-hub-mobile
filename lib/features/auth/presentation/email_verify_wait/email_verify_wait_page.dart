import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'email_verify_wait_notifier.dart';

class EmailVerifyWaitPage extends ConsumerWidget {
  const EmailVerifyWaitPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (email.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go(AppRoutes.signup),
      );
      return const SizedBox.shrink();
    }

    final state = ref.watch(emailVerifyWaitNotifierProvider(email));
    final notifier = ref.read(emailVerifyWaitNotifierProvider(email).notifier);

    ref.listen(emailVerifyWaitNotifierProvider(email), (_, next) {
      if (next.resentSuccess) {
        AppSnackBar.showSuccess(l10n.emailVerifyWaitAlertResent);
      }
      if (next.errorMessage != null) {
        AppSnackBar.showError(next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.signup)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.emailVerifyWaitTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(l10n.emailVerifyWaitSentTo(email)),
              const SizedBox(height: 8),
              Text(l10n.emailVerifyWaitInstruction),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: state.canResend ? notifier.resend : null,
                child: state.isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : state.cooldownSeconds > 0
                    ? Text(
                        l10n.emailVerifyWaitResendCooldown(
                          state.cooldownSeconds,
                        ),
                      )
                    : Text(l10n.emailVerifyWaitResendButton),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                l10n.emailVerifyWaitSpamNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
