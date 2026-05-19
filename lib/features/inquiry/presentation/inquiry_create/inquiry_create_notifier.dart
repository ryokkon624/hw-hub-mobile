import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/app_exception.dart';
import '../../inquiry_providers.dart';
import 'inquiry_create_state.dart';

class InquiryCreateNotifier extends AutoDisposeNotifier<InquiryCreateState> {
  @override
  InquiryCreateState build() => const InquiryCreateState();

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category, errorMessage: null);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title, errorMessage: null);
  }

  void setBody(String body) {
    state = state.copyWith(body: body, errorMessage: null);
  }

  Future<void> submit() async {
    // バリデーション
    if (state.selectedCategory == null || state.selectedCategory!.isEmpty) {
      state = state.copyWith(
        errorMessage: 'inquiryCreateErrorCategoryRequired',
      );
      return;
    }
    if (state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'inquiryCreateErrorTitleRequired');
      return;
    }
    if (state.title.length > 200) {
      state = state.copyWith(errorMessage: 'inquiryCreateErrorTitleTooLong');
      return;
    }
    if (state.body.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'inquiryCreateErrorBodyRequired');
      return;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final repo = ref.read(inquiryRepositoryProvider);
      final inquiryId = await repo.createInquiry(
        category: state.selectedCategory!,
        title: state.title.trim(),
        body: state.body.trim(),
      );
      state = state.copyWith(isSubmitting: false, createdInquiryId: inquiryId);
    } on AppException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'errorUnexpected',
      );
    }
  }
}

final inquiryCreateNotifierProvider =
    NotifierProvider.autoDispose<InquiryCreateNotifier, InquiryCreateState>(
      InquiryCreateNotifier.new,
    );
