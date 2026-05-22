import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../core/ui/main_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../shopping_providers.dart';
import '../widgets/basket_tab.dart';
import '../widgets/purchased_tab.dart';
import '../widgets/shopping_tab_bar.dart';
import '../widgets/unpurchased_tab.dart';

class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shoppingAsync = ref.watch(shoppingListNotifierProvider);

    // 操作エラー時にAppSnackBarで通知する
    ref.listen(shoppingListNotifierProvider, (prev, next) {
      final errorMessage = next.valueOrNull?.errorMessage;
      if (errorMessage != null && prev?.valueOrNull?.errorMessage == null) {
        AppSnackBar.showError(_resolveErrorMessage(l10n, errorMessage));
      }
    });

    return Scaffold(
      appBar: MainAppBar(title: l10n.shoppingListTitle),
      body: shoppingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: _errorMessage(l10n, error),
          onRetry: () => ref.invalidate(shoppingListNotifierProvider),
        ),
        data: (state) => _ShoppingBody(state: state),
      ),
    );
  }

  String _errorMessage(AppLocalizations l10n, Object error) {
    if (error is NetworkException) return l10n.errorNetwork;
    if (error is UnauthorizedException) return l10n.errorUnauthorized;
    if (error is ServerException) return l10n.errorServer;
    if (error is AppException) return error.message;
    return l10n.errorUnexpected;
  }
}

/// l10nキー名からローカライズ済みエラーメッセージを解決する。
String _resolveErrorMessage(AppLocalizations l10n, String messageOrKey) {
  switch (messageOrKey) {
    case 'errorUnexpected':
      return l10n.errorUnexpected;
    default:
      return messageOrKey;
  }
}

class _ShoppingBody extends ConsumerWidget {
  const _ShoppingBody({required this.state});

  final ShoppingListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final householdAsync = ref.watch(householdNotifierProvider);
    final hasHousehold = householdAsync.valueOrNull?.selectedHousehold != null;

    return Column(
      children: [
        // + アイテムを追加ボタン（AC12）
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hasHousehold
                  ? () => context.push(AppRoutes.shoppingNew)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.shoppingListAddItemButton),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // タブバー（AC1）
        ShoppingTabBar(
          activeTab: state.activeTab,
          unpurchasedCount: state.unpurchasedItems.length,
          basketCount: state.basketItems.length,
          purchasedCount: state.purchasedItems.length,
          onTabChanged: (tab) =>
              ref.read(shoppingListNotifierProvider.notifier).setTab(tab),
        ),
        // タブコンテンツ
        Expanded(child: _buildTabContent(context, ref, state, l10n)),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WidgetRef ref,
    ShoppingListState state,
    AppLocalizations l10n,
  ) {
    switch (state.activeTab) {
      case ShoppingTab.unpurchased:
        return UnpurchasedTab(
          items: state.filteredUnpurchasedItems,
          locationFilter: state.locationFilter,
          onCardTap: (id) =>
              context.push(AppRoutes.shoppingDetail(id.toString())),
        );
      case ShoppingTab.basket:
        return BasketTab(
          items: state.basketItems,
          onCardTap: (id) =>
              context.push(AppRoutes.shoppingDetail(id.toString())),
        );
      case ShoppingTab.purchased:
        return PurchasedTab(
          itemsByDate: state.purchasedItemsByDate,
          onCardTap: (id) =>
              context.push(AppRoutes.shoppingDetail(id.toString())),
        );
    }
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textBody),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
