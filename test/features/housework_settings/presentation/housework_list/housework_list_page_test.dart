import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hw_hub_mobile/features/housework_settings/data/models/housework_dto.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_notifier.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_page.dart';
import 'package:hw_hub_mobile/features/housework_settings/presentation/housework_list/housework_list_state.dart';

import '../../../../helpers/widget_test_helpers.dart';

// HouseworkListNotifier の FakeNotifier
class _FakeHouseworkListNotifier extends HouseworkListNotifier {
  _FakeHouseworkListNotifier(this._state);

  final HouseworkListState _state;

  @override
  Future<HouseworkListState> build() async => _state;
}

const _hw1 = HouseworkDto(
  houseworkId: 1,
  householdId: 10,
  name: '掃除機がけ',
  category: 'CLEAN',
  recurrenceType: '1',
  weeklyDays: 2,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

const _hw2 = HouseworkDto(
  houseworkId: 2,
  householdId: 10,
  name: '食器洗い',
  category: 'KITCHEN',
  recurrenceType: '1',
  weeklyDays: 127,
  startDate: '2025-01-01',
  endDate: '2099-12-31',
);

Widget _buildPage(HouseworkListState state) {
  return buildTestPageWithRouter(
    overrides: [
      houseworkListNotifierProvider.overrideWith(
        () => _FakeHouseworkListNotifier(state),
      ),
    ],
    routes: [GoRoute(path: '/', builder: (_, __) => const HouseworkListPage())],
  );
}

void main() {
  group('HouseworkListPage', () {
    testWidgets('houseworkListPageキーのScaffoldが表示される', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkListState(allHouseworks: [_hw1, _hw2])),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkListPage')), findsOneWidget);
    });

    testWidgets('家事一覧が表示される（2件）', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkListState(allHouseworks: [_hw1, _hw2])),
      );
      await tester.pumpAndSettle();

      expect(find.text('掃除機がけ'), findsOneWidget);
      expect(find.text('食器洗い'), findsOneWidget);
    });

    testWidgets('空リストの場合に家事カードが表示されない', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkListState()));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('家事を追加するボタンが表示される', (tester) async {
      await tester.pumpWidget(_buildPage(const HouseworkListState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('houseworkAddButton')), findsOneWidget);
    });

    testWidgets('カテゴリフィルタDropdownが表示される', (tester) async {
      await tester.pumpWidget(
        _buildPage(const HouseworkListState(allHouseworks: [_hw1])),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('categoryFilterDropdown')), findsOneWidget);
    });
  });
}
