import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../core/ui/app_dialog.dart';
import '../../../../../l10n/app_localizations.dart';

/// AC7: 危険ゾーンセクション（アカウント削除）
class DangerZoneSection extends StatelessWidget {
  const DangerZoneSection({
    super.key,
    required this.isDeleting,
    required this.onDelete,
  });

  final bool isDeleting;
  final Future<void> Function() onDelete;

  Future<void> _confirmAndDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.accountSettingsDeleteAccountConfirmTitle,
      message: l10n.accountSettingsDeleteAccountConfirmBody,
      confirmLabel: l10n.accountSettingsDeleteAccountConfirmButton,
      cancelLabel: l10n.accountSettingsDeleteAccountCancelButton,
      isDanger: true,
    );
    if (confirmed) {
      await onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.dangerSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.dangerBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountSettingsDangerZoneSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              key: const Key('deleteAccountButton'),
              onPressed: isDeleting
                  ? null
                  : () => _confirmAndDelete(context, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.dangerBtn,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.accountSettingsDeleteAccountButton),
            ),
          ),
        ],
      ),
    );
  }
}
