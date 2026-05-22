import 'package:flutter/material.dart';
import '../../../../core/models/notification_link_type.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../data/notification_repository.dart';
import 'notification_message_renderer.dart';

class NotificationListItem extends StatelessWidget {
  const NotificationListItem({
    super.key,
    required this.notification,
    required this.renderer,
    required this.onTap,
  });

  final NotificationDto notification;
  final NotificationMessageRenderer renderer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final title = renderer.renderTitle(
      notification.titleKey,
      notification.params,
    );
    final body = renderer.renderBody(notification.bodyKey, notification.params);
    final hasLink =
        NotificationLinkType.fromCode(notification.linkType) !=
        NotificationLinkType.none;
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? colors.primary50 : colors.surfaceCard,
          border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 未読インジケーター
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: AnimatedOpacity(
                opacity: isUnread ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // テキスト
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: colors.textHeading,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.textBody),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTimeWithSeconds(notification.occurredAt),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            // 遷移アイコン（linkTypeがNONE以外の場合のみ）
            if (hasLink)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: colors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
