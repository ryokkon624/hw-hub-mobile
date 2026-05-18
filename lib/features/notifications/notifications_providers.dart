import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(dioProvider));
});
