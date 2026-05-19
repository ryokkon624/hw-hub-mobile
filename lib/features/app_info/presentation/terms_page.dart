import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/ui/main_app_bar.dart';
import '../../../l10n/app_localizations.dart';

/// 利用規約画面（#143）。
///
/// 静的コンテンツとして第1〜6条と注記を表示する。
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: MainAppBar(title: l10n.pageTitleTerms),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // イントロダクション
            Text(
              l10n.termsIntro,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),

            // 第1条（適用）
            _ArticleSection(
              key: const Key('termsArticle1'),
              title: l10n.termsArticle1Title,
              child: Text(
                l10n.termsArticle1Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // 第2条（アカウント）
            _ArticleSection(
              key: const Key('termsArticle2'),
              title: l10n.termsArticle2Title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletText(l10n.termsArticle2AccurateInfo),
                  _BulletText(l10n.termsArticle2AccountResponsibility),
                  _BulletText(l10n.termsArticle2IllegalUseNotice),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 第3条（禁止事項）
            _ArticleSection(
              key: const Key('termsArticle3'),
              title: l10n.termsArticle3Title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletText(l10n.termsArticle3LawAndOrder),
                  _BulletText(l10n.termsArticle3Impersonation),
                  _BulletText(l10n.termsArticle3ServiceDisruption),
                  _BulletText(l10n.termsArticle3ReverseEngineering),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 第4条（サービスの変更・停止）
            _ArticleSection(
              key: const Key('termsArticle4'),
              title: l10n.termsArticle4Title,
              child: Text(
                l10n.termsArticle4Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // 第5条（免責事項）
            _ArticleSection(
              key: const Key('termsArticle5'),
              title: l10n.termsArticle5Title,
              child: Text(
                l10n.termsArticle5Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 12),

            // 第6条（規約の変更）
            _ArticleSection(
              key: const Key('termsArticle6'),
              title: l10n.termsArticle6Title,
              child: Text(
                l10n.termsArticle6Body,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // 注記
            Text(
              key: const Key('termsNote'),
              l10n.termsNote,
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

class _ArticleSection extends StatelessWidget {
  const _ArticleSection({super.key, required this.title, required this.child});

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
