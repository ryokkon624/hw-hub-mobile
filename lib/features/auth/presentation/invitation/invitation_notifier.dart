import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_exception.dart';
import '../../auth_providers.dart';
import 'invitation_state.dart';

final invitationNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<InvitationNotifier, InvitationState, String>(
      InvitationNotifier.new,
    );

class InvitationNotifier
    extends AutoDisposeFamilyAsyncNotifier<InvitationState, String> {
  @override
  Future<InvitationState> build(String token) async {
    if (token.isEmpty) {
      return const InvitationState(errorMessage: 'invalid');
    }
    final info = await ref
        .read(authRepositoryProvider)
        .getInvitation(token: token);
    return InvitationState(invitationInfo: info);
  }

  Future<void> accept() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isActing: true));
    try {
      await ref.read(authRepositoryProvider).acceptInvitation(token: arg);
      state = AsyncData(current.copyWith(isActing: false, accepted: true));
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(isActing: false, errorMessage: e.message),
      );
    }
  }

  Future<void> decline() async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(isActing: true));
    try {
      await ref.read(authRepositoryProvider).declineInvitation(token: arg);
      state = AsyncData(current.copyWith(isActing: false, declined: true));
    } on AppException catch (e) {
      state = AsyncData(
        current.copyWith(isActing: false, errorMessage: e.message),
      );
    }
  }
}
