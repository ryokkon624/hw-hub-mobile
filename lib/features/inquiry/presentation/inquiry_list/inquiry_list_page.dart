import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../core/ui/main_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/inquiry_category_badge.dart';
import '../widgets/inquiry_status_badge.dart';
import 'inquiry_list_notifier.dart';

class InquiryListPage extends ConsumerWidget {
  const InquiryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final state = ref.watch(inquiryListNotifierProvider);

    ref.listen(inquiryListNotifierProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        AppSnackBar.showError(next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: MainAppBar(title: l10n.pageTitleInquiry),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明文
            Text(
              l10n.inquiryListDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 12),
            // 新規作成ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('newInquiryButton'),
                onPressed: () => context.push(AppRoutes.settingsInquiriesNew),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.inquiryListAddButton),
              ),
            ),
            const SizedBox(height: 16),
            // 一覧
            Expanded(child: _buildBody(context, ref, state, l10n, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    InquiryListState state,
    AppLocalizations l10n,
    AppColorScheme colors,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.inquiries.isEmpty) {
      return Center(
        key: const Key('emptyState'),
        child: Text(
          l10n.inquiryListEmpty,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }
    return ListView.separated(
      key: const Key('inquiryList'),
      itemCount: state.inquiries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final inquiry = state.inquiries[index];
        return InkWell(
          key: ValueKey(inquiry.inquiryId),
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(
            AppRoutes.settingsInquiryDetail(inquiry.inquiryId.toString()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                // タイトル
                Text(
                  '#${inquiry.inquiryId}: ${inquiry.title}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textHeading,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                // カテゴリバッジ + ステータスバッジ
                Row(
                  children: [
                    InquiryCategoryBadge(categoryCode: inquiry.category),
                    const Spacer(),
                    InquiryStatusBadge(statusCode: inquiry.status),
                  ],
                ),
                const SizedBox(height: 4),
                // 作成日時
                Text(
                  _formatDateTime(inquiry.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final y = dt.year;
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$y/$mo/$d $h:$mi';
    } catch (_) {
      return isoString;
    }
  }
}
