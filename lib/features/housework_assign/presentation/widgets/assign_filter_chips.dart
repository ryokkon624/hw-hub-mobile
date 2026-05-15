import 'package:flutter/material.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import '../housework_assign_state.dart';

class AssignFilterChips extends StatelessWidget {
  const AssignFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AssignFilter selected;
  final ValueChanged<AssignFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _Chip(
            label: l10n.houseworkAssignFilterAll,
            selected: selected == AssignFilter.all,
            onTap: () => onChanged(AssignFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: l10n.houseworkAssignFilterUnassigned,
            selected: selected == AssignFilter.unassignedOnly,
            onTap: () => onChanged(AssignFilter.unassignedOnly),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: l10n.houseworkAssignFilterMeAndUnassigned,
            selected: selected == AssignFilter.meAndUnassigned,
            onTap: () => onChanged(AssignFilter.meAndUnassigned),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
