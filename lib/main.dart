import 'package:flutter/material.dart';
import 'core/theme/app_color_scheme.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HwHub',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        title: Text('HwHub', style: TextStyle(color: colors.onPrimary)),
      ),
      body: Center(
        child: Text('Hello HwHub', style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
