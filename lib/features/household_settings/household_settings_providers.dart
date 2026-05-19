import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/household_settings_repository.dart';

final householdSettingsRepositoryProvider =
    Provider<HouseholdSettingsRepository>((ref) {
      return HouseholdSettingsRepositoryImpl(ref.watch(dioProvider));
    });
