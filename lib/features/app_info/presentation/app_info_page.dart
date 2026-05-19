import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/ui/main_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../app_info_providers.dart';

/// アプリ情報画面（#142）。
///
/// バージョン情報・利用規約リンク・プライバシーポリシーリンク・開発者情報などを表示する。
class AppInfoPage extends ConsumerWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final state = ref.watch(appInfoNotifierProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: MainAppBar(title: l10n.pageTitleAppInfo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appInfoDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),

            // バージョン情報セクション
            _SectionCard(
              key: const Key('appInfoVersionSection'),
              title: l10n.appInfoVersionSectionTitle,
              child: Column(
                children: [
                  _InfoRow(
                    label: l10n.appInfoVersionFrontend,
                    value: state.appVersion ?? l10n.appInfoVersionUnknown,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l10n.appInfoVersionApi,
                    valueWidget: state.isLoadingApi
                        ? Text(
                            key: const Key('apiVersionLoading'),
                            l10n.appInfoVersionLoading,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          )
                        : state.apiVersion != null
                        ? Text(
                            key: const Key('apiVersionValue'),
                            state.apiVersion!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                          )
                        : Text(
                            key: const Key('apiVersionUnknown'),
                            l10n.appInfoVersionUnknown,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 利用規約・プライバシーポリシーセクション
            _SectionCard(
              key: const Key('appInfoLegalSection'),
              title: l10n.appInfoLegalSectionTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appInfoLegalDescription,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _LinkItem(
                    key: const Key('termsLink'),
                    label: l10n.appInfoLegalTermsLinkLabel,
                    onTap: () => context.push(AppRoutes.settingsTerms),
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _LinkItem(
                    key: const Key('privacyLink'),
                    label: l10n.appInfoLegalPrivacyLinkLabel,
                    onTap: () => context.push(AppRoutes.settingsPrivacy),
                    colors: colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // データとプライバシーの概要セクション
            _SectionCard(
              key: const Key('appInfoPrivacyOverviewSection'),
              title: l10n.appInfoPrivacyOverviewSectionTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletText(l10n.appInfoPrivacyOverviewHouseholdVisibility),
                  _BulletText(l10n.appInfoPrivacyOverviewAnalyticsUsage),
                  _BulletText(l10n.appInfoPrivacyOverviewNoSelling),
                  const SizedBox(height: 4),
                  Text(
                    l10n.appInfoPrivacyOverviewNote,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 開発者情報セクション
            _SectionCard(
              key: const Key('appInfoDeveloperSection'),
              title: l10n.appInfoDeveloperSectionTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appInfoDeveloperAppNameLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.appInfoDeveloperOperatorLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        l10n.appInfoDeveloperContactLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.appInfoDeveloperContactEmail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // OSSライセンスセクション
            _SectionCard(
              key: const Key('appInfoOssSection'),
              title: l10n.appInfoOssSectionTitle,
              child: Text(
                l10n.appInfoOssBody,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// セクションカードウィジェット
class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// ラベル・値のペア行
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colors.textHeading,
              ),
            ),
      ],
    );
  }
}

/// 箇条書きテキスト
class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// リンクアイテム（利用規約・プライバシーポリシー）
class _LinkItem extends StatelessWidget {
  const _LinkItem({
    super.key,
    required this.label,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final VoidCallback onTap;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textHeading,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
