import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/household/household_notifier.dart';
import 'package:hw_hub_mobile/core/household/household_state.dart';
import 'package:hw_hub_mobile/core/models/household.dart';
import 'package:hw_hub_mobile/core/theme/app_theme.dart';
import 'package:hw_hub_mobile/features/tasks/data/my_tasks_repository.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_notifier.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_page.dart';
import 'package:hw_hub_mobile/features/tasks/presentation/my_tasks_state.dart';
import 'package:hw_hub_mobile/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/widget_test_helpers.dart';

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _today() => _dateStr(DateTime.now());
String _daysFromNow(int days) =>
    _dateStr(DateTime.now().add(Duration(days: days)));

HouseworkTaskDto _task({
  int id = 1,
  String? houseworkName,
  String? targetDate,
}) => HouseworkTaskDto(
  houseworkTaskId: id,
  householdId: 1,
  houseworkId: 1,
  houseworkName: houseworkName ?? 'タスク$id',
  targetDate: targetDate ?? _today(),
  assigneeUserId: 10,
  status: '0',
);

class _FakeMyTasksNotifier extends MyTasksNotifier {
  _FakeMyTasksNotifier(this._initialState);
  final MyTasksState _initialState;

  @override
  Future<MyTasksState> build() async => _initialState;
}

class _CompleterMyTasksNotifier extends MyTasksNotifier {
  _CompleterMyTasksNotifier(this._completer);
  final Completer<MyTasksState> _completer;

  @override
  Future<MyTasksState> build() => _completer.future;
}

class _ErrorMyTasksNotifier extends MyTasksNotifier {
  @override
  Future<MyTasksState> build() async => throw Exception('テストエラー');
}

class _FakeHouseholdNotifier extends HouseholdNotifier {
  _FakeHouseholdNotifier(this._state);
  final HouseholdState _state;

  @override
  Future<HouseholdState> build() async => _state;

  @override
  Future<void> select(Household household) async {}
}

List<Override> _overrides(MyTasksState myTasksState) => [
  myTasksNotifierProvider.overrideWith(
    () => _FakeMyTasksNotifier(myTasksState),
  ),
  householdNotifierProvider.overrideWith(
    () => _FakeHouseholdNotifier(
      const HouseholdState(households: [], selectedHousehold: null),
    ),
  ),
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MyTasksPage', () {
    testWidgets('ローディング中はCircularProgressIndicatorを表示する', (tester) async {
      final completer = Completer<MyTasksState>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myTasksNotifierProvider.overrideWith(
              () => _CompleterMyTasksNotifier(completer),
            ),
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(
                const HouseholdState(households: [], selectedHousehold: null),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const MyTasksPage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const MyTasksState());
      await tester.pumpAndSettle();
    });

    testWidgets('エラー時: エラーメッセージと再試行ボタンを表示する', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myTasksNotifierProvider.overrideWith(() => _ErrorMyTasksNotifier()),
            householdNotifierProvider.overrideWith(
              () => _FakeHouseholdNotifier(
                const HouseholdState(households: [], selectedHousehold: null),
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const MyTasksPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(TextButton), findsWidgets);
    });

    testWidgets('過去タスクが0件の場合: 過去の家事セクションが非表示になる', (tester) async {
      const state = MyTasksState(pastTasks: [], futureTasks: []);

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('過去の家事'), findsNothing);
    });

    testWidgets('過去タスクがある場合: 過去の家事セクションが表示される', (tester) async {
      final state = MyTasksState(
        pastTasks: [_task(id: 1, targetDate: _daysFromNow(-1))],
        futureTasks: [],
      );

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('過去の家事'), findsOneWidget);
    });

    testWidgets('これからの家事セクションが常に表示される', (tester) async {
      const state = MyTasksState(pastTasks: [], futureTasks: []);

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('これからの家事'), findsOneWidget);
    });

    testWidgets('フィルタタブ（すべて / 今日 / 1週間）が表示される', (tester) async {
      const state = MyTasksState(pastTasks: [], futureTasks: []);

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('今日'), findsOneWidget);
      expect(find.text('1週間'), findsOneWidget);
    });

    testWidgets('タスクカードが表示される', (tester) async {
      final state = MyTasksState(
        pastTasks: [],
        futureTasks: [_task(id: 1, houseworkName: '掃除機かけ')],
      );

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('掃除機かけ'), findsOneWidget);
    });

    testWidgets('タスクカードはDismissible（スワイプ操作可能）である', (tester) async {
      final state = MyTasksState(
        pastTasks: [],
        futureTasks: [_task(id: 1, houseworkName: '掃除機かけ')],
      );

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('掃除機かけ'), findsOneWidget);
      expect(find.byType(Dismissible), findsWidgets);
    });

    testWidgets('SwipeableTaskCardが存在しDismissibleが使われている', (tester) async {
      final state = MyTasksState(
        pastTasks: [],
        futureTasks: [_task(id: 1, houseworkName: '掃除機かけ')],
      );

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('掃除機かけ'), findsOneWidget);
      // Dismissibleはスワイプ操作を実現するウィジェット
      expect(find.byType(Dismissible), findsWidgets);
    });

    testWidgets('「すべて完了にする」ボタンが過去タスクセクションに表示される', (tester) async {
      final state = MyTasksState(
        pastTasks: [_task(id: 1, targetDate: _daysFromNow(-1))],
        futureTasks: [],
      );

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      expect(find.text('すべて完了にする'), findsOneWidget);
    });

    testWidgets('「すべて完了にする」タップで確認ダイアログが表示される', (tester) async {
      final state = MyTasksState(
        pastTasks: [_task(id: 1, targetDate: _daysFromNow(-1))],
        futureTasks: [],
      );

      await tester.pumpWidget(
        buildTestPage(const MyTasksPage(), overrides: _overrides(state)),
      );
      await tester.pump();

      await tester.tap(find.text('すべて完了にする'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });
}
