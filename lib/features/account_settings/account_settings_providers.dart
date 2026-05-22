import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/network/s3_url_resolver.dart';
import 'data/account_settings_repository.dart';
import 'presentation/account_settings/account_settings_notifier.dart';
import 'presentation/account_settings/account_settings_state.dart';

export 'presentation/account_settings/account_settings_notifier.dart';
export 'presentation/account_settings/account_settings_state.dart';

/// S3 に直接 PUT するための素 Dio（インターセプターなし）
/// shopping_providers と同じパターン（shared s3DioProvider と統合しても良いが分離して管理）
final accountS3DioProvider = Provider<Dio>((ref) {
  return Dio();
});

final accountSettingsRepositoryProvider = Provider<AccountSettingsRepository>((
  ref,
) {
  return AccountSettingsRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(accountS3DioProvider),
    S3UrlResolver(isDebug: kDebugMode),
  );
});

final accountSettingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      AccountSettingsNotifier,
      AccountSettingsState
    >(AccountSettingsNotifier.new);
