import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return AppBar(
      backgroundColor: colors.surfaceCard,
      elevation: 0,
      title: Text(
        l10n.pageTitleHome,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.textHeading,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        // 通知ベル（#119: 通知センター）
        const NotificationBell(),
        // アカウントアイコン（#15で実装予定 - 現在はSnackBar表示）
        IconButton(
          icon: Icon(Icons.account_circle_outlined, color: colors.textMuted),
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.homeAppBarAccount))),
        ),
      ],
    );
  }
}
