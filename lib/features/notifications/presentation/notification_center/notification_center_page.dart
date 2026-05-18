import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/notification_link_type.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../notification_global_notifier.dart';
import '../widgets/notification_link_navigator.dart';
import '../widgets/notification_list_item.dart';
import '../widgets/notification_message_renderer.dart';
import 'notification_center_notifier.dart';

class NotificationCenterPage extends ConsumerWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final state = ref.watch(notificationCenterNotifierProvider);
    final renderer = NotificationMessageRenderer(l10n: l10n);

    // エラーメッセージがあれば SnackBar 表示
    ref.listen(notificationCenterNotifierProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        AppSnackBar.showError(next.errorMessage!);
      }
    });

    // 通知センター表示後は未読をリセット
    ref.listen(notificationCenterNotifierProvider, (_, next) {
      if (!next.isLoading && next.notifications.isNotEmpty) {
        ref.read(notificationGlobalNotifierProvider.notifier).resetToZero();
      }
    });

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        title: Text(
          l10n.notificationsCenterTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サブタイトル + 更新ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.notificationsCenterSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
                ),
                TextButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => ref
                            .read(notificationCenterNotifierProvider.notifier)
                            .reload(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l10n.notificationsReload),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 通知一覧
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.notifications.isEmpty
                ? Center(
                    child: Text(
                      l10n.notificationsEmpty,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: state.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = state.notifications[index];
                      return NotificationListItem(
                        key: ValueKey(notification.notificationId),
                        notification: notification,
                        renderer: renderer,
                        onTap:
                            NotificationLinkType.fromCode(
                                  notification.linkType,
                                ) !=
                                NotificationLinkType.none
                            ? () => NotificationLinkNavigator.navigate(
                                context: context,
                                linkType: notification.linkType,
                                linkId: notification.linkId,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
