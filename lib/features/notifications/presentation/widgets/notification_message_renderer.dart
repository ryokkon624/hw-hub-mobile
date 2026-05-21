import '../../../../l10n/app_localizations.dart';

/// 通知メッセージのタイトル・本文をレンダリングするクラス。
///
/// Flutter の AppLocalizations は動的キー参照ができないため、
/// Map ディスパッチテーブルで各 titleKey に対応する文字列を返す。
/// 未知のキーが来た場合はキー文字列をそのまま返す（Web 版と同じ挙動）。
///
/// バックエンド（NotificationPublisher / NotificationAggregationService）が
/// DB に保存するキー値はフルパス形式。
///   例: 'notifications.messages.acceptInvitation.title'
///       'notifications.messages.acceptInvitation.body'
class NotificationMessageRenderer {
  const NotificationMessageRenderer({required this.l10n});

  final AppLocalizations l10n;

  String renderTitle(String titleKey, Map<String, dynamic> params) {
    return switch (titleKey) {
      'notifications.messages.acceptInvitation.title' =>
        l10n.notificationsAcceptInvitationTitle,
      'notifications.messages.declineInvitation.title' =>
        l10n.notificationsDeclineInvitationTitle,
      'notifications.messages.removedFromHousehold.title' =>
        l10n.notificationsRemovedFromHouseholdTitle,
      'notifications.messages.leftHousehold.title' =>
        l10n.notificationsLeftHouseholdTitle,
      'notifications.messages.assigned2Owner.title' =>
        l10n.notificationsAssigned2OwnerTitle,
      'notifications.messages.taskAssigned.title' =>
        l10n.notificationsTaskAssignedTitle,
      'notifications.messages.beDumpedTasks.title' =>
        l10n.notificationsBeDumpedTasksTitle,
      'notifications.messages.yourTaskWasTaken.title' =>
        l10n.notificationsYourTaskWasTakenTitle,
      'notifications.messages.generic.title' => l10n.notificationsGenericTitle,
      'notifications.messages.inquiryReplied.title' =>
        l10n.notificationsInquiryRepliedTitle,
      _ => titleKey,
    };
  }

  String renderBody(String bodyKey, Map<String, dynamic> params) {
    String p(String key) => (params[key] ?? '').toString();

    return switch (bodyKey) {
      'notifications.messages.acceptInvitation.body' =>
        l10n.notificationsAcceptInvitationBody(
          p('householdName'),
          p('memberName'),
        ),
      'notifications.messages.declineInvitation.body' =>
        l10n.notificationsDeclineInvitationBody(
          p('householdName'),
          p('memberName'),
        ),
      'notifications.messages.removedFromHousehold.body' =>
        l10n.notificationsRemovedFromHouseholdBody(p('householdName')),
      'notifications.messages.leftHousehold.body' =>
        l10n.notificationsLeftHouseholdBody(
          p('householdName'),
          p('memberName'),
        ),
      'notifications.messages.assigned2Owner.body' =>
        l10n.notificationsAssigned2OwnerBody(p('householdName')),
      'notifications.messages.taskAssigned.body' =>
        l10n.notificationsTaskAssignedBody(
          p('actorName'),
          p('household'),
          p('date'),
          p('count'),
        ),
      'notifications.messages.beDumpedTasks.body' =>
        l10n.notificationsBeDumpedTasksBody(
          p('actorName'),
          p('household'),
          p('date'),
          p('count'),
        ),
      'notifications.messages.yourTaskWasTaken.body' =>
        l10n.notificationsYourTaskWasTakenBody(
          p('actorName'),
          p('household'),
          p('date'),
          p('count'),
        ),
      'notifications.messages.generic.body' => l10n.notificationsGenericBody(
        p('household'),
        p('date'),
        p('count'),
      ),
      'notifications.messages.inquiryReplied.body' =>
        l10n.notificationsInquiryRepliedBody(p('inquiryId'), p('title')),
      _ => bodyKey,
    };
  }
}
