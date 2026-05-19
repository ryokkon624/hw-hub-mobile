import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

/// アプリのロケール（言語）を管理する Notifier。
///
/// - `null` はシステムロケール追従（MaterialApp.router の locale: null と等価）
/// - `setLocale(Locale)` を呼ぶと SharedPreferences に永続化し、即時反映する
class LocaleNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code == null) return null;
    return Locale(code);
  }

  /// ロケールを更新して SharedPreferences に永続化する。
  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
    state = AsyncData(locale);
  }
}

final localeNotifierProvider = AsyncNotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
