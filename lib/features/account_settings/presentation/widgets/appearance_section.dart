import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/theme_mode_notifier.dart';
import '../../../../l10n/app_localizations.dart';

/// 外観設定セクション（システム連動 / ライト / ダーク の 3 択）。
///
/// - AC1: ProfileSection と IconSection の間に配置
/// - AC2: システム連動・ライト・ダークの 3 択から選択できる
/// - AC3: 選択変更でアプリの外観が即座に切り替わる（MaterialApp.router の themeMode が watch で更新）
/// - AC4: SharedPreferences に永続化（ThemeModeNotifier が管理）
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final themeModeAsync = ref.watch(themeModeNotifierProvider);
    final currentMode = themeModeAsync.valueOrNull ?? ThemeMode.system;

    return Column(
      key: const Key('appearanceSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountSettingsAppearanceSection,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.accountSettingsAppearanceSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.accountSettingsAppearanceLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.accountSettingsAppearanceDark),
              ),
            ],
            selected: {currentMode},
            onSelectionChanged: (Set<ThemeMode> selected) {
              ref
                  .read(themeModeNotifierProvider.notifier)
                  .setThemeMode(selected.first);
            },
            showSelectedIcon: false,
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
