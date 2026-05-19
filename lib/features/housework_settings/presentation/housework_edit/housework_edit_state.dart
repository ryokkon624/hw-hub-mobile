import '../../data/housework_settings_repository.dart';
import '../housework_create/housework_create_state.dart';

/// 家事編集画面の状態。
class HouseworkEditState {
  const HouseworkEditState({
    this.houseworkId,
    this.form = const HouseworkFormState(),
    this.members = const [],
    this.fetchError = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final int? houseworkId;
  final HouseworkFormState form;
  final List<HouseholdMemberDto> members;

  /// 家事データの取得に失敗した場合にtrueになる（一覧へリダイレクト用）
  final bool fetchError;

  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  HouseworkEditState copyWith({
    int? houseworkId,
    HouseworkFormState? form,
    List<HouseholdMemberDto>? members,
    bool? fetchError,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return HouseworkEditState(
      houseworkId: houseworkId ?? this.houseworkId,
      form: form ?? this.form,
      members: members ?? this.members,
      fetchError: fetchError ?? this.fetchError,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }
}
