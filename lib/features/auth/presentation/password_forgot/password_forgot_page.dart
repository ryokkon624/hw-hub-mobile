import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import 'password_forgot_notifier.dart';

class PasswordForgotPage extends ConsumerStatefulWidget {
  const PasswordForgotPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<PasswordForgotPage> createState() =>
      _PasswordForgotPageState();
}

class _PasswordForgotPageState extends ConsumerState<PasswordForgotPage> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.initialEmail ?? '');
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(passwordForgotNotifierProvider.notifier)
            .setEmail(widget.initialEmail!);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(passwordForgotNotifierProvider);
    final notifier = ref.read(passwordForgotNotifierProvider.notifier);

    ref.listen(passwordForgotNotifierProvider, (_, next) {
      if (next.sentEmail != null) {
        context.go(
            '/forgot-password/sent?email=${Uri.encodeComponent(next.sentEmail!)}');
      }
    });

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
              Text(l10n.passwordForgotTitle,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(l10n.passwordForgotDescription),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.passwordForgotEmail,
                  hintText: l10n.passwordForgotEmailPlaceholder,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onChanged: notifier.setEmail,
                onSubmitted: (_) {
                  if (state.canSubmit) notifier.submit();
                },
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: state.canSubmit ? notifier.submit : null,
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.passwordForgotSubmit),
              ),
              const SizedBox(height: 16),
              const Divider(),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(l10n.passwordForgotBackToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
