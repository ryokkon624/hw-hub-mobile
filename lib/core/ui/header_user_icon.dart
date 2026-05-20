import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../auth/auth_state.dart';
import '../di/providers.dart';
import '../../l10n/app_localizations.dart';
import 'user_avatar.dart';

/// ヘッダー右端に表示するユーザーアイコン。
///
/// タップするとポップオーバーメニューを表示し、「設定」「ログアウト」を提供する。
class HeaderUserIcon extends ConsumerWidget {
  const HeaderUserIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context);

    String? iconUrl;
    String displayName = '';

    final authState = authAsync.valueOrNull;
    if (authState is AuthAuthenticated) {
      iconUrl = authState.user.iconUrl;
      displayName = authState.user.displayName;
    }

    return GestureDetector(
      onTapUp: (details) =>
          _showMenu(context, ref, details.globalPosition, l10n),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: UserAvatar(
          iconUrl: iconUrl,
          label: displayName,
          size: UserAvatarSize.sm,
        ),
      ),
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    AppLocalizations l10n,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null) return;

    final RelativeRect relativeRect = RelativeRect.fromRect(
      Rect.fromPoints(position, position),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<_MenuAction>(
      context: context,
      position: relativeRect,
      items: [
        PopupMenuItem(
          key: const Key('menuItemSettings'),
          value: _MenuAction.settings,
          child: Text(l10n.headerUserIconMenuSettings),
        ),
        PopupMenuItem(
          key: const Key('menuItemLogout'),
          value: _MenuAction.logout,
          child: Text(l10n.headerUserIconMenuLogout),
        ),
      ],
    );

    if (!context.mounted) return;

    switch (selected) {
      case _MenuAction.settings:
        context.go(AppRoutes.settings);
      case _MenuAction.logout:
        await _confirmLogout(context, ref, l10n);
      case null:
        break;
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('logoutConfirmDialog'),
        title: Text(l10n.headerUserIconLogoutConfirmTitle),
        content: Text(l10n.headerUserIconLogoutConfirmMessage),
        actions: [
          TextButton(
            key: const Key('logoutCancelButton'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const Key('logoutConfirmButton'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.commonYes),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

enum _MenuAction { settings, logout }
