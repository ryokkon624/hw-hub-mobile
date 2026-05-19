import 'package:flutter/material.dart';
import '../../../../core/models/inquiry_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../l10n/app_localizations.dart';

class InquiryStatusBadge extends StatelessWidget {
  const InquiryStatusBadge({super.key, required this.statusCode});

  final String statusCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final status = InquiryStatus.fromCode(statusCode);

    final (label, bg, textColor) = _style(status, l10n, colors);

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
    InquiryStatus? status,
    AppLocalizations l10n,
    AppColorScheme colors,
  ) {
    switch (status) {
      case InquiryStatus.open:
        return (
          l10n.inquiryStatusOpen,
          colors.paletteBlueSoft,
          colors.paletteBlueText,
        );
      case InquiryStatus.aiAnswered:
        return (
          l10n.inquiryStatusAiAnswered,
          colors.paletteVioletSoft,
          colors.paletteVioletText,
        );
      case InquiryStatus.pendingStaff:
        return (
          l10n.inquiryStatusPendingStaff,
          colors.paletteAmberSoft,
          colors.paletteAmberText,
        );
      case InquiryStatus.staffAnswered:
        return (
          l10n.inquiryStatusStaffAnswered,
          colors.paletteEmeraldSoft,
          colors.paletteEmeraldText,
        );
      case InquiryStatus.closed:
      case null:
        return (
          l10n.inquiryStatusClosed,
          colors.surfaceSubtle,
          colors.textMuted,
        );
    }
  }
}
