import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import 'auth_state.dart';
import '../di/providers.dart';
import '../storage/storage_keys.dart';
import '../../features/auth/auth_providers.dart';

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
    // ログイン成功後に householdNotifierProvider を invalidate して
    // 新しいユーザーのトークンで世帯リストを再取得させる。
    // HouseholdNotifier を watch している HomeNotifier 等も自動的に再ビルドされる。
    ref.invalidate(householdNotifierProvider);
  }

  /// トークンリフレッシュ専用: 既存ユーザー情報を保持したままトークンのみ差し替える。
  /// リフレッシュ成功時に AuthInterceptor から呼び出される。
  /// saveTokens() と異なり householdNotifierProvider の invalidate は行わない
  /// （リフレッシュはセッション継続であり、世帯切替は不要なため）。
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await ref
        .read(tokenStorageProvider)
        .saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    // 現在の AuthAuthenticated 状態のユーザー情報を保持したまま state を更新する
    final currentUser = state.valueOrNull;
    if (currentUser is AuthAuthenticated) {
      state = AsyncData(AuthAuthenticated(currentUser.user));
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clearTokens();

    // 選択世帯IDをクリアして次のユーザーが前のユーザーの世帯IDを引き継がないようにする
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.selectedHouseholdId);

    // 先に未認証状態にセットする。
    // これにより、AuthInterceptor が 401 を受け取った際に
    // 既に AuthUnauthenticated 状態であることを検出して logout() 再入を防ぐ。
    state = const AsyncData(AuthUnauthenticated());

    // householdNotifierProvider はここでは invalidate しない。
    // トークンクリア後に invalidate するとトークンなしでビルドが走り 401 エラー状態になる。
    // その後 saveTokens() を呼んでも HouseholdNotifier がエラー状態のまま残ってしまう。
    // 代わりに saveTokens()（ログイン成功時）で invalidate することで
    // 新ユーザーのトークンで正常にビルドされる。
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
