import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app_router.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth_providers.dart';

class PasswordResetSentPage extends ConsumerWidget {
  const PasswordResetSentPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(passwordResetSentNotifierProvider(email));
    final notifier = ref.read(
      passwordResetSentNotifierProvider(email).notifier,
    );

    ref.listen(passwordResetSentNotifierProvider(email), (_, next) {
      if (next.resentSuccess) {
        AppSnackBar.showSuccess(l10n.passwordResetSentResendSuccess);
      }
      if (next.errorMessage != null) {
        AppSnackBar.showError(next.errorMessage!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.forgotPassword),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.passwordResetSentTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(l10n.passwordResetSentDescription),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('($email)', style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.passwordResetSentCheckSpam,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('• ${l10n.passwordResetSentSpamFolder}'),
                      Text('• ${l10n.passwordResetSentCheckSettings}'),
                      Text('• ${l10n.passwordResetSentWaitAndRetry}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.isSending ? null : notifier.resend,
                child: state.isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.passwordResetSentResend),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.forgotPassword),
                child: Text(l10n.passwordResetSentUseDifferentEmail),
              ),
              const SizedBox(height: 16),
              const Divider(),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(l10n.passwordResetSentBackToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
