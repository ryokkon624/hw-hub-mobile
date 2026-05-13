import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app_router.dart';
import '../../../../core/auth/auth_state.dart';
import '../../../../core/di/providers.dart';
import '../../../../l10n/app_localizations.dart';
import 'invitation_notifier.dart';

class InvitationPage extends ConsumerWidget {
  const InvitationPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invAsync = ref.watch(invitationNotifierProvider(token));
    final authAsync = ref.watch(authNotifierProvider);
    final notifier = ref.read(invitationNotifierProvider(token).notifier);

    ref.listen(invitationNotifierProvider(token), (previous, next) {
      next.whenData((state) {
        if (state.accepted) context.go(AppRoutes.home);
        if (state.declined) context.go(AppRoutes.login);
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      });
    });

    return Scaffold(
      body: SafeArea(
        child: invAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorBody(
            l10n: l10n,
            onRetry: () => ref.invalidate(invitationNotifierProvider(token)),
          ),
          data: (state) {
            final info = state.invitationInfo;
            if (info == null) {
              return _ErrorBody(
                l10n: l10n,
                onRetry: () =>
                    ref.invalidate(invitationNotifierProvider(token)),
              );
            }

            final isAuth = authAsync.valueOrNull is AuthAuthenticated;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.invitePageLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.inviteHeading,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.inviteDescription),
                  const Divider(height: 32),
                  _InfoRow(
                    label: l10n.inviteHouseholdTitle,
                    value: info.householdName,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l10n.inviteInviterLabel,
                    value: info.inviterName,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l10n.inviteInvitedEmailLabel,
                    value: info.invitedEmail,
                  ),
                  const SizedBox(height: 24),
                  if (isAuth) ...[
                    Text(l10n.inviteConfirmMessage(info.householdName)),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: state.isActing ? null : notifier.accept,
                      child: state.isActing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.inviteAccept),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: state.isActing ? null : notifier.decline,
                      child: Text(l10n.inviteDecline),
                    ),
                  ] else ...[
                    Text(l10n.inviteLoginNeededMessage),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'redirect_after_login',
                          AppRoutes.invite(token),
                        );
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                      child: Text(l10n.inviteLoginAndJoin),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'redirect_after_login',
                          AppRoutes.invite(token),
                        );
                        if (context.mounted) {
                          context.go(
                            '${AppRoutes.signup}?invitationToken=$token',
                          );
                        }
                      },
                      child: Text(l10n.inviteSignupAndJoin),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.l10n, required this.onRetry});
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.inviteErrorInvalid),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
