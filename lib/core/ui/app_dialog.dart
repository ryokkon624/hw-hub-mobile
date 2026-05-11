import 'package:flutter/material.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppDialog {
  AppDialog._();

  /// 確認ダイアログ。OKで true、キャンセルで false を返す。
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String cancelLabel = 'キャンセル',
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }

  /// エラー・通知ダイアログ。OKのみ。
  static Future<void> alert(
    BuildContext context, {
    required String title,
    required String message,
    String okLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) =>
          _AppAlertDialog(title: title, message: message, okLabel: okLabel),
    );
  }
}

class _AppConfirmDialog extends StatelessWidget {
  const _AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDanger,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final confirmColor = isDanger ? colors.danger : colors.primary;

    return AlertDialog(
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: colors.textHeading),
      ),
      content: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.textBody),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel, style: TextStyle(color: colors.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: confirmColor, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _AppAlertDialog extends StatelessWidget {
  const _AppAlertDialog({
    required this.title,
    required this.message,
    required this.okLabel,
  });

  final String title;
  final String message;
  final String okLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return AlertDialog(
      backgroundColor: colors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: colors.textHeading),
      ),
      content: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.textBody),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            okLabel,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
