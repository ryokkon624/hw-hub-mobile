import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_exception.dart';
import '../../inquiry_providers.dart';

class InquiryDetailNotifier
    extends AutoDisposeFamilyNotifier<InquiryDetailState, int> {
  @override
  InquiryDetailState build(int arg) {
    Future.microtask(_fetchDetail);
    return const InquiryDetailState();
  }

  Future<void> _fetchDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _runCatching(
      () async {
        final repo = ref.read(inquiryRepositoryProvider);
        final detail = await repo.fetchInquiry(arg);
        state = state.copyWith(detail: detail, isLoading: false);
      },
      onError: (msg) => state.copyWith(
        isLoading: false,
        errorMessage: msg,
        fetchFailed: true,
      ),
    );
  }

  Future<void> sendReply(String body) async {
    await _runCatching(() async {
      final repo = ref.read(inquiryRepositoryProvider);
      await repo.addMessage(arg, body);
      final detail = await repo.fetchInquiry(arg);
      state = state.copyWith(detail: detail, replySent: true);
    });
  }

  Future<void> close() async {
    await _runCatching(() async {
      final repo = ref.read(inquiryRepositoryProvider);
      await repo.closeInquiry(arg);
      final detail = await repo.fetchInquiry(arg);
      state = state.copyWith(detail: detail, closed: true);
    });
  }

  Future<void> escalate() async {
    await _runCatching(() async {
      final repo = ref.read(inquiryRepositoryProvider);
      await repo.escalateToStaff(arg);
      final detail = await repo.fetchInquiry(arg);
      state = state.copyWith(detail: detail, escalated: true);
    });
  }

  /// Notifier（同期ステート）向けエラーハンドリングヘルパー。
  Future<void> _runCatching(
    Future<void> Function() operation, {
    InquiryDetailState Function(String errorMessage)? onError,
  }) async {
    try {
      await operation();
    } on AppException catch (e) {
      state = onError != null
          ? onError(e.message)
          : state.copyWith(errorMessage: e.message);
    } catch (_) {
      state = onError != null
          ? onError('errorUnexpected')
          : state.copyWith(errorMessage: 'errorUnexpected');
    }
  }

  Future<void> reload() async {
    await _fetchDetail();
  }

  void clearReplySent() {
    state = state.copyWith(replySent: false);
  }
}
