import '../../../../l10n/app_localizations.dart';

/// 通知メッセージのタイトル・本文をレンダリングするクラス。
///
/// Flutter の AppLocalizations は動的キー参照ができないため、
/// Map ディスパッチテーブルで各 titleKey に対応する文字列を返す。
/// 未知のキーが来た場合はキー文字列をそのまま返す（Web 版と同じ挙動）。
class NotificationMessageRenderer {
  const NotificationMessageRenderer({required this.l10n});

  final AppLocalizations l10n;

  String renderTitle(String titleKey, Map<String, dynamic> params) {
    return switch (titleKey) {
      'acceptInvitation' => l10n.notificationsAcceptInvitationTitle,
      'declineInvitation' => l10n.notificationsDeclineInvitationTitle,
      'removedFromHousehold' => l10n.notificationsRemovedFromHouseholdTitle,
      'leftHousehold' => l10n.notificationsLeftHouseholdTitle,
      'assigned2Owner' => l10n.notificationsAssigned2OwnerTitle,
      'taskAssigned' => l10n.notificationsTaskAssignedTitle,
      'beDumpedTasks' => l10n.notificationsBeDumpedTasksTitle,
      'yourTaskWasTaken' => l10n.notificationsYourTaskWasTakenTitle,
      'generic' => l10n.notificationsGenericTitle,
      'inquiryReplied' => l10n.notificationsInquiryRepliedTitle,
      _ => titleKey,
    };
  }

  String renderBody(String bodyKey, Map<String, dynamic> params) {
    String p(String key) => (params[key] ?? '').toString();

    return switch (bodyKey) {
      'acceptInvitation' => l10n.notificationsAcceptInvitationBody(
        p('householdName'),
        p('memberName'),
      ),
      'declineInvitation' => l10n.notificationsDeclineInvitationBody(
        p('householdName'),
        p('memberName'),
      ),
      'removedFromHousehold' => l10n.notificationsRemovedFromHouseholdBody(
        p('householdName'),
      ),
      'leftHousehold' => l10n.notificationsLeftHouseholdBody(
        p('householdName'),
        p('memberName'),
      ),
      'assigned2Owner' => l10n.notificationsAssigned2OwnerBody(
        p('householdName'),
      ),
      'taskAssigned' => l10n.notificationsTaskAssignedBody(
        p('actorName'),
        p('household'),
        p('date'),
        p('count'),
      ),
      'beDumpedTasks' => l10n.notificationsBeDumpedTasksBody(
        p('actorName'),
        p('household'),
        p('date'),
        p('count'),
      ),
      'yourTaskWasTaken' => l10n.notificationsYourTaskWasTakenBody(
        p('actorName'),
        p('household'),
        p('date'),
        p('count'),
      ),
      'generic' => l10n.notificationsGenericBody(
        p('household'),
        p('date'),
        p('count'),
      ),
      'inquiryReplied' => l10n.notificationsInquiryRepliedBody(
        p('inquiryId'),
        p('title'),
      ),
      _ => bodyKey,
    };
  }
}
