import 'package:flutter/material.dart';

import '../../features/notifications/presentation/widgets/notification_bell.dart';
import '../theme/app_color_scheme.dart';
import 'header_user_icon.dart';

/// メイン画面（ホーム・家事分担・My Tasks・買い物・通知センター・設定）で共通利用する AppBar。
///
/// actions に [NotificationBell] と [HeaderUserIcon] を並べる。
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return AppBar(
      backgroundColor: colors.surfaceCard,
      elevation: 0,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.textHeading,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: const [NotificationBell(), HeaderUserIcon()],
    );
  }
}
