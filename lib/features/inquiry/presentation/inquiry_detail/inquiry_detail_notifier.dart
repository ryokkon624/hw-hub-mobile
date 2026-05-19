import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_exception.dart';
import '../../inquiry_providers.dart';
import 'inquiry_detail_state.dart';

class InquiryDetailNotifier
    extends AutoDisposeFamilyNotifier<InquiryDetailState, int> {
  @override
  InquiryDetailState build(int arg) {
    Future.microtask(_fetchDetail);
    return const InquiryDetailState();
  }

  Future<void> _fetchDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(inquiryRepositoryProvider);
      final detail = await repo.fetchInquiry(arg);
      state = state.copyWith(detail: detail, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        fetchFailed: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'errorUnexpected',
        fetchFailed: true,
      );
    }
  }

  Future<void> sendReply(String body) async {
    try {
      final repo = ref.read(inquiryRepositoryProvider);
      await repo.addMessage(arg, body);
      final detail = await repo.fetchInquiry(arg);
      state = state.copyWith(detail: detail, replySent: true);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'errorUnexpected');
    }
  }

  Future<void> close() async {
    try {
      final repo = ref.read(inquiryRepositoryProvider);
      await repo.closeInquiry(arg);
      final detail = await repo.fetchInquiry(arg);
      state = state.copyWith(detail: detail, closed: true);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'errorUnexpected');
    }
  }

  Future<void> escalate() async {
    try {
      final repo = ref.read(inquiryRepositoryProvider);
      await repo.escalateToStaff(arg);
      final detail = await repo.fetchInquiry(arg);
      state = state.copyWith(detail: detail, escalated: true);
    } on AppException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(errorMessage: 'errorUnexpected');
    }
  }

  void clearReplySent() {
    state = state.copyWith(replySent: false);
  }
}

final inquiryDetailNotifierProvider = NotifierProvider.autoDispose
    .family<InquiryDetailNotifier, InquiryDetailState, int>(
      InquiryDetailNotifier.new,
    );
