import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import 'password_reset_notifier.dart';
import 'password_reset_state.dart';

class PasswordResetPage extends ConsumerWidget {
  const PasswordResetPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(passwordResetNotifierProvider);
    final notifier = ref.read(passwordResetNotifierProvider.notifier);

    ref.listen(passwordResetNotifierProvider, (_, next) {
      final result = next.result;
      if (result == null) return;
      final status = switch (result) {
        PasswordResetResult.success => 'success',
        PasswordResetResult.expired => 'expired',
        PasswordResetResult.invalid => 'invalid',
      };
      context.go('/auth-result?type=passwordReset&status=$status');
    });

    if (token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth-result?type=passwordReset&status=invalid');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.passwordResetTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(l10n.passwordResetDescription),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.passwordResetNewPassword,
                  helperText: l10n.passwordResetNewPasswordHint,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setPassword,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.passwordResetConfirmPassword,
                  hintText: l10n.passwordResetConfirmPasswordHint,
                  border: const OutlineInputBorder(),
                  errorText: state.hasMismatch
                      ? l10n.passwordResetErrorMismatch
                      : null,
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onChanged: notifier.setPasswordConfirm,
                onSubmitted: (_) {
                  if (state.canSubmit(token)) {
                    notifier.submit(token: token);
                  }
                },
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.canSubmit(token)
                    ? () => notifier.submit(token: token)
                    : null,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.passwordResetSubmit),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: Text(l10n.passwordResetRequestNew),
                  ),
                  const Text(' · '),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l10n.passwordResetBackToLogin),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
