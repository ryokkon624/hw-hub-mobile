import 'package:flutter/material.dart';
import '../../../../../core/models/sender_type.dart';
import '../../../../../core/theme/app_color_scheme.dart';
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

    final bubbleColor = isUser ? colors.primary : colors.surfaceCard;
    final textColor = isUser ? colors.onPrimary : colors.textBody;
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
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
            border: isUser ? null : Border.all(color: colors.border),
          ),
          child: Text(
            message.body,
            style: TextStyle(color: textColor, fontSize: 14),
          ),
        ),
        // タイムスタンプ
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _formatDateTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final y = dt.year;
      final mo = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$y/$mo/$d $h:$mi';
    } catch (_) {
      return isoString;
    }
  }
}
