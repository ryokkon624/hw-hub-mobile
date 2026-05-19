import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/network/app_exception.dart';
import '../app_info_providers.dart';

class AppInfoNotifier extends AutoDisposeNotifier<AppInfoState> {
  @override
  AppInfoState build() {
    Future.microtask(_initialize);
    return const AppInfoState();
  }

  Future<void> _initialize() async {
    // アプリバージョン取得
    final String? appVersion = await _fetchAppVersion();
    state = state.copyWith(appVersion: appVersion);

    // APIバージョン取得
    await _fetchApiVersion();
  }

  Future<String?> _fetchAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchApiVersion() async {
    state = state.copyWith(isLoadingApi: true);
    try {
      final repo = ref.read(appInfoRepositoryProvider);
      final version = await repo.fetchApiVersion();
      state = state.copyWith(apiVersion: version, isLoadingApi: false);
    } on AppException catch (_) {
      state = state.copyWith(isLoadingApi: false);
    } catch (_) {
      state = state.copyWith(isLoadingApi: false);
    }
  }
}
