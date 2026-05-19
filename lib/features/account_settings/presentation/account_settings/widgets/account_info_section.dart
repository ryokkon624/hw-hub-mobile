import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/user_profile_dto.dart';

/// AC1: アカウント情報（メール・表示名の読み取り専用表示）
class AccountInfoSection extends StatelessWidget {
  const AccountInfoSection({super.key, required this.profile});

  final UserProfileDto profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return _SectionCard(
      title: l10n.accountSettingsAccountInfoSection,
      colors: colors,
      child: Column(
        children: [
          _InfoRow(
            label: l10n.accountSettingsEmail,
            value: profile.email,
            colors: colors,
          ),
          Divider(color: colors.border, height: 1),
          _InfoRow(
            label: l10n.accountSettingsDisplayName,
            value: profile.displayName,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: colors.textBody),
            ),
          ),
        ],
      ),
    );
  }
}

/// セクション共通ラッパー
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.colors,
    required this.child,
  });

  final String title;
  final AppColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
          child: child,
        ),
      ],
    );
  }
}
