import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/core/ui/app_snack_bar.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';

Widget buildTestPage(
  Widget page, {
  List<Override> overrides = const [],

  /// AppSnackBar を検証するテストでは [withSnackBarKey] を true にすること。
  bool withSnackBarKey = false,
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    scaffoldMessengerKey: withSnackBarKey
        ? AppSnackBar.messengerKey
        : GlobalKey<ScaffoldMessengerState>(),
    home: page,
  ),
);

/// GoRouter が必要なページ（context.go を呼ぶ）のテスト用。
/// routes の最初のルートをホームとして使う。
Widget buildTestPageWithRouter({
  required List<GoRoute> routes,
  List<Override> overrides = const [],
  String initialLocation = '/',
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp.router(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.light,
    routerConfig: GoRouter(initialLocation: initialLocation, routes: routes),
  ),
);
