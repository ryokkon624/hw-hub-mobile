import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'household_state.dart';
import '../di/providers.dart';
import '../models/household.dart';
import '../network/app_exception.dart';
import '../storage/storage_keys.dart';

class HouseholdNotifier extends AsyncNotifier<HouseholdState> {
  @override
  Future<HouseholdState> build() async {
    final dio = ref.read(dioProvider);
    try {
      final response = await dio.get<dynamic>('/api/users/me/households');
      final data = response.data as List<dynamic>;
      final households = data
          .map(
            (e) => Household(
              id: (e as Map<String, dynamic>)['householdId'] as int,
              name: e['name'] as String,
            ),
          )
          .toList();

      final selected = await _restoreSelection(households);
      return HouseholdState(
        households: households,
        selectedHousehold: selected,
      );
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      throw NetworkException(e.message ?? 'Network error');
    }
  }

  Future<void> select(Household household) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.selectedHouseholdId, household.id);

    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedHousehold: household));
  }

  // 保存済みの選択世帯IDを復元。所属解除済みの場合は先頭にフォールバック。
  Future<Household?> _restoreSelection(List<Household> households) async {
    if (households.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getInt(StorageKeys.selectedHouseholdId);
    if (savedId == null) return households.first;
    return households.firstWhere(
      (h) => h.id == savedId,
      orElse: () => households.first,
    );
  }
}
