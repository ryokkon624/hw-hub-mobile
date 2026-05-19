import 'package:flutter/material.dart';
import '../../../../core/models/inquiry_category.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../l10n/app_localizations.dart';

class InquiryCategoryBadge extends StatelessWidget {
  const InquiryCategoryBadge({super.key, required this.categoryCode});

  final String categoryCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final category = InquiryCategory.fromCode(categoryCode);

    final (label, bg, textColor) = _style(category, l10n, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  (String, Color, Color) _style(
    InquiryCategory? category,
    AppLocalizations l10n,
    AppColorScheme colors,
  ) {
    switch (category) {
      case InquiryCategory.general:
        return (
          l10n.inquiryCategoryGeneral,
          colors.surfaceSubtle,
          colors.textBody,
        );
      case InquiryCategory.housework:
        return (
          l10n.inquiryCategoryHousework,
          colors.paletteAmberSoft,
          colors.paletteAmberText,
        );
      case InquiryCategory.shopping:
        return (
          l10n.inquiryCategoryShopping,
          colors.paletteEmeraldSoft,
          colors.paletteEmeraldText,
        );
      case InquiryCategory.accountSettings:
        return (
          l10n.inquiryCategoryAccount,
          colors.paletteBlueSoft,
          colors.paletteBlueText,
        );
      case InquiryCategory.bugReport:
        return (
          l10n.inquiryCategoryBug,
          colors.paletteRoseSoft,
          colors.paletteRoseText,
        );
      case InquiryCategory.other:
      case null:
        return (
          l10n.inquiryCategoryOther,
          colors.surfaceSubtle,
          colors.textMuted,
        );
    }
  }
}
