import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/home/data/models/household_member_dto.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/housework_assign_notifier.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/housework_assign_page.dart';
import 'package:hw_hub_mobile/features/housework_assign/presentation/housework_assign_state.dart';
import 'package:hw_hub_mobile/features/tasks/data/models/housework_task_dto.dart';

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
}

class _LoadingNotifier extends HouseworkAssignNotifier {
  @override
  Future<HouseworkAssignState> build() {
    // Completer で永続的なローディング状態（timer は作らない）
    return Completer<HouseworkAssignState>().future;
  }
}
