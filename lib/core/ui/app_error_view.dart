import 'package:flutter/material.dart';
import '../network/app_exception.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// 例外種別を i18n 済みエラーメッセージに変換する共通関数。
///
/// 各画面の `error:` ハンドラで呼び出し、[AppErrorView.message] に渡す。
String resolveErrorMessage(Object error, AppLocalizations l10n) {
  if (error is NetworkException) return l10n.errorNetwork;
  if (error is UnauthorizedException) return l10n.errorUnauthorized;
  if (error is ServerException) return l10n.errorServer;
  // AppException のサブクラスのうち上記3つ以外（ApiException 等）は
  // error.message にユーザー向けメッセージが格納されている。
  if (error is AppException) return error.message;
  return l10n.errorUnexpected;
}

/// アプリ全体で統一されたエラー表示 Widget。
///
/// !マーク + エラーメッセージ + 再読み込みボタン のレイアウト。
/// ホーム画面のデザインを基準としてすべての画面で使用する。
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.message, required this.onRetry});

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
            Icon(
              Icons.error_outline,
              key: const Key('appErrorViewIcon'),
              color: colors.danger,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              key: const Key('appErrorViewMessage'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textBody),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('appErrorViewRetryButton'),
              onPressed: onRetry,
              child: Text(l10n.homeErrorRetry),
            ),
          ],
        ),
      ),
    );
  }
}
