import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/swipe_date_calendar.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('SwipeDateCalendar', () {
    testWidgets('TableCalendar ウィジェットが描画される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const SwipeDateCalendar(targetDate: '2026-05-20')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar), findsOneWidget);
    });

    testWidgets('targetDate が null の場合も TableCalendar が描画される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(const SwipeDateCalendar(targetDate: null)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar), findsOneWidget);
    });

    testWidgets('targetDate のある月が focusedDay としてカレンダーに表示される', (tester) async {
      // 2026-05-20 を指定 → 2026年5月が表示される
      await tester.pumpWidget(
        buildTestPage(const SwipeDateCalendar(targetDate: '2026-05-20')),
      );
      await tester.pumpAndSettle();

      // TableCalendar ウィジェットを取得して focusedDay を確認
      final calendar = tester.widget<TableCalendar>(find.byType(TableCalendar));
      expect(calendar.focusedDay.year, 2026);
      expect(calendar.focusedDay.month, 5);
    });
  });
}
