import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'household_state.dart';
import '../models/household.dart';
import '../storage/storage_keys.dart';

class HouseholdNotifier extends AsyncNotifier<HouseholdState> {
  @override
  Future<HouseholdState> build() async {
    // TODO: GET /api/households/me をバックエンド実装後に呼び出す
    // Phase 3で以下に差し替え:
    // final dio = ref.read(dioProvider);
    // final res = await dio.get('/api/households/me');
    // final households = (res.data as List).map(Household.fromJson).toList();
    const households = <Household>[];

    final selected = await _restoreSelection(households);
    return HouseholdState(households: households, selectedHousehold: selected);
  }

  Future<void> select(Household household) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.selectedHouseholdId, household.id);

    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedHousehold: household));
  }

  // 保存済みの選択世帯IDを復元。所属解除済みの場合は先頭にフォールバック。
  Future<Household?> _restoreSelection(List<Household> households) async {
    if (households.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(StorageKeys.selectedHouseholdId);
    return households.firstWhere(
      (h) => h.id == savedId,
      orElse: () => households.first,
    );
  }
}
