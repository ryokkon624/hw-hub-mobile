import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/notification_settings_dto.dart';

/// AC5: 通知設定セクション（即時反映トグル）
class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({
    super.key,
    required this.settings,
    required this.onToggleGlobal,
    required this.onToggleGroup,
  });

  final NotificationSettingsDto settings;
  final Future<void> Function(bool enabled) onToggleGlobal;
  final Future<void> Function(String groupCode, bool enabled) onToggleGroup;

  // グループコード定数
  static const _householdCode = '100';
  static const _taskAssignmentCode = '200';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    final globalEnabled = settings.notificationEnabled;
    final householdEnabled = settings.groupSettings[_householdCode] ?? true;
    final taskEnabled = settings.groupSettings[_taskAssignmentCode] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountSettingsNotificationSection,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // グローバル ON/OFF
              _NotificationToggleRow(
                label: l10n.accountSettingsNotificationGlobal,
                value: globalEnabled,
                colors: colors,
                onChanged: (v) => onToggleGlobal(v),
              ),
              Divider(color: colors.border, height: 1),
              // 世帯関連
              Opacity(
                opacity: globalEnabled ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !globalEnabled,
                  child: _NotificationToggleRow(
                    label: l10n.accountSettingsNotificationHousehold,
                    value: householdEnabled,
                    colors: colors,
                    onChanged: (v) => onToggleGroup(_householdCode, v),
                  ),
                ),
              ),
              Divider(color: colors.border, height: 1),
              // タスク割り当て
              Opacity(
                opacity: globalEnabled ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !globalEnabled,
                  child: _NotificationToggleRow(
                    label: l10n.accountSettingsNotificationTaskAssignment,
                    value: taskEnabled,
                    colors: colors,
                    onChanged: (v) => onToggleGroup(_taskAssignmentCode, v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationToggleRow extends StatelessWidget {
  const _NotificationToggleRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final AppColorScheme colors;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: colors.textBody),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }
}
