import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/theme/app_color_scheme.dart';
import 'package:hw_hub_mobile/features/inquiry/data/models/inquiry_message_dto.dart';
import 'package:hw_hub_mobile/features/inquiry/presentation/inquiry_detail/widgets/message_bubble.dart';

import '../../../../helpers/widget_test_helpers.dart';

Widget _buildBubble(String senderType) => buildTestPage(
  Scaffold(
    body: MessageBubble(
      message: InquiryMessageDto(
        messageId: 1,
        seq: 1,
        senderType: senderType,
        body: 'テストメッセージ',
        createdAt: '2024-01-01T12:00:00Z',
      ),
    ),
  ),
);

void main() {
  group('MessageBubble', () {
    testWidgets('USER: バブルコンテナがprimaryカラーで表示される', (tester) async {
      await tester.pumpWidget(_buildBubble('USER'));
      await tester.pump();

      final container = tester.widget<Container>(
        find.byKey(const Key('messageBubble')),
      );
      final colors = Theme.of(
        tester.element(find.byKey(const Key('messageBubble'))),
      ).extension<AppColorScheme>()!;
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, colors.primary);
    });

    testWidgets('AI: バブルコンテナがpaletteVioletSoftカラーで表示される', (tester) async {
      await tester.pumpWidget(_buildBubble('AI'));
      await tester.pump();

      final container = tester.widget<Container>(
        find.byKey(const Key('messageBubble')),
      );
      final colors = Theme.of(
        tester.element(find.byKey(const Key('messageBubble'))),
      ).extension<AppColorScheme>()!;
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, colors.paletteVioletSoft);
    });

    testWidgets('STAFF: バブルコンテナがpaletteEmeraldSoftカラーで表示される', (tester) async {
      await tester.pumpWidget(_buildBubble('STAFF'));
      await tester.pump();

      final container = tester.widget<Container>(
        find.byKey(const Key('messageBubble')),
      );
      final colors = Theme.of(
        tester.element(find.byKey(const Key('messageBubble'))),
      ).extension<AppColorScheme>()!;
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, colors.paletteEmeraldSoft);
    });

    testWidgets('USER: テキストカラーがonPrimaryになる', (tester) async {
      await tester.pumpWidget(_buildBubble('USER'));
      await tester.pump();

      final colors = Theme.of(
        tester.element(find.byType(MessageBubble)),
      ).extension<AppColorScheme>()!;
      final text = tester.widget<Text>(
        find.byKey(const Key('messageBubbleText')),
      );
      expect(text.style?.color, colors.onPrimary);
    });

    testWidgets('AI: テキストカラーがpaletteVioletTextになる', (tester) async {
      await tester.pumpWidget(_buildBubble('AI'));
      await tester.pump();

      final colors = Theme.of(
        tester.element(find.byType(MessageBubble)),
      ).extension<AppColorScheme>()!;
      final text = tester.widget<Text>(
        find.byKey(const Key('messageBubbleText')),
      );
      expect(text.style?.color, colors.paletteVioletText);
    });

    testWidgets('STAFF: テキストカラーがpaletteEmeraldTextになる', (tester) async {
      await tester.pumpWidget(_buildBubble('STAFF'));
      await tester.pump();

      final colors = Theme.of(
        tester.element(find.byType(MessageBubble)),
      ).extension<AppColorScheme>()!;
      final text = tester.widget<Text>(
        find.byKey(const Key('messageBubbleText')),
      );
      expect(text.style?.color, colors.paletteEmeraldText);
    });
  });
}
