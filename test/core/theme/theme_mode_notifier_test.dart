import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/theme/theme_mode_notifier.dart';
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

  group('ThemeModeNotifier.build()', () {
    test(
      'SharedPreferences に保存値がない場合: material.ThemeMode.system を返す',
      () async {
        final container = _makeContainer();
        final state = await container.read(themeModeNotifierProvider.future);
        expect(state, material.ThemeMode.system);
      },
    );

    test('SharedPreferences に "LIGHT" が保存済みの場合: ThemeMode.light を返す', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'LIGHT'});
      final container = _makeContainer();
      final state = await container.read(themeModeNotifierProvider.future);
      expect(state, material.ThemeMode.light);
    });

    test('SharedPreferences に "DARK" が保存済みの場合: ThemeMode.dark を返す', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'DARK'});
      final container = _makeContainer();
      final state = await container.read(themeModeNotifierProvider.future);
      expect(state, material.ThemeMode.dark);
    });

    test(
      'SharedPreferences に "SYSTEM" が保存済みの場合: ThemeMode.system を返す',
      () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'SYSTEM'});
        final container = _makeContainer();
        final state = await container.read(themeModeNotifierProvider.future);
        expect(state, material.ThemeMode.system);
      },
    );

    test('SharedPreferences に不明な値がある場合: ThemeMode.system にフォールバックする', () async {
      SharedPreferences.setMockInitialValues({'app_theme_mode': 'UNKNOWN'});
      final container = _makeContainer();
      final state = await container.read(themeModeNotifierProvider.future);
      expect(state, material.ThemeMode.system);
    });
  });

  group('ThemeModeNotifier.setThemeMode()', () {
    test('setThemeMode(light) で state が ThemeMode.light に更新される', () async {
      final container = _makeContainer();
      await container.read(themeModeNotifierProvider.future);

      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(material.ThemeMode.light);

      final updated = container.read(themeModeNotifierProvider).value;
      expect(updated, material.ThemeMode.light);
    });

    test('setThemeMode(dark) で SharedPreferences に "DARK" が保存される', () async {
      final container = _makeContainer();
      await container.read(themeModeNotifierProvider.future);

      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(material.ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'DARK');
    });

    test(
      'setThemeMode(system) で SharedPreferences に "SYSTEM" が保存される',
      () async {
        final container = _makeContainer();
        await container.read(themeModeNotifierProvider.future);

        await container
            .read(themeModeNotifierProvider.notifier)
            .setThemeMode(material.ThemeMode.system);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('app_theme_mode'), 'SYSTEM');
      },
    );

    test('setThemeMode を複数回呼んでも最後の値が保存される', () async {
      final container = _makeContainer();
      await container.read(themeModeNotifierProvider.future);

      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(material.ThemeMode.light);
      await container
          .read(themeModeNotifierProvider.notifier)
          .setThemeMode(material.ThemeMode.dark);

      final updated = container.read(themeModeNotifierProvider).value;
      expect(updated, material.ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'DARK');
    });
  });
}
