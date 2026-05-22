import 'package:flutter/material.dart';
import '../../../../../core/models/sender_type.dart';
import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../core/utils/date_format_utils.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/inquiry_message_dto.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final InquiryMessageDto message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final senderType = SenderType.fromCode(message.senderType);
    final isUser = senderType == SenderType.you;

    final senderLabel = switch (senderType) {
      SenderType.you => l10n.senderTypeUser,
      SenderType.aiSupport => l10n.senderTypeAi,
      SenderType.staff => l10n.senderTypeStaff,
      null => message.senderType,
    };

    final (bubbleColor, bubbleBorderColor, textColor) = switch (senderType) {
      SenderType.you => (colors.primary, null as Color?, colors.onPrimary),
      SenderType.aiSupport => (
        colors.paletteVioletSoft,
        colors.paletteVioletBorder,
        colors.paletteVioletText,
      ),
      SenderType.staff => (
        colors.paletteEmeraldSoft,
        colors.paletteEmeraldBorder,
        colors.paletteEmeraldText,
      ),
      null => (colors.surfaceCard, colors.border, colors.textBody),
    };
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        // 送信者ラベル
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            senderLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // バブル本体
        Container(
          key: const Key('messageBubble'),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
            border: bubbleBorderColor != null
                ? Border.all(color: bubbleBorderColor)
                : null,
          ),
          child: Text(
            key: const Key('messageBubbleText'),
            message.body,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
        // タイムスタンプ
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            formatDateTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
