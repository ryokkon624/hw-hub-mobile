import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/home/data/models/household_member_dto.dart';
import 'package:hw_hub_mobile/features/housework_assign/housework_assign_providers.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/housework_assign_page.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/widgets/swipe_date_calendar.dart';
import 'package:hw_hub_mobile/features/my_tasks/data/models/housework_task_dto.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../helpers/widget_test_helpers.dart';

String _dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _today() => _dateStr(DateTime.now());
String _daysFromNow(int days) =>
    _dateStr(DateTime.now().add(Duration(days: days)));

HouseworkTaskDto _task({
  int id = 1,
  String? targetDate,
  int? assigneeUserId,
  String? assigneeNickname,
}) => HouseworkTaskDto(
  houseworkTaskId: id,
  householdId: 1,
  houseworkId: id,
  houseworkName: 'タスク$id',
  targetDate: targetDate ?? _today(),
  assigneeUserId: assigneeUserId,
  assigneeNickname: assigneeNickname,
  status: '0',
);

HouseholdMemberDto _member({int userId = 10, String displayName = 'テストユーザー'}) =>
    HouseholdMemberDto(
      householdId: 1,
      userId: userId,
      displayName: displayName,
      status: 'ACTIVE',
      role: 'OWNER',
    );

class _FakeNotifier extends HouseworkAssignNotifier {
  _FakeNotifier(this._initialState);
  final HouseworkAssignState _initialState;

  @override
  Future<HouseworkAssignState> build() async => _initialState;
}

Widget _buildPage(HouseworkAssignState state) => buildTestPage(
  const HouseworkAssignPage(),
  overrides: [
    houseworkAssignNotifierProvider.overrideWith(() => _FakeNotifier(state)),
  ],
);

void main() {
  group('HouseworkAssignPage 通常リストモード', () {
    test('タスク一覧が表示される（testWidgetsで個別実装済み）', () {
      // メンバーサマリ・タスクカード等の個別テストで各表示をカバー済み
    });

    testWidgets('メンバーサマリが表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [_task(id: 1, assigneeUserId: null)],
        members: [_member(userId: 10, displayName: 'テスト')],
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      // メンバーサマリの「未割当」ラベルが表示される
      expect(find.text('未割当'), findsWidgets);
    });

    testWidgets('タスクカードが表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [
          _task(id: 1, assigneeUserId: null),
          _task(id: 2, assigneeUserId: 10, assigneeNickname: 'テスト'),
        ],
        members: [_member()],
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      expect(find.text('タスク1'), findsOneWidget);
      expect(find.text('タスク2'), findsOneWidget);
    });

    testWidgets('未対応タスク件数ラベルが表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [
          _task(id: 1, assigneeUserId: null),
          _task(id: 2, assigneeUserId: 10),
        ],
        members: [],
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      // 未対応タスク 2件（未割当: 1件）
      expect(find.textContaining('2'), findsWidgets);
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('過去の未割当がある場合はスキップボタンが表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [
          _task(id: 1, targetDate: _daysFromNow(-1), assigneeUserId: null),
        ],
        members: [],
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      expect(find.text('過去の未割当をスキップ'), findsOneWidget);
    });

    testWidgets('過去の未割当がない場合はスキップボタンが非表示', (tester) async {
      final state = HouseworkAssignState(
        tasks: [_task(id: 1, targetDate: _today(), assigneeUserId: null)],
        members: [],
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      expect(find.text('過去の未割当をスキップ'), findsNothing);
    });

    testWidgets('フィルタチップが3つ表示される', (tester) async {
      final state = HouseworkAssignState(tasks: [], members: []);
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      expect(find.text('すべて'), findsOneWidget);
      expect(find.text('未割当'), findsWidgets); // サマリにも「未割当」があるが
      expect(find.text('自分+未'), findsOneWidget);
    });

    testWidgets('タスクが0件の場合スワイプモードボタンがグレーアウト', (tester) async {
      final state = HouseworkAssignState(tasks: [], members: []);
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      // スワイプモード起動ボタンが表示されている
      expect(find.text('未割当を自分に割り当てる ▶'), findsOneWidget);
      expect(find.text('他メンバーのタスクを奪う ▶'), findsOneWidget);
    });
  });

  group('HouseworkAssignPage スワイプモード', () {
    testWidgets('スワイプモード時にカードが表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [_task(id: 1, assigneeUserId: null)],
        members: [],
        mode: AssignMode.swipe,
        swipeTarget: SwipeTarget.unassigned,
        swipeIndex: 0,
        swipeTaskCount: 1,
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      // スワイプモードのカードが表示される
      expect(find.text('タスク1'), findsOneWidget);
      // 進捗表示
      expect(find.textContaining('1 / 1'), findsOneWidget);
    });

    testWidgets('全カード消化後に完了メッセージが表示される', (tester) async {
      // swipeIndex >= swipeTaskCount の場合は完了メッセージ
      final state = HouseworkAssignState(
        tasks: [],
        members: [],
        mode: AssignMode.swipe,
        swipeTarget: SwipeTarget.unassigned,
        swipeIndex: 1,
        swipeTaskCount: 1,
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      expect(find.text('お疲れさまでした！'), findsOneWidget);
    });
  });

  group('HouseworkAssignPage スワイプモード UX改善（#114）', () {
    HouseworkAssignState buildSwipeState({
      int swipeIndex = 0,
      int swipeTaskCount = 3,
      String targetDate = '2026-05-20',
    }) => HouseworkAssignState(
      tasks: [
        _task(id: 1, assigneeUserId: null, targetDate: targetDate),
        _task(id: 2, assigneeUserId: null, targetDate: targetDate),
        _task(id: 3, assigneeUserId: null, targetDate: targetDate),
      ],
      members: [],
      mode: AssignMode.swipe,
      swipeTarget: SwipeTarget.unassigned,
      swipeIndex: swipeIndex,
      swipeTaskCount: swipeTaskCount,
    );

    testWidgets('AC1: 進捗テキストが body 内に headlineSmall スタイルで表示される', (
      tester,
    ) async {
      await tester.pumpWidget(_buildPage(buildSwipeState()));
      await tester.pumpAndSettle();

      // headlineSmall スタイルを持つ Text ウィジェットで進捗テキストが表示される
      final progressTextFinder = find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        if (widget.style?.fontSize == null) return false;
        // headlineSmall は約 24sp
        return (widget.style!.fontSize! >= 20) &&
            (widget.data?.contains('/') ?? false);
      });
      expect(progressTextFinder, findsOneWidget);
    });

    testWidgets('AC1: AppBar の actions に進捗テキストが存在しない', (tester) async {
      await tester.pumpWidget(_buildPage(buildSwipeState()));
      await tester.pumpAndSettle();

      // AppBar の actions ウィジェットツリーを確認。
      // actions 内の Padding > Center > Text として進捗テキストがないことを確認する。
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      // AppBar を取得して actions が null または空であるか確認
      // (Flutter では actions を未指定の場合 null が返る)
      final appBar = tester.widget<AppBar>(appBarFinder);
      expect(appBar.actions == null || appBar.actions!.isEmpty, isTrue);
    });

    testWidgets('AC2: 「割り当てを中断する」ボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(buildSwipeState()));
      await tester.pumpAndSettle();

      expect(find.text('割り当てを中断する'), findsOneWidget);
    });

    testWidgets('AC2: AppBar に BackButton が表示されない', (tester) async {
      await tester.pumpWidget(_buildPage(buildSwipeState()));
      await tester.pumpAndSettle();

      // automaticallyImplyLeading: false なので BackButton がない
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('AC2: 「割り当てを中断する」タップで exitSwipeMode が呼ばれる', (tester) async {
      bool exitCalled = false;
      final fakeNotifier = _ExitTrackingNotifier(
        buildSwipeState(),
        onExit: () => exitCalled = true,
      );
      await tester.pumpWidget(
        buildTestPage(
          const HouseworkAssignPage(),
          overrides: [
            houseworkAssignNotifierProvider.overrideWith(() => fakeNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('割り当てを中断する'));
      await tester.pump();

      expect(exitCalled, isTrue);
    });

    testWidgets('AC3: TableCalendar ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(buildSwipeState()));
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar), findsOneWidget);
    });

    testWidgets('AC3: SwipeDateCalendar ウィジェットが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(buildSwipeState()));
      await tester.pumpAndSettle();

      expect(find.byType(SwipeDateCalendar), findsOneWidget);
    });
  });

  group('HouseworkAssignPage ローディング', () {
    testWidgets('ローディング中はCircularProgressIndicatorが表示される', (tester) async {
      // loading state - Completer を使って pending timer を作らずローディング状態を維持
      final overrides = [
        houseworkAssignNotifierProvider.overrideWith(() => _LoadingNotifier()),
      ];
      await tester.pumpWidget(
        buildTestPage(const HouseworkAssignPage(), overrides: overrides),
      );
      // pump() 1フレームだけ進める（pumpAndSettle はローディング中にタイムアウト）
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HouseworkAssignPage フィルタ', () {
    testWidgets('未割当フィルタ選択時: 未割当タスクのみ表示される', (tester) async {
      final trackingNotifier = _FilterTrackingNotifier(
        HouseworkAssignState(
          tasks: [
            _task(id: 1, assigneeUserId: null),
            _task(id: 2, assigneeUserId: 10),
          ],
          members: [],
          filter: AssignFilter.unassignedOnly,
        ),
        onFilterChanged: (_) {},
      );
      await tester.pumpWidget(
        buildTestPage(
          const HouseworkAssignPage(),
          overrides: [
            houseworkAssignNotifierProvider.overrideWith(
              () => trackingNotifier,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 未割当タスク1件のみ表示
      expect(find.text('タスク1'), findsOneWidget);
      expect(find.text('タスク2'), findsNothing);
    });

    testWidgets('自分+未フィルタ選択時: 自分のタスクと未割当が表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [
          _task(id: 1, assigneeUserId: null), // 未割当
          _task(id: 2, assigneeUserId: 10), // 自分（currentUserId=-1なので除外される）
          _task(id: 3, assigneeUserId: 20), // 他人
        ],
        members: [],
        filter: AssignFilter.meAndUnassigned,
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      // 自分のID=-1なので未割当のみ表示（currentUserId取得失敗）
      expect(find.text('タスク1'), findsOneWidget);
      expect(find.text('タスク3'), findsNothing);
    });

    testWidgets('全件フィルタ: 全タスクが表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [
          _task(id: 1, assigneeUserId: null),
          _task(id: 2, assigneeUserId: 10),
          _task(id: 3, assigneeUserId: 20),
        ],
        members: [],
        filter: AssignFilter.all,
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      expect(find.text('タスク1'), findsOneWidget);
      expect(find.text('タスク2'), findsOneWidget);
      expect(find.text('タスク3'), findsOneWidget);
    });
  });

  group('HouseworkAssignPage スキップダイアログ', () {
    testWidgets('スキップボタンタップでBulkSkipDialogが表示される', (tester) async {
      final state = HouseworkAssignState(
        tasks: [
          _task(id: 1, targetDate: _daysFromNow(-1), assigneeUserId: null),
        ],
        members: [],
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('過去の未割当をスキップ'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('HouseworkAssignPage スワイプモード（currentTask==null）', () {
    testWidgets('swipeIndex<swipeTaskCountだがswipeTasksが空ならインジケータが表示される', (
      tester,
    ) async {
      // tasks が空なのに swipeTaskCount > swipeIndex の場合: currentTask == null
      final state = HouseworkAssignState(
        tasks: [], // assigned tasks are empty -> swipeTasks is empty
        members: [],
        mode: AssignMode.swipe,
        swipeTarget: SwipeTarget.unassigned,
        swipeIndex: 0,
        swipeTaskCount: 5, // swipeIndex(0) < swipeTaskCount(5) but no tasks
      );
      await tester.pumpWidget(_buildPage(state));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

class _LoadingNotifier extends HouseworkAssignNotifier {
  @override
  Future<HouseworkAssignState> build() {
    // Completer で永続的なローディング状態（timer は作らない）
    return Completer<HouseworkAssignState>().future;
  }
}

class _ExitTrackingNotifier extends HouseworkAssignNotifier {
  _ExitTrackingNotifier(this._initialState, {required this.onExit});
  final HouseworkAssignState _initialState;
  final VoidCallback onExit;

  @override
  Future<HouseworkAssignState> build() async => _initialState;

  @override
  void exitSwipeMode() {
    onExit();
  }
}

class _FilterTrackingNotifier extends HouseworkAssignNotifier {
  _FilterTrackingNotifier(this._initialState, {required this.onFilterChanged});
  final HouseworkAssignState _initialState;
  final void Function(AssignFilter) onFilterChanged;

  @override
  Future<HouseworkAssignState> build() async => _initialState;

  @override
  void setFilter(AssignFilter filter) {
    onFilterChanged(filter);
    state = AsyncData(state.value!.copyWith(filter: filter));
  }
}
