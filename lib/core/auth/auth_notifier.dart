import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';
import '../di/providers.dart';
import '../storage/storage_keys.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    await _clearOnFreshInstall();
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    return token != null
        ? const AuthAuthenticated()
        : const AuthUnauthenticated();
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await ref.read(tokenStorageProvider).saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
    state = const AsyncData(AuthAuthenticated());
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearTokens();
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
