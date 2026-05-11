import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';

class AuthResultPage extends StatelessWidget {
  const AuthResultPage({super.key, required this.type, required this.status});

  final String type;
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSuccess = status == 'success';

    final (title, message, buttonLabel, onTap) = switch ((type, status)) {
      ('emailVerify', 'success') => (
        l10n.authResultEmailVerifySuccessTitle,
        l10n.authResultEmailVerifySuccessMessage,
        l10n.authResultToLogin,
        () => context.go('/login?notice=emailVerified'),
      ),
      ('emailVerify', _) => (
        status == 'expired'
            ? l10n.authResultEmailVerifyExpiredTitle
            : l10n.authResultEmailVerifyInvalidTitle,
        status == 'expired'
            ? l10n.authResultEmailVerifyExpiredMessage
            : l10n.authResultEmailVerifyInvalidMessage,
        l10n.authResultToSignup,
        () => context.go('/signup'),
      ),
      ('passwordReset', 'success') => (
        l10n.authResultPasswordResetSuccessTitle,
        l10n.authResultPasswordResetSuccessMessage,
        l10n.authResultToLogin,
        () => context.go('/login?notice=passwordResetSuccess'),
      ),
      ('passwordReset', _) => (
        status == 'expired'
            ? l10n.authResultPasswordResetExpiredTitle
            : l10n.authResultPasswordResetInvalidTitle,
        status == 'expired'
            ? l10n.authResultPasswordResetExpiredMessage
            : l10n.authResultPasswordResetInvalidMessage,
        l10n.authResultRetryPasswordReset,
        () => context.go('/forgot-password'),
      ),
      _ => (
        l10n.errorUnexpected,
        '',
        l10n.authResultToLogin,
        () => context.go('/login'),
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                size: 64,
                color: isSuccess
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: onTap, child: Text(buttonLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
