import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../notification_global_notifier.dart';
import 'notification_popover.dart';

/// ヘッダー用のベルアイコン。
/// 未読件数バッジとベルアニメーション（振り子）を持つ。
class NotificationBell extends ConsumerStatefulWidget {
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnimation;
  int _prevUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 1),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationGlobalNotifierProvider);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    // 未読数が増えた場合にアニメーション発火
    if (state.unreadCount > _prevUnreadCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _triggerShake());
    }
    _prevUnreadCount = state.unreadCount;

    return IconButton(
      onPressed: () => showNotificationPopover(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _shakeAnimation.value,
                child: child,
              );
            },
            child: Icon(
              Icons.notifications_outlined,
              color: state.showBadge ? Colors.amber[600] : colors.textMuted,
            ),
          ),
          if (state.showBadge)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  state.badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
