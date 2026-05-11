import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/auth/auth_providers.dart';
import 'package:hw_hub_mobile/features/auth/data/models/invitation_info.dart';
import 'package:hw_hub_mobile/features/auth/presentation/invitation/invitation_notifier.dart';

import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth_mocks.mocks.dart';
import '../../../../helpers/mocks.mocks.dart';

void main() {
  late MockAuthRepository mockRepo;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockStorage = MockFlutterSecureStorage();
    SharedPreferences.setMockInitialValues({});
    when(mockStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
    ).thenAnswer((_) async {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  ProviderContainer makeContainer(String token) {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(mockStorage),
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('InvitationNotifier', () {
    test('build() 成功で招待情報がロードされる', () async {
      when(mockRepo.getInvitation(token: anyNamed('token'))).thenAnswer(
        (_) async => const InvitationInfo(
          householdName: '田中家',
          inviterName: '田中 太郎',
          invitedEmail: 'user@example.com',
        ),
      );

      final container = makeContainer('valid-token');
      final state = await container.read(
        invitationNotifierProvider('valid-token').future,
      );
      expect(state.invitationInfo?.householdName, '田中家');
      expect(state.isLoading, false);
    });

    test('build() エラーでerror状態になる', () async {
      when(
        mockRepo.getInvitation(token: anyNamed('token')),
      ).thenThrow(const NetworkException());

      final container = makeContainer('bad-token');
      try {
        await container.read(invitationNotifierProvider('bad-token').future);
      } catch (_) {
        // build()がthrowした場合
      }
      expect(
        container.read(invitationNotifierProvider('bad-token')).hasError,
        true,
      );
    });

    test('accept() 成功でacceptedがtrue', () async {
      when(mockRepo.getInvitation(token: anyNamed('token'))).thenAnswer(
        (_) async => const InvitationInfo(
          householdName: '田中家',
          inviterName: '田中 太郎',
          invitedEmail: 'user@example.com',
        ),
      );
      when(
        mockRepo.acceptInvitation(token: anyNamed('token')),
      ).thenAnswer((_) async {});

      final container = makeContainer('valid-token');
      await container.read(invitationNotifierProvider('valid-token').future);
      await container
          .read(invitationNotifierProvider('valid-token').notifier)
          .accept();

      final state = container
          .read(invitationNotifierProvider('valid-token'))
          .value!;
      expect(state.accepted, true);
    });

    test('accept() エラーでerrorMessageがセットされisActingがfalse', () async {
      when(mockRepo.getInvitation(token: anyNamed('token'))).thenAnswer(
        (_) async => const InvitationInfo(
          householdName: '田中家',
          inviterName: '田中 太郎',
          invitedEmail: 'user@example.com',
        ),
      );
      when(
        mockRepo.acceptInvitation(token: anyNamed('token')),
      ).thenThrow(const NetworkException());

      final container = makeContainer('valid-token');
      await container.read(invitationNotifierProvider('valid-token').future);
      await container
          .read(invitationNotifierProvider('valid-token').notifier)
          .accept();

      final state = container
          .read(invitationNotifierProvider('valid-token'))
          .value!;
      expect(state.errorMessage, isNotNull);
      expect(state.accepted, false);
      expect(state.isActing, false);
    });

    test('decline() エラーでerrorMessageがセットされisActingがfalse', () async {
      when(mockRepo.getInvitation(token: anyNamed('token'))).thenAnswer(
        (_) async => const InvitationInfo(
          householdName: '田中家',
          inviterName: '田中 太郎',
          invitedEmail: 'user@example.com',
        ),
      );
      when(
        mockRepo.declineInvitation(token: anyNamed('token')),
      ).thenThrow(const NetworkException());

      final container = makeContainer('valid-token');
      await container.read(invitationNotifierProvider('valid-token').future);
      await container
          .read(invitationNotifierProvider('valid-token').notifier)
          .decline();

      final state = container
          .read(invitationNotifierProvider('valid-token'))
          .value!;
      expect(state.errorMessage, isNotNull);
      expect(state.declined, false);
      expect(state.isActing, false);
    });

    test('decline() 成功でdeclinedがtrue', () async {
      when(mockRepo.getInvitation(token: anyNamed('token'))).thenAnswer(
        (_) async => const InvitationInfo(
          householdName: '田中家',
          inviterName: '田中 太郎',
          invitedEmail: 'user@example.com',
        ),
      );
      when(
        mockRepo.declineInvitation(token: anyNamed('token')),
      ).thenAnswer((_) async {});

      final container = makeContainer('valid-token');
      await container.read(invitationNotifierProvider('valid-token').future);
      await container
          .read(invitationNotifierProvider('valid-token').notifier)
          .decline();

      final state = container
          .read(invitationNotifierProvider('valid-token'))
          .value!;
      expect(state.declined, true);
    });
  });
}
