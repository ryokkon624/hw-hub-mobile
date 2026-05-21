import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theme_mode.dart' as hw;

const _kThemeModeKey = 'app_theme_mode';

/// アプリのテーマモード（ライト/ダーク/システム連動）を管理する Notifier。
///
/// - SharedPreferences に永続化する（デバイスローカル）
/// - `null` または不明な値はシステム連動（material.ThemeMode.system）にフォールバック
/// - `setThemeMode()` で即時反映 → AC3
/// - AC4: 再起動後も保持（SharedPreferences から復元）
/// - AC5: バックエンドとの同期は `AccountSettingsRepository.updateThemeMode()` 経由
class ThemeModeNotifier extends AsyncNotifier<material.ThemeMode> {
  @override
  Future<material.ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kThemeModeKey);
    return _fromCode(code);
  }

  /// テーマモードを変更して SharedPreferences に永続化する。
  Future<void> setThemeMode(material.ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, _toCode(mode));
    state = AsyncData(mode);
  }

  /// HwHub の ThemeMode コードから Flutter の material.ThemeMode に変換する。
  material.ThemeMode _fromCode(String? code) {
    final hwMode = hw.ThemeMode.fromCode(code);
    switch (hwMode) {
      case hw.ThemeMode.light:
        return material.ThemeMode.light;
      case hw.ThemeMode.dark:
        return material.ThemeMode.dark;
      case hw.ThemeMode.system:
      case null:
        return material.ThemeMode.system;
    }
  }

  /// Flutter の material.ThemeMode を HwHub の ThemeMode コードに変換する。
  String _toCode(material.ThemeMode mode) {
    switch (mode) {
      case material.ThemeMode.light:
        return hw.ThemeMode.light.code;
      case material.ThemeMode.dark:
        return hw.ThemeMode.dark.code;
      case material.ThemeMode.system:
        return hw.ThemeMode.system.code;
    }
  }
}

final themeModeNotifierProvider =
    AsyncNotifierProvider<ThemeModeNotifier, material.ThemeMode>(
      ThemeModeNotifier.new,
    );
