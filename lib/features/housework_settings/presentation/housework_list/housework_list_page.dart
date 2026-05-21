import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'housework_list_notifier.dart';
import 'housework_list_state.dart';
import 'widgets/housework_card.dart';

/// 家事設定一覧画面（#20）。
class HouseworkListPage extends ConsumerWidget {
  const HouseworkListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    ref.listen(houseworkListNotifierProvider, (_, next) {
      if (!next.hasValue) return;
      final val = next.value!;
      if (val.errorMessage != null) {
        AppSnackBar.showError(val.errorMessage!);
      }
    });

    return Scaffold(
      key: const Key('houseworkListPage'),
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        title: Text(
          l10n.houseworkSettingsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ref
          .watch(houseworkListNotifierProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => RefreshIndicator(
              onRefresh: () =>
                  ref.read(houseworkListNotifierProvider.notifier).reload(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [Center(child: Text(e.toString()))],
              ),
            ),
            data: (state) => _HouseworkListBody(state: state),
          ),
    );
  }
}

class _HouseworkListBody extends ConsumerWidget {
  const _HouseworkListBody({required this.state});

  final HouseworkListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final notifier = ref.read(houseworkListNotifierProvider.notifier);

    final categories = [
      (null, l10n.houseworkSettingsFilterAll),
      ('CLEAN', l10n.houseworkSettingsFilterClean),
      ('KITCHEN', l10n.houseworkSettingsFilterKitchen),
      ('GARDEN', l10n.houseworkSettingsFilterGarden),
      ('GARBAGE', l10n.houseworkSettingsFilterGarbage),
      ('PET', l10n.houseworkSettingsFilterPet),
      ('OTHER', l10n.houseworkSettingsFilterOther),
    ];

    return RefreshIndicator(
      onRefresh: () => notifier.reload(),
      child: Column(
        children: [
          // 家事を追加するボタン
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const Key('houseworkAddButton'),
                onPressed: () => context.push(AppRoutes.settingsHouseworkNew),
                icon: const Icon(Icons.add),
                label: Text(l10n.houseworkSettingsAddButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // 家事マスタ一覧カード
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリフィルタ + 件数
                  Row(
                    children: [
                      DropdownButton<String?>(
                        key: const Key('categoryFilterDropdown'),
                        value: state.selectedCategory,
                        isDense: true,
                        underline: const SizedBox(),
                        items: categories.map((pair) {
                          return DropdownMenuItem<String?>(
                            value: pair.$1,
                            child: Text(pair.$2),
                          );
                        }).toList(),
                        onChanged: (val) => notifier.filterByCategory(val),
                      ),
                      const Spacer(),
                      Text(
                        l10n.houseworkSettingsTotalCount(
                          state.filteredHouseworks.length,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // 家事リスト
                  Expanded(
                    child: state.filteredHouseworks.isEmpty
                        ? Center(
                            child: Text(
                              l10n.commonLoading,
                              style: TextStyle(color: colors.textMuted),
                            ),
                          )
                        : ListView(
                            children: [
                              ...state.pagedHouseworks.map((hw) {
                                return Padding(
                                  key: ValueKey(hw.houseworkId),
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: HouseworkCard(
                                    housework: hw,
                                    assigneeName: state.memberNameById(
                                      hw.defaultAssigneeUserId,
                                    ),
                                    onTap: () => context.push(
                                      AppRoutes.settingsHouseworkDetail(
                                        hw.houseworkId.toString(),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              // ページネーション
                              if (state.totalPages > 1)
                                _PaginationRow(
                                  state: state,
                                  notifier: notifier,
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  const _PaginationRow({required this.state, required this.notifier});

  final HouseworkListState state;
  final HouseworkListNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const Key('paginationPrev'),
            onPressed: state.currentPage > 1
                ? () => notifier.goToPage(state.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            l10n.houseworkSettingsPageInfo(state.currentPage, state.totalPages),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textBody),
          ),
          IconButton(
            key: const Key('paginationNext'),
            onPressed: state.currentPage < state.totalPages
                ? () => notifier.goToPage(state.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
