import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/ui/main_app_bar.dart';
import '../../../l10n/app_localizations.dart';

/// プライバシーポリシー画面（#144）。
///
/// 静的コンテンツとして6セクションと注記を表示する。
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: MainAppBar(title: l10n.pageTitlePrivacy),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // イントロダクション
            Text(
              l10n.privacyIntro,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),

            // 1. 収集する情報
            _Section(
              key: const Key('privacySection1'),
              title: l10n.privacySection1Title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletText(l10n.privacySection1AccountInfo),
                  _BulletText(l10n.privacySection1UsageData),
                  _BulletText(l10n.privacySection1LogInfo),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. 情報の利用目的
            _Section(
              key: const Key('privacySection2'),
              title: l10n.privacySection2Title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletText(l10n.privacySection2ServiceProvision),
                  _BulletText(l10n.privacySection2Troubleshooting),
                  _BulletText(l10n.privacySection2Analytics),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. 第三者提供
            _Section(
              key: const Key('privacySection3'),
              title: l10n.privacySection3Title,
              child: Text(
                l10n.privacySection3Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // 4. 情報の安全管理
            _Section(
              key: const Key('privacySection4'),
              title: l10n.privacySection4Title,
              child: Text(
                l10n.privacySection4Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // 5. 情報の保存期間
            _Section(
              key: const Key('privacySection5'),
              title: l10n.privacySection5Title,
              child: Text(
                l10n.privacySection5Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // 6. お問い合わせ
            _Section(
              key: const Key('privacySection6'),
              title: l10n.privacySection6Title,
              child: Text(
                l10n.privacySection6Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // 注記
            Text(
              key: const Key('privacyNote'),
              l10n.privacyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textHeading,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

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
