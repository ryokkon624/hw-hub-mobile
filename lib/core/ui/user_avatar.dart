import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// ユーザーアバター表示ウィジェット。
///
/// - [iconUrl] が指定されていればアイコン画像を表示し、
///   未指定または読み込み失敗時は [label] の先頭2文字をイニシャルとして表示する。
/// - [isUnassigned] が true の場合は未割当バッジ（「未」）を表示する。
enum UserAvatarSize { sm, md, lg }

class UserAvatar extends StatefulWidget {
  const UserAvatar({
    super.key,
    required this.iconUrl,
    required this.label,
    this.isUnassigned = false,
    this.size = UserAvatarSize.md,
  });

  final String? iconUrl;
  final String label;
  final bool isUnassigned;
  final UserAvatarSize size;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _imageError = false;

  double get _diameter {
    switch (widget.size) {
      case UserAvatarSize.sm:
        return 24;
      case UserAvatarSize.lg:
        return 36;
      case UserAvatarSize.md:
        return 32;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case UserAvatarSize.sm:
        return 10;
      case UserAvatarSize.lg:
        return 14;
      case UserAvatarSize.md:
        return 12;
    }
  }

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '?';
    final characters = trimmed.characters;
    if (characters.length <= 2) return trimmed;
    return characters.take(2).string;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final hasIcon =
        widget.iconUrl != null && widget.iconUrl!.isNotEmpty && !_imageError;

    Widget inner;
    if (widget.isUnassigned) {
      // 未割当: 「未」テキストをイニシャル代わりに表示
      inner = Center(
        child: Text(
          l10n.houseworkAssignUnassignedBadge,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      );
    } else if (hasIcon) {
      // アイコン画像あり
      inner = Image.network(
        widget.iconUrl!,
        width: _diameter,
        height: _diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          // エラー時はイニシャル表示に切り替え
          Future.microtask(() {
            if (mounted) setState(() => _imageError = true);
          });
          return Center(
            child: Text(
              _initials(widget.label),
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          );
        },
      );
    } else {
      // イニシャル表示
      inner = Center(
        child: Text(
          _initials(widget.label),
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.isUnassigned
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.primaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: inner,
    );
  }
}
