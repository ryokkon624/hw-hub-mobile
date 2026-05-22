import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/network/s3_url_resolver.dart';
import 'data/household_settings_repository.dart';
import 'presentation/household_settings/household_settings_notifier.dart';
import 'presentation/household_settings/household_settings_state.dart';

export 'presentation/household_settings/household_settings_notifier.dart';
export 'presentation/household_settings/household_settings_state.dart';

final householdSettingsRepositoryProvider =
    Provider<HouseholdSettingsRepository>((ref) {
      return HouseholdSettingsRepositoryImpl(
        ref.watch(dioProvider),
        S3UrlResolver(isDebug: kDebugMode),
      );
    });

final householdSettingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      HouseholdSettingsNotifier,
      HouseholdSettingsState
    >(HouseholdSettingsNotifier.new);
