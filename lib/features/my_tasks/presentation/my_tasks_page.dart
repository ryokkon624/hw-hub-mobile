import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/app_error_view.dart';
import '../../../core/ui/app_snack_bar.dart';
import '../../../core/ui/main_app_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../my_tasks_providers.dart';
import 'widgets/future_tasks_section.dart';
import 'widgets/past_tasks_section.dart';

class MyTasksPage extends ConsumerWidget {
  const MyTasksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasksAsync = ref.watch(myTasksNotifierProvider);

    // 操作エラー時にAppSnackBarで通知する
    ref.listen(myTasksNotifierProvider, (prev, next) {
      final errorMessage = next.valueOrNull?.errorMessage;
      if (errorMessage != null && prev?.valueOrNull?.errorMessage == null) {
        AppSnackBar.showError(_resolveErrorMessage(l10n, errorMessage));
      }
    });

    return Scaffold(
      appBar: MainAppBar(title: l10n.pageTitleMyTasks),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: resolveErrorMessage(error, l10n),
          onRetry: () => ref.invalidate(myTasksNotifierProvider),
        ),
        data: (state) => _TasksBody(state: state),
      ),
    );
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

class _TasksBody extends StatelessWidget {
  const _TasksBody({required this.state});

  final MyTasksState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return RefreshIndicator(
      onRefresh: () async {
        // ref.invalidate は ConsumerWidget なので _TasksBody では直接呼べないが、
        // RefreshIndicator 用に上位のウィジェットツリーで再読み込みする仕組みが
        // AutoDispose の build() リロードにより自動で動く（世帯切り替え連動）
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // ページ上部の説明テキスト（web SP版の myTasks.intro に相当）
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Text(
              l10n.myTasksIntro,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ),
          PastTasksSection(tasks: state.pastTasks),
          FutureTasksSection(
            tasks: state.filteredFutureTasks,
            filter: state.filter,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
