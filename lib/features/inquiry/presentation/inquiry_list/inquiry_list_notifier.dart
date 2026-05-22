import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_exception.dart';
import '../../inquiry_providers.dart';
import '../../data/inquiry_repository.dart';

class InquiryListState {
  const InquiryListState({
    this.inquiries = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final List<InquirySummaryDto> inquiries;
  final bool isLoading;
  final String? errorMessage;

  InquiryListState copyWith({
    List<InquirySummaryDto>? inquiries,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return InquiryListState(
      inquiries: inquiries ?? this.inquiries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

class InquiryListNotifier extends AutoDisposeNotifier<InquiryListState> {
  @override
  InquiryListState build() {
    Future.microtask(_fetchInquiries);
    return const InquiryListState();
  }

  Future<void> _fetchInquiries() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _runCatching(() async {
      final repo = ref.read(inquiryRepositoryProvider);
      final inquiries = await repo.fetchInquiries();
      state = state.copyWith(inquiries: inquiries, isLoading: false);
    }, onError: (msg) => state.copyWith(isLoading: false, errorMessage: msg));
  }

  Future<void> reload() async {
    await _fetchInquiries();
  }

  /// AutoDisposeNotifier 向けエラーハンドリングヘルパー。
  Future<void> _runCatching(
    Future<void> Function() operation, {
    InquiryListState Function(String errorMessage)? onError,
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
}
