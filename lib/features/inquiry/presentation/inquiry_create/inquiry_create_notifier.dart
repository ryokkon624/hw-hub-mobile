import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/network/app_exception.dart';
import '../../../app_info/app_info_providers.dart';
import '../../../inquiry/inquiry_providers.dart';
import '../../../../core/models/ui_client.dart';

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
    await _runCatching(
      () async {
        final repo = ref.read(inquiryRepositoryProvider);
        final appInfoRepo = ref.read(appInfoRepositoryProvider);

        // バージョン情報を並行取得
        final results = await Future.wait([
          PackageInfo.fromPlatform(),
          appInfoRepo.fetchApiVersion(),
        ]);
        final packageInfo = results[0] as PackageInfo;
        final apiVersion = (results[1] as String?) ?? 'unknown';

        final inquiryId = await repo.createInquiry(
          category: state.selectedCategory!,
          title: state.title.trim(),
          body: state.body.trim(),
          uiClient: UiClient.mobile.code,
          uiVersion: packageInfo.version,
          apiVersion: apiVersion,
        );
        state = state.copyWith(
          isSubmitting: false,
          createdInquiryId: inquiryId,
        );
      },
      onError: (msg) => state.copyWith(isSubmitting: false, errorMessage: msg),
    );
  }

  /// AutoDisposeNotifier 向けエラーハンドリングヘルパー。
  Future<void> _runCatching(
    Future<void> Function() operation, {
    InquiryCreateState Function(String errorMessage)? onError,
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
