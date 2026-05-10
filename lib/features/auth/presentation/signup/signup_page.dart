import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import 'signup_notifier.dart';

class SignupPage extends ConsumerWidget {
  const SignupPage({super.key, this.invitationToken});

  final String? invitationToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(signupNotifierProvider);
    final notifier = ref.read(signupNotifierProvider.notifier);

    ref.listen(signupNotifierProvider, (_, next) {
      final result = next.successResult;
      if (result == null) return;
      if (result.requiresEmailVerify) {
        context.go('/email-waiting?email=${Uri.encodeComponent(result.email)}');
      } else {
        context.go('/');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                l10n.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.signupTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l10n.signupGoLogin),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.signupEmail,
                  hintText: l10n.signupEmailPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setEmail,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.signupDisplayName,
                  hintText: l10n.signupDisplayNamePlaceholder,
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: notifier.setDisplayName,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.signupPassword,
                  helperText: l10n.signupPasswordHint,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.next,
                onChanged: notifier.setPassword,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.signupPasswordConfirm,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onChanged: notifier.setPasswordConfirm,
                onSubmitted: (_) {
                  if (state.canSubmit) {
                    notifier.submit(invitationToken: invitationToken);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.signupLocale,
                  border: const OutlineInputBorder(),
                ),
                initialValue: state.locale,
                items: [
                  DropdownMenuItem(
                      value: 'ja', child: Text(l10n.commonLocaleJa)),
                  DropdownMenuItem(
                      value: 'en', child: Text(l10n.commonLocaleEn)),
                  DropdownMenuItem(
                      value: 'es', child: Text(l10n.commonLocaleEs)),
                ],
                onChanged: (v) {
                  if (v != null) notifier.setLocale(v);
                },
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.canSubmit
                    ? () => notifier.submit(invitationToken: invitationToken)
                    : null,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.signupSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
