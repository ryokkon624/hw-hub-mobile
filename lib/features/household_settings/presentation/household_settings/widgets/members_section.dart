import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/household_member_status.dart';
import '../../../../../core/ui/user_avatar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/household_member_dto.dart';
import '../household_settings_notifier.dart';

/// メンバー一覧セクション（AC5・AC6・AC7）。
class MembersSection extends ConsumerWidget {
  const MembersSection({super.key, required this.loginUserId});

  final int loginUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifierState = ref.watch(householdSettingsNotifierProvider);

    return notifierState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        // isCurrentUserOwner は Notifier 側で事前計算済み（O(1)参照）
        return Card(
          key: const Key('membersSection'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.householdSettingsMembersSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...state.members.map(
                  (m) => _MemberCard(
                    key: ValueKey('member_${m.userId}'),
                    member: m,
                    loginUserId: loginUserId,
                    isCurrentUserOwner: state.isCurrentUserOwner,
                    onRemove: () => _confirmRemove(context, ref, l10n, m),
                    onTransferOwner: () =>
                        _confirmTransfer(context, ref, l10n, m),
                    onLeave: () => _confirmLeave(context, ref, l10n),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    HouseholdSettingsMemberDto member,
  ) {
    final name = member.nickname ?? member.displayName;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdSettingsRemoveMemberConfirmTitle),
        content: Text(l10n.householdSettingsRemoveMemberConfirmBody(name)),
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
                  .removeMember(userId: member.userId);
            },
            child: Text(l10n.householdSettingsRemoveMemberButton),
          ),
        ],
      ),
    );
  }

  void _confirmTransfer(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    HouseholdSettingsMemberDto member,
  ) {
    final name = member.nickname ?? member.displayName;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdSettingsTransferOwnerConfirmTitle),
        content: Text(l10n.householdSettingsTransferOwnerConfirmBody(name)),
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
                  .transferOwner(newOwnerUserId: member.userId);
            },
            child: Text(l10n.householdSettingsTransferOwnerButton),
          ),
        ],
      ),
    );
  }

  void _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.householdSettingsLeaveConfirmTitle),
        content: Text(l10n.householdSettingsLeaveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // 離脱後は世帯切り替え（householdNotifier.refresh() はPage側でhandleする）
              await ref
                  .read(householdSettingsNotifierProvider.notifier)
                  .leaveHousehold();
            },
            child: Text(l10n.householdSettingsLeaveButton),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    super.key,
    required this.member,
    required this.loginUserId,
    required this.isCurrentUserOwner,
    required this.onRemove,
    required this.onTransferOwner,
    required this.onLeave,
  });

  final HouseholdSettingsMemberDto member;
  final int loginUserId;
  final bool isCurrentUserOwner;
  final VoidCallback onRemove;
  final VoidCallback onTransferOwner;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isMe = member.userId == loginUserId;
    final isActive =
        HouseholdMemberStatus.fromCode(member.status) ==
        HouseholdMemberStatus.active;

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: UserAvatar(
            iconUrl: member.iconUrl,
            label: member.nickname ?? member.displayName,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  member.nickname ?? member.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Chip(
                  label: Text(
                    l10n.householdSettingsMemberBadgeYou,
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              _StatusBadge(status: member.status),
              if (member.role == 'OWNER') ...[
                const SizedBox(width: 4),
                _RoleBadge(role: member.role),
              ],
            ],
          ),
        ),
        // OWNERが他のACTIVEメンバーに対して表示するボタン
        if (isCurrentUserOwner && !isMe && isActive) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ValueKey('removeButton_${member.userId}'),
                  onPressed: onRemove,
                  child: Text(l10n.householdSettingsRemoveMemberButton),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: ValueKey('transferOwnerButton_${member.userId}'),
                  onPressed: onTransferOwner,
                  child: Text(l10n.householdSettingsTransferOwnerButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        // 非OWNERが自分のカードで表示する離脱ボタン
        if (!isCurrentUserOwner && isMe) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('leaveButton'),
              onPressed: onLeave,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: Text(l10n.householdSettingsLeaveButton),
            ),
          ),
          const SizedBox(height: 4),
        ],
        const Divider(height: 1),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final memberStatus = HouseholdMemberStatus.fromCode(status);

    String label;
    Color color;
    switch (memberStatus) {
      case HouseholdMemberStatus.active:
        label = l10n.householdSettingsMemberStatusActive;
        color = Colors.green;
      case HouseholdMemberStatus.invited:
        label = l10n.householdSettingsMemberStatusInvited;
        color = Colors.amber;
      case HouseholdMemberStatus.left:
        label = l10n.householdSettingsMemberStatusLeft;
        color = Colors.grey;
      case null:
        label = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
      ),
      child: Text(
        l10n.householdSettingsMemberStatusOwner,
        style: TextStyle(
          fontSize: 11,
          color: Colors.blue.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

extension on Color {
  Color get shade700 => HSLColor.fromColor(this).withLightness(0.35).toColor();
}
