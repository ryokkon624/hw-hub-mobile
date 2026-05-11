import '../../data/models/invitation_info.dart';

class InvitationState {
  const InvitationState({
    this.invitationInfo,
    this.isLoading = false,
    this.isActing = false,
    this.errorMessage,
    this.accepted = false,
    this.declined = false,
  });

  final InvitationInfo? invitationInfo;
  final bool isLoading;
  final bool isActing;
  final String? errorMessage;
  final bool accepted;
  final bool declined;

  InvitationState copyWith({
    InvitationInfo? invitationInfo,
    bool? isLoading,
    bool? isActing,
    Object? errorMessage = _sentinel,
    bool? accepted,
    bool? declined,
  }) => InvitationState(
    invitationInfo: invitationInfo ?? this.invitationInfo,
    isLoading: isLoading ?? this.isLoading,
    isActing: isActing ?? this.isActing,
    errorMessage: errorMessage == _sentinel
        ? this.errorMessage
        : errorMessage as String?,
    accepted: accepted ?? this.accepted,
    declined: declined ?? this.declined,
  );

  static const _sentinel = Object();
}
