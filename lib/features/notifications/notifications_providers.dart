import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/notification_repository.dart';
import 'presentation/notification_center/notification_center_notifier.dart';
import 'presentation/notification_center/notification_center_state.dart';
import 'presentation/notification_global_notifier.dart';

export 'presentation/notification_center/notification_center_notifier.dart';
export 'presentation/notification_center/notification_center_state.dart';
export 'presentation/notification_global_notifier.dart'; // exports NotificationGlobalNotifier + NotificationGlobalState

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(dioProvider));
});

final notificationCenterNotifierProvider =
    NotifierProvider<NotificationCenterNotifier, NotificationCenterState>(
      NotificationCenterNotifier.new,
    );

final notificationGlobalNotifierProvider =
    NotifierProvider<NotificationGlobalNotifier, NotificationGlobalState>(
      NotificationGlobalNotifier.new,
    );
