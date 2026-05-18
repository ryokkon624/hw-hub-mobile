import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_scheme.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountSettingsDeleteAccountConfirmTitle),
        content: Text(l10n.accountSettingsDeleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.accountSettingsDeleteAccountCancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.accountSettingsDeleteAccountConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
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
