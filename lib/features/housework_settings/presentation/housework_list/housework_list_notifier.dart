import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../features/home/data/models/household_member_dto.dart';
import '../../data/models/housework_dto.dart';
import '../../housework_settings_providers.dart';
import 'housework_list_state.dart';

class HouseworkListNotifier
    extends AutoDisposeAsyncNotifier<HouseworkListState> {
  @override
  Future<HouseworkListState> build() async {
    // 世帯切り替えで自動再ロード
    final householdState = await ref.watch(householdNotifierProvider.future);
    final householdId = householdState.selectedHousehold?.id;
    if (householdId == null) {
      return const HouseworkListState();
    }

    final repo = ref.read(houseworkSettingsRepositoryProvider);
    final results = await Future.wait([
      repo.fetchHouseworks(householdId: householdId),
      repo.fetchMembers(householdId: householdId),
    ]);

    return HouseworkListState(
      allHouseworks: results[0] as List<HouseworkDto>,
      members: results[1] as List<HouseholdMemberDto>,
    );
  }

  /// カテゴリフィルタを設定する（null=すべて）。
  void filterByCategory(String? category) {
    final current = state.valueOrNull;
    if (current == null) return;

    if (category == null) {
      state = AsyncData(current.copyWith(clearCategory: true, currentPage: 1));
    } else {
      state = AsyncData(
        current.copyWith(selectedCategory: category, currentPage: 1),
      );
    }
  }

  /// ページを変更する。
  void goToPage(int page) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(currentPage: page));
  }

  /// 手動リロード（pull-to-refresh 用）。
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

final houseworkListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<HouseworkListNotifier, HouseworkListState>(
      HouseworkListNotifier.new,
    );
