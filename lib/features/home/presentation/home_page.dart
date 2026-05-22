import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/main_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../home_providers.dart';
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
      appBar: MainAppBar(title: l10n.pageTitleHome),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: resolveErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(homeNotifierProvider),
        ),
        data: (state) => _HomeBody(state: state),
      ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homeNotifierProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // 世帯未所属時のオンボーディングカード（AC6）
          if (!state.hasHousehold)
            OnboardingCard(
              onGoHousehold: () => context.go(AppRoutes.settingsHousehold),
              onGoHousework: () => context.go(AppRoutes.settingsHousework),
            ),
          // My Tasksカード（AC2）
          MyTasksCard(
            summary: state.myTasksSummary,
            onOpen: () => context.go(AppRoutes.tasks),
          ),
          // 家事未割り当てカード（AC3）
          UnassignedCard(
            summary: state.unassignedSummary,
            onOpen: () => context.go(AppRoutes.housework),
          ),
          // 買い物リストカード（AC4）
          ShoppingCard(
            items: state.shoppingItems,
            onOpen: () => context.go(AppRoutes.shopping),
          ),
          // おうちの様子カード（AC5）
          HouseholdOverviewCard(
            overview: state.householdOverview,
            members: state.members,
            hasOverviewData: state.hasOverviewData,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
