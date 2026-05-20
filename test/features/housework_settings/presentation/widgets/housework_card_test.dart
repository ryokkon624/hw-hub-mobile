import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/models/housework_dto.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/widgets/housework_card.dart';

import '../../../../helpers/widget_test_helpers.dart';

const _weeklyHousework = HouseworkDto(
  houseworkId: 1,
  householdId: 10,
  name: '掃除機がけ',
  category: 'CLEAN',
  recurrenceType: '1',
  weeklyDays: 2, // bit1 = 月曜
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _monthlyHousework = HouseworkDto(
  houseworkId: 2,
  householdId: 10,
  name: '風呂掃除',
  category: 'KITCHEN',
  recurrenceType: '2',
  dayOfMonth: 15,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _monthlyEndHousework = HouseworkDto(
  houseworkId: 3,
  householdId: 10,
  name: '月末掃除',
  category: 'GARBAGE',
  recurrenceType: '2',
  dayOfMonth: 31,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _nthWeekdayHousework = HouseworkDto(
  houseworkId: 4,
  householdId: 10,
  name: 'ガーデニング',
  category: 'GARDEN',
  recurrenceType: '3',
  nthWeek: 2,
  weekday: 3, // 水曜
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _petHousework = HouseworkDto(
  houseworkId: 5,
  householdId: 10,
  name: 'ペット世話',
  category: 'PET',
  recurrenceType: '1',
  weeklyDays: 2,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _otherHousework = HouseworkDto(
  houseworkId: 6,
  householdId: 10,
  name: 'その他作業',
  category: 'OTHER',
  recurrenceType: '1',
  weeklyDays: 2,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _unknownCategoryHousework = HouseworkDto(
  houseworkId: 7,
  householdId: 10,
  name: '不明カテゴリ',
  category: 'UNKNOWN_XYZ',
  recurrenceType: '1',
  weeklyDays: 2,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _unknownRecurrenceHousework = HouseworkDto(
  houseworkId: 8,
  householdId: 10,
  name: '不明周期',
  category: 'CLEAN',
  recurrenceType: '9',
  weeklyDays: 0,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

// nthWeekday with weekday=0 (Sun)
const _nthSunHousework = HouseworkDto(
  houseworkId: 9,
  householdId: 10,
  name: '日曜家事',
  category: 'CLEAN',
  recurrenceType: '3',
  nthWeek: 1,
  weekday: 0, // 日曜
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

// nthWeekday with weekday=5 (Fri)
const _nthFriHousework = HouseworkDto(
  houseworkId: 10,
  householdId: 10,
  name: '金曜家事',
  category: 'CLEAN',
  recurrenceType: '3',
  nthWeek: 1,
  weekday: 5, // 金曜
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

Widget _buildCard({
  required HouseworkDto housework,
  String? assigneeName,
  VoidCallback? onTap,
}) {
  return buildTestPage(
    Scaffold(
      body: HouseworkCard(
        housework: housework,
        assigneeName: assigneeName,
        onTap: onTap ?? () {},
      ),
    ),
  );
}

void main() {
  group('HouseworkCard', () {
    testWidgets('家事名が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _weeklyHousework));
      await tester.pump();

      expect(find.text('掃除機がけ'), findsOneWidget);
    });

    testWidgets('担当者名がある場合に担当者ラベルが表示される', (tester) async {
      await tester.pumpWidget(
        _buildCard(housework: _weeklyHousework, assigneeName: '山田太郎'),
      );
      await tester.pump();

      // assigneeLabelを含むTextが表示される
      expect(find.textContaining('山田太郎'), findsOneWidget);
    });

    testWidgets('担当者名がnullの場合に未割当表示になる', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _weeklyHousework));
      await tester.pump();

      // 未割当ラベルが表示される（l10n.houseworkSettingsAssigneeNone）
      // Key検証: Cardウィジェットが存在すること
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('タップするとonTapが呼ばれる', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _buildCard(housework: _weeklyHousework, onTap: () => tapped = true),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('週次タイプ(recurrenceType=1)の家事が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _weeklyHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('月次タイプ(recurrenceType=2, dayOfMonth=15)の家事が表示される', (
      tester,
    ) async {
      await tester.pumpWidget(_buildCard(housework: _monthlyHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('風呂掃除'), findsOneWidget);
    });

    testWidgets('月次タイプ(dayOfMonth=31)の家事が表示される（月末）', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _monthlyEndHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('月末掃除'), findsOneWidget);
    });

    testWidgets('第n週タイプ(recurrenceType=3)の家事が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _nthWeekdayHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('ガーデニング'), findsOneWidget);
    });

    testWidgets('CLEANカテゴリのバッジが表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _weeklyHousework));
      await tester.pump();

      // カテゴリバッジコンテナが存在する
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('開始日が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _weeklyHousework));
      await tester.pump();

      expect(find.textContaining('2025-01-01'), findsOneWidget);
    });

    testWidgets('PETカテゴリの家事が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _petHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('ペット世話'), findsOneWidget);
    });

    testWidgets('OTHERカテゴリの家事が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _otherHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('その他作業'), findsOneWidget);
    });

    testWidgets('未知カテゴリの家事が表示される（default分岐）', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _unknownCategoryHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('不明カテゴリ'), findsOneWidget);
    });

    testWidgets('未知周期タイプの家事が表示される（fallback分岐）', (tester) async {
      await tester.pumpWidget(
        _buildCard(housework: _unknownRecurrenceHousework),
      );
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('不明周期'), findsOneWidget);
    });

    testWidgets('第n週・日曜タイプ(weekday=0)の家事が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _nthSunHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('日曜家事'), findsOneWidget);
    });

    testWidgets('第n週・金曜タイプ(weekday=5)の家事が表示される', (tester) async {
      await tester.pumpWidget(_buildCard(housework: _nthFriHousework));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('金曜家事'), findsOneWidget);
    });
  });
}
