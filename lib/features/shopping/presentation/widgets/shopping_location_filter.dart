import 'package:flutter/material.dart';
import '../../../../core/models/purchase_location_type.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

class ShoppingLocationFilter extends StatelessWidget {
  const ShoppingLocationFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.shoppingFilterAll,
            isSelected: selectedFilter == null,
            onTap: () => onFilterChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: l10n.shoppingFilterSupermarket,
            isSelected: selectedFilter == PurchaseLocationType.supermarket.code,
            color: _storeColor(context, PurchaseLocationType.supermarket),
            onTap: () => onFilterChanged(PurchaseLocationType.supermarket.code),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: l10n.shoppingFilterDrugstore,
            isSelected: selectedFilter == PurchaseLocationType.drugstore.code,
            color: _storeColor(context, PurchaseLocationType.drugstore),
            onTap: () => onFilterChanged(PurchaseLocationType.drugstore.code),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: l10n.shoppingFilterOnline,
            isSelected: selectedFilter == PurchaseLocationType.online.code,
            color: _storeColor(context, PurchaseLocationType.online),
            onTap: () => onFilterChanged(PurchaseLocationType.online.code),
          ),
        ],
      ),
    );
  }

  Color _storeColor(BuildContext context, PurchaseLocationType type) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    switch (type) {
      case PurchaseLocationType.supermarket:
        return colors.storeSuper;
      case PurchaseLocationType.drugstore:
        return colors.storeDrug;
      case PurchaseLocationType.online:
        return colors.storeOnline;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final activeColor = color ?? colors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(color: isSelected ? activeColor : colors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? activeColor : colors.textMuted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
