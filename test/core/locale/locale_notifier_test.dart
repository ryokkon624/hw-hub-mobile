import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/locale/locale_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _makeContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleNotifier.build()', () {
    test('SharedPreferencesに保存されたロケールがない場合: nullを返す（システムロケール追従）', () async {
      final container = _makeContainer();
      final state = await container.read(localeNotifierProvider.future);
      expect(state, isNull);
    });

    test('SharedPreferencesに"ja"が保存済みの場合: Locale("ja")を返す', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
      final container = _makeContainer();
      final state = await container.read(localeNotifierProvider.future);
      expect(state, equals(const Locale('ja')));
    });

    test('SharedPreferencesに"en"が保存済みの場合: Locale("en")を返す', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      final container = _makeContainer();
      final state = await container.read(localeNotifierProvider.future);
      expect(state, equals(const Locale('en')));
    });

    test('SharedPreferencesに"es"が保存済みの場合: Locale("es")を返す', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'es'});
      final container = _makeContainer();
      final state = await container.read(localeNotifierProvider.future);
      expect(state, equals(const Locale('es')));
    });
  });

  group('LocaleNotifier.setLocale()', () {
    test('setLocale()でstateが更新される', () async {
      final container = _makeContainer();
      // 初期状態はnull
      await container.read(localeNotifierProvider.future);

      await container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));

      final updated = container.read(localeNotifierProvider).value;
      expect(updated, equals(const Locale('en')));
    });

    test('setLocale()でSharedPreferencesにロケールコードが保存される', () async {
      final container = _makeContainer();
      await container.read(localeNotifierProvider.future);

      await container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('es'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), equals('es'));
    });

    test('setLocale()を複数回呼んでも最後のロケールが保存される', () async {
      final container = _makeContainer();
      await container.read(localeNotifierProvider.future);

      await container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('en'));
      await container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('ja'));

      final updated = container.read(localeNotifierProvider).value;
      expect(updated, equals(const Locale('ja')));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), equals('ja'));
    });
  });
}
