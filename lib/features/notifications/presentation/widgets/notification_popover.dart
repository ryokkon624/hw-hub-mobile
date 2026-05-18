import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/models/notification_link_type.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/notification_repository.dart';
import '../../notifications_providers.dart';
import '../notification_global_notifier.dart';
import 'notification_link_navigator.dart';
import 'notification_list_item.dart';
import 'notification_message_renderer.dart';

/// ベルアイコンタップ時に表示するポップオーバー。
/// showDialog で呼び出すことで、バリア（外側）タップで閉じる動作を実現する。
class NotificationPopover extends ConsumerStatefulWidget {
  const NotificationPopover({super.key});

  @override
  ConsumerState<NotificationPopover> createState() =>
      _NotificationPopoverState();
}

class _NotificationPopoverState extends ConsumerState<NotificationPopover> {
  List<NotificationDto> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final items = await repo.fetchNotifications(limit: 20, markRead: true);
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
        // 既読になるためバッジをリセット
        ref.read(notificationGlobalNotifierProvider.notifier).resetToZero();
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null; // SnackBarで通知するためnullのまま
        });
        AppSnackBar.showError(AppLocalizations.of(context).errorUnexpected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final renderer = NotificationMessageRenderer(l10n: l10n);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: kToolbarHeight + 8, right: 8),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: colors.surfaceCard,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.notificationsBellTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textHeading,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.notifications);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.notificationsViewAll,
                          style: TextStyle(color: colors.primary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // 通知リスト
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colors.danger),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (_notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.notificationsEmpty,
                      style: TextStyle(color: colors.textMuted),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return NotificationListItem(
                          key: ValueKey(notification.notificationId),
                          notification: notification,
                          renderer: renderer,
                          onTap:
                              NotificationLinkType.fromCode(
                                    notification.linkType,
                                  ) !=
                                  NotificationLinkType.none
                              ? () {
                                  Navigator.of(context).pop();
                                  NotificationLinkNavigator.navigate(
                                    context: context,
                                    linkType: notification.linkType,
                                    linkId: notification.linkId,
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ポップオーバーを表示する
Future<void> showNotificationPopover(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (dialogContext) => const NotificationPopover(),
  );
}
