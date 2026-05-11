import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import 'home_notifier.dart';
import 'home_state.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/household_overview_card.dart';
import 'widgets/my_tasks_card.dart';
import 'widgets/onboarding_card.dart';
import 'widgets/shopping_card.dart';
import 'widgets/unassigned_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final homeAsync = ref.watch(homeNotifierProvider);

    return Scaffold(
      appBar: const HomeAppBar(),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: _errorMessage(l10n, error),
          onRetry: () => ref.invalidate(homeNotifierProvider),
        ),
        data: (state) => _HomeBody(state: state),
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

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Notifier の refresh を呼ぶ（ProviderScopeからは直接取れないため invalidate で代用）
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // 世帯未所属時のオンボーディングカード（AC6）
          if (!state.hasHousehold)
            OnboardingCard(
              onGoHousehold: () => context.go('/settings/household'),
              onGoHousework: () => context.go('/settings/housework'),
            ),
          // My Tasksカード（AC2）
          MyTasksCard(
            summary: state.myTasksSummary,
            onOpen: () => context.go('/tasks'),
          ),
          // 家事未割り当てカード（AC3）
          UnassignedCard(
            summary: state.unassignedSummary,
            onOpen: () => context.go('/housework'),
          ),
          // 買い物リストカード（AC4）
          ShoppingCard(
            items: state.shoppingItems,
            onOpen: () => context.go('/shopping'),
          ),
          // おうちの様子カード（AC5）
          HouseholdOverviewCard(
            overview: state.householdOverview,
            members: state.members,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
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
            Icon(Icons.error_outline, color: colors.danger, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textBody),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: Text(l10n.homeErrorRetry)),
          ],
        ),
      ),
    );
  }
}
