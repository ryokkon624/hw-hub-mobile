import 'package:flutter/material.dart';
import '../network/app_exception.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppSnackBar {
  AppSnackBar._();

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message) => _show(
    message: message,
    icon: Icons.check_circle_outline,
    backgroundColor: const Color(0xFF059669),
    foregroundColor: Colors.white,
  );

  static void showError(String message) => _show(
    message: message,
    icon: Icons.error_outline,
    backgroundColor: const Color(0xFFE11D48),
    foregroundColor: Colors.white,
  );

  static void showWarning(String message) => _show(
    message: message,
    icon: Icons.warning_amber_outlined,
    backgroundColor: const Color(0xFFF59E0B),
    foregroundColor: const Color(0xFF1E293B),
  );

  static void showInfo(String message) => _show(
    message: message,
    icon: Icons.info_outline,
    backgroundColor: const Color(0xFF1D4ED8),
    foregroundColor: Colors.white,
  );

  static void _show({
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: foregroundColor, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.md),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}

extension AppExceptionSnackBar on AppException {
  void showAsSnackBar() {
    switch (this) {
      case NetworkException():
        AppSnackBar.showError(message);
      case UnauthorizedException():
        AppSnackBar.showError(message);
      case ServerException():
        AppSnackBar.showError(message);
      case ApiException():
        AppSnackBar.showError(message);
    }
  }
}
