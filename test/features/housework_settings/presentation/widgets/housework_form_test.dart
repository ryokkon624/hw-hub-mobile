import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/housework_settings_repository.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_create/housework_create_state.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/widgets/housework_form.dart';

import '../../../../helpers/widget_test_helpers.dart';

const _defaultForm = HouseworkFormState();
const _defaultErrors = HouseworkFormErrors.empty;

const _member1 = HouseholdMemberDto(
  householdId: 10,
  userId: 1,
  displayName: '山田太郎',
  status: '1',
  role: 'OWNER',
);

Widget _buildForm({
  HouseworkFormState form = _defaultForm,
  List<HouseholdMemberDto> members = const [],
  HouseworkFormErrors errors = _defaultErrors,
  void Function(String)? onNameChanged,
  void Function(String)? onDescriptionChanged,
  void Function(String)? onCategoryChanged,
  void Function(String)? onRecurrenceTypeChanged,
  void Function(int)? onWeeklyDayToggled,
  void Function(int)? onDayOfMonthChanged,
  void Function(int)? onNthWeekChanged,
  void Function(int)? onWeekdayChanged,
  void Function(String)? onStartDateChanged,
  void Function(String)? onEndDateChanged,
  void Function(int?)? onAssigneeChanged,
}) {
  return buildTestPage(
    Scaffold(
      body: SingleChildScrollView(
        child: HouseworkForm(
          form: form,
          members: members,
          errors: errors,
          onNameChanged: onNameChanged ?? (_) {},
          onDescriptionChanged: onDescriptionChanged ?? (_) {},
          onCategoryChanged: onCategoryChanged ?? (_) {},
          onRecurrenceTypeChanged: onRecurrenceTypeChanged ?? (_) {},
          onWeeklyDayToggled: onWeeklyDayToggled ?? (_) {},
          onDayOfMonthChanged: onDayOfMonthChanged ?? (_) {},
          onNthWeekChanged: onNthWeekChanged ?? (_) {},
          onWeekdayChanged: onWeekdayChanged ?? (_) {},
          onStartDateChanged: onStartDateChanged ?? (_) {},
          onEndDateChanged: onEndDateChanged ?? (_) {},
          onAssigneeChanged: onAssigneeChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  group('HouseworkForm 基本要素', () {
    testWidgets('家事名フィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(find.byKey(const Key('houseworkNameField')), findsOneWidget);
    });

    testWidgets('説明フィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(
        find.byKey(const Key('houseworkDescriptionField')),
        findsOneWidget,
      );
    });

    testWidgets('カテゴリDropdownが表示される', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(
        find.byKey(const Key('houseworkCategoryDropdown')),
        findsOneWidget,
      );
    });

    testWidgets('周期タイプDropdownが表示される', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(
        find.byKey(const Key('houseworkRecurrenceTypeDropdown')),
        findsOneWidget,
      );
    });

    testWidgets('担当者Dropdownが表示される', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(
        find.byKey(const Key('houseworkAssigneeDropdown')),
        findsOneWidget,
      );
    });

    testWidgets('開始日フィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(find.byKey(const Key('houseworkStartDateField')), findsOneWidget);
    });

    testWidgets('終了日フィールドが表示される', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(find.byKey(const Key('houseworkEndDateField')), findsOneWidget);
    });
  });

  group('HouseworkForm 周期タイプ別表示', () {
    testWidgets('recurrenceType=1のとき WeeklyDaysSelector が表示される', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildForm(form: const HouseworkFormState(recurrenceType: '1')),
      );
      await tester.pump();

      // WeeklyDaysSelector内のFilterChipが表示される
      expect(find.byType(FilterChip), findsNWidgets(7));
    });

    testWidgets('recurrenceType=2のとき monthDaySelector が表示される', (tester) async {
      await tester.pumpWidget(
        _buildForm(form: const HouseworkFormState(recurrenceType: '2')),
      );
      await tester.pump();

      expect(find.byKey(const Key('monthDaySelector')), findsOneWidget);
    });

    testWidgets(
      'recurrenceType=3のとき nthWeekSelector/nthWeekdaySelector が表示される',
      (tester) async {
        await tester.pumpWidget(
          _buildForm(form: const HouseworkFormState(recurrenceType: '3')),
        );
        await tester.pump();

        expect(find.byKey(const Key('nthWeekSelector')), findsOneWidget);
        expect(find.byKey(const Key('nthWeekdaySelector')), findsOneWidget);
      },
    );
  });

  group('HouseworkForm バリデーションエラー', () {
    testWidgets('nameErrorがあるときエラーが表示される', (tester) async {
      await tester.pumpWidget(
        _buildForm(
          errors: const HouseworkFormErrors(
            nameError: 'houseworkCreateErrorNameRequired',
          ),
        ),
      );
      await tester.pump();

      // エラーテキストノードが表示される
      expect(find.byKey(const Key('houseworkNameField')), findsOneWidget);
    });

    testWidgets('weeklyDaysErrorがあるときエラーが表示される', (tester) async {
      await tester.pumpWidget(
        _buildForm(
          form: const HouseworkFormState(recurrenceType: '1'),
          errors: const HouseworkFormErrors(
            weeklyDaysError: 'houseworkCreateErrorWeeklyDaysRequired',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FilterChip), findsNWidgets(7));
    });
  });

  group('HouseworkForm メンバー選択', () {
    testWidgets('メンバーが存在する場合にDropdownに表示される', (tester) async {
      await tester.pumpWidget(_buildForm(members: [_member1]));
      await tester.pump();

      expect(
        find.byKey(const Key('houseworkAssigneeDropdown')),
        findsOneWidget,
      );
    });

    testWidgets('フォームに初期値が反映されている', (tester) async {
      await tester.pumpWidget(
        _buildForm(
          form: const HouseworkFormState(
            name: '初期家事名',
            startDate: '2025-06-01',
            endDate: '2099-12-31',
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('houseworkNameField')), findsOneWidget);
    });
  });
}
