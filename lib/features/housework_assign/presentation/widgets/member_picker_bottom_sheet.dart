import 'package:flutter/material.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import '../../data/housework_assign_repository.dart';

class MemberPickerBottomSheet extends StatelessWidget {
  const MemberPickerBottomSheet({
    super.key,
    required this.members,
    required this.onSelected,
  });

  final List<HouseholdMemberDto> members;
  final void Function(int? userId, String? nickname) onSelected;

  static Future<void> show(
    BuildContext context, {
    required List<HouseholdMemberDto> members,
    required void Function(int? userId, String? nickname) onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (dialogContext) => MemberPickerBottomSheet(
        members: members,
        onSelected: (userId, nickname) {
          Navigator.pop(dialogContext);
          onSelected(userId, nickname);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.houseworkAssignSwipePickMemberLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // 未割当に戻すオプション
          ListTile(
            title: Text(l10n.houseworkAssignAssigneeUnassigned),
            leading: const Icon(Icons.person_off),
            onTap: () => onSelected(null, null),
          ),
          ...members.map(
            (m) => ListTile(
              key: ValueKey(m.userId),
              title: Text(m.displayName),
              leading: const Icon(Icons.person),
              onTap: () => onSelected(m.userId, m.displayName),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
