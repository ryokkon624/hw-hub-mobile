import '../../data/notification_repository.dart';

class NotificationCenterState {
  const NotificationCenterState({
    this.notifications = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<NotificationDto> notifications;
  final bool isLoading;
  final String? errorMessage;

  NotificationCenterState copyWith({
    List<NotificationDto>? notifications,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return NotificationCenterState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
