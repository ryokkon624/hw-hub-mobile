import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/features/auth/data/models/invitation_info.dart';
import 'package:hw_hub_mobile/features/auth/presentation/invitation/invitation_notifier.dart';
import 'package:hw_hub_mobile/features/auth/presentation/invitation/invitation_page.dart';
import 'package:hw_hub_mobile/features/auth/presentation/invitation/invitation_state.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/mocks.mocks.dart';
import '../../../../helpers/widget_test_helpers.dart';

class _LoadingInvitationNotifier extends InvitationNotifier {
  // Completer を使うことでタイマーを作らずに未完了の Future を提供する
  @override
  Future<InvitationState> build(String arg) => Completer<InvitationState>().future;
}

class _DataInvitationNotifier extends InvitationNotifier {
  @override
  Future<InvitationState> build(String arg) async => const InvitationState(
        invitationInfo: InvitationInfo(
          householdName: 'テスト家',
          inviterName: 'テスト太郎',
          invitedEmail: 'invited@example.com',
        ),
      );
}

void main() {
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    SharedPreferences.setMockInitialValues({});
    // トークンなし → AuthUnauthenticated
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
        .thenAnswer((_) async {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  group('InvitationPage', () {
    testWidgets('招待情報ロード中はCircularProgressIndicatorが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const InvitationPage(token: 'test-token'),
        overrides: [
          invitationNotifierProvider.overrideWith(() => _LoadingInvitationNotifier()),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      ));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('招待情報ロード後（未ログイン）: 招待ヘッダーとログインボタンが表示される', (tester) async {
      await tester.pumpWidget(buildTestPage(
        const InvitationPage(token: 'test-token'),
        overrides: [
          invitationNotifierProvider.overrideWith(() => _DataInvitationNotifier()),
          secureStorageProvider.overrideWithValue(mockStorage),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('おうちへの招待が届いています。'), findsOneWidget);
      expect(find.text('テスト家'), findsOneWidget);
      expect(find.text('ログインして参加する'), findsOneWidget);
    });
  });
}
