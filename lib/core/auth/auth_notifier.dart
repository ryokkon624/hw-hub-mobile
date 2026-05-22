import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import 'auth_state.dart';
import '../di/providers.dart';
import '../storage/storage_keys.dart';
import '../../features/auth/auth_providers.dart';
import '../../features/home/presentation/home_notifier.dart';
import '../../features/housework_assign/presentation/housework_assign_notifier.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    await _clearOnFreshInstall();
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    if (token == null) return const AuthUnauthenticated();

    // トークンがある場合は AuthRepository 経由でユーザー情報を取得する
    try {
      final user = await ref.read(authRepositoryProvider).getMyProfile();
      return AuthAuthenticated(user);
    } catch (_) {
      // /me 失敗時は再ログインを促す
      return const AuthUnauthenticated();
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    await ref
        .read(tokenStorageProvider)
        .saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    state = AsyncData(AuthAuthenticated(user));
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearTokens();

    // 選択世帯IDをクリアして次のユーザーが前のユーザーの世帯IDを引き継がないようにする
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.selectedHouseholdId);

    // 世帯・各一覧 Provider をリセットして別ユーザーでのログイン後に前ユーザーのデータが残らないようにする
    ref.invalidate(householdNotifierProvider);
    ref.invalidate(homeNotifierProvider);
    ref.invalidate(houseworkAssignNotifierProvider);

    state = const AsyncData(AuthUnauthenticated());
  }

  // iOSはアプリ削除後もKeychain（SecureStorage）が残るため、
  // 再インストール初回起動時にトークンをクリアする。
  // SharedPreferencesはアプリ削除で消えるのでインストール判定に使う。
  Future<void> _clearOnFreshInstall() async {
    if (!Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    final installed = prefs.getBool(StorageKeys.installFlag) ?? false;
    if (!installed) {
      await ref.read(tokenStorageProvider).clearTokens();
      await prefs.setBool(StorageKeys.installFlag, true);
    }
  }
}
