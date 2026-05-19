import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/housework_settings_repository.dart';

final houseworkSettingsRepositoryProvider =
    Provider<HouseworkSettingsRepository>((ref) {
      return HouseworkSettingsRepositoryImpl(ref.watch(dioProvider));
    });
