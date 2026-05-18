import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/models/notification_link_type.dart';

/// linkType に応じて対応画面に遷移するユーティリティ。
///
/// linkType → 遷移先:
/// - NONE(none)       → 遷移なし
/// - MY_TASKS(myTasks) → /tasks
/// - HOUSEHOLD(household) / INVITATION(invitation) → /settings/household
/// - SETTINGS(settings) → /settings/account
/// - INQUIRY(inquiryDetail) → /settings/inquiries/{linkId}
abstract class NotificationLinkNavigator {
  static void navigate({
    required BuildContext context,
    required String linkType,
    int? linkId,
  }) {
    final type = NotificationLinkType.fromCode(linkType);
    if (type == null || type == NotificationLinkType.none) return;

    switch (type) {
      case NotificationLinkType.myTasks:
        context.push(AppRoutes.tasks);
      case NotificationLinkType.household:
      case NotificationLinkType.invitation:
        context.push(AppRoutes.settingsHousehold);
      case NotificationLinkType.settings:
        context.push(AppRoutes.settingsAccount);
      case NotificationLinkType.inquiryDetail:
        if (linkId != null) {
          context.push(AppRoutes.settingsInquiryDetail(linkId.toString()));
        }
      case NotificationLinkType.none:
        break;
    }
  }
}
