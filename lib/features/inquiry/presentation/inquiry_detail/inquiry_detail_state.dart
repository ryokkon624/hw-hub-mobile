import '../../data/inquiry_repository.dart';

class InquiryDetailState {
  const InquiryDetailState({
    this.detail,
    this.isLoading = true,
    this.errorMessage,
    this.fetchFailed = false,
    this.replySent = false,
    this.closed = false,
    this.escalated = false,
  });

  final InquiryDetailDto? detail;
  final bool isLoading;
  final String? errorMessage;
  final bool fetchFailed;
  final bool replySent;
  final bool closed;
  final bool escalated;

  InquiryDetailState copyWith({
    Object? detail = _sentinel,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    bool? fetchFailed,
    bool? replySent,
    bool? closed,
    bool? escalated,
  }) {
    return InquiryDetailState(
      detail: detail == _sentinel ? this.detail : detail as InquiryDetailDto?,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      fetchFailed: fetchFailed ?? this.fetchFailed,
      replySent: replySent ?? this.replySent,
      closed: closed ?? this.closed,
      escalated: escalated ?? this.escalated,
    );
  }
}

const _sentinel = Object();
