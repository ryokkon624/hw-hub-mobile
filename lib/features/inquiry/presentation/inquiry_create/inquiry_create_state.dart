class InquiryCreateState {
  const InquiryCreateState({
    this.selectedCategory,
    this.title = '',
    this.body = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.createdInquiryId,
  });

  final String? selectedCategory;
  final String title;
  final String body;
  final bool isSubmitting;
  final String? errorMessage;
  final int? createdInquiryId;

  InquiryCreateState copyWith({
    Object? selectedCategory = _sentinel,
    String? title,
    String? body,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? createdInquiryId = _sentinel,
  }) {
    return InquiryCreateState(
      selectedCategory: selectedCategory == _sentinel
          ? this.selectedCategory
          : selectedCategory as String?,
      title: title ?? this.title,
      body: body ?? this.body,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      createdInquiryId: createdInquiryId == _sentinel
          ? this.createdInquiryId
          : createdInquiryId as int?,
    );
  }
}

const _sentinel = Object();
