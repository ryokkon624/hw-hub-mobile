import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/models/invitation_status.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/household_invitation_dto.dart';
import '../household_settings_notifier.dart';

/// メンバー招待セクション（AC8・AC9）。
class InvitationSection extends ConsumerStatefulWidget {
  const InvitationSection({super.key});

  @override
  ConsumerState<InvitationSection> createState() => _InvitationSectionState();
}

class _InvitationSectionState extends ConsumerState<InvitationSection> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _hasEmail => _emailController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifierState = ref.watch(householdSettingsNotifierProvider);

    return notifierState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        final isCreating = state.isCreatingInvite;

        return Card(
          key: const Key('invitationSection'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.householdSettingsInvitationSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: l10n.householdSettingsInviteEmailHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      key: const Key('sendInviteButton'),
                      onPressed: _hasEmail && !isCreating
                          ? () async {
                              final email = _emailController.text.trim();
                              await ref
                                  .read(
                                    householdSettingsNotifierProvider.notifier,
                                  )
                                  .sendInvitation(email: email);
                              _emailController.clear();
                              setState(() {});
                            }
                          : null,
                      child: Text(l10n.householdSettingsInviteButton),
                    ),
                  ],
                ),
                if (state.invitations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.householdSettingsSentInvitations,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.invitations.map(
                    (inv) => _InvitationRow(
                      key: ValueKey('invitation_${inv.invitationToken}'),
                      invitation: inv,
                      onRevoke: () => _confirmRevoke(context, ref, l10n, inv),
                      onShare: () => _shareLink(inv.invitationToken),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRevoke(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    HouseholdInvitationDto inv,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdSettingsRevokeConfirmTitle),
        content: Text(
          l10n.householdSettingsRevokeConfirmBody(inv.invitedEmail),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref
                  .read(householdSettingsNotifierProvider.notifier)
                  .revokeInvitation(token: inv.invitationToken);
            },
            child: Text(l10n.householdSettingsRevokeInvitationButton),
          ),
        ],
      ),
    );
  }

  void _shareLink(String token) {
    final url = 'https://hwhub.familyapp-hwhub.com/invite/$token';
    Share.share(url);
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow({
    super.key,
    required this.invitation,
    required this.onRevoke,
    required this.onShare,
  });

  final HouseholdInvitationDto invitation;
  final VoidCallback onRevoke;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = InvitationStatus.fromCode(invitation.status);
    final isPending = status == InvitationStatus.pending;

    String statusLabel;
    Color statusColor;
    switch (status) {
      case InvitationStatus.pending:
        statusLabel = l10n.householdSettingsInvitationStatusPending;
        statusColor = Colors.amber;
      case InvitationStatus.accepted:
        statusLabel = l10n.householdSettingsInvitationStatusAccepted;
        statusColor = Colors.green;
      case InvitationStatus.declined:
        statusLabel = l10n.householdSettingsInvitationStatusDeclined;
        statusColor = Colors.orange;
      case InvitationStatus.revoked:
        statusLabel = l10n.householdSettingsInvitationStatusRevoked;
        statusColor = Colors.grey;
      case InvitationStatus.expired:
        statusLabel = l10n.householdSettingsInvitationStatusExpired;
        statusColor = Colors.grey;
      case null:
        statusLabel = invitation.status;
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.invitedEmail,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (invitation.expiresAt != null) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.householdSettingsInviteExpiresAt(
                            invitation.expiresAt!.substring(0, 10),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isPending) ...[
            IconButton(
              key: ValueKey('shareButton_${invitation.invitationToken}'),
              onPressed: onShare,
              icon: const Icon(Icons.share, size: 20),
              tooltip: l10n.householdSettingsCopyLinkButton,
            ),
            IconButton(
              key: ValueKey('revokeButton_${invitation.invitationToken}'),
              onPressed: onRevoke,
              icon: const Icon(Icons.close, size: 20),
              tooltip: l10n.householdSettingsRevokeInvitationButton,
            ),
          ],
        ],
      ),
    );
  }
}
