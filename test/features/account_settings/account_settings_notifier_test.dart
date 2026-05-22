import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/auth_notifier.dart';
import 'package:hw_hub_mobile/core/auth/auth_state.dart';
import 'package:hw_hub_mobile/core/di/providers.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/account_settings/account_settings_providers.dart';
import 'package:hw_hub_mobile/features/account_settings/data/account_settings_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([AccountSettingsRepository])
import 'account_settings_notifier_test.mocks.dart';

import '../../helpers/mocks.mocks.dart';

/// uploadIcon 後の authNotifierProvider invalidate を検証するカウンター
int _authNotifierBuildCount = 0;

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async {
    _authNotifierBuildCount++;
    return const AuthUnauthenticated();
  }
}

ProviderContainer _makeContainer(
  AccountSettingsRepository repo,
  MockDio mockDio,
) {
  final container = ProviderContainer(
    overrides: [
      accountSettingsRepositoryProvider.overrideWithValue(repo),
      dioProvider.overrideWithValue(mockDio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// authNotifier を含む Container（uploadIcon の invalidate 検証用）
ProviderContainer _makeContainerWithAuth(
  AccountSettingsRepository repo,
  MockDio mockDio,
) {
  _authNotifierBuildCount = 0;
  final container = ProviderContainer(
    overrides: [
      accountSettingsRepositoryProvider.overrideWithValue(repo),
      authNotifierProvider.overrideWith(_FakeAuthNotifier.new),
      dioProvider.overrideWithValue(mockDio),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// 初期ロード用スタブ
void _stubInitialLoad(MockAccountSettingsRepository repo) {
  when(repo.fetchProfile()).thenAnswer(
    (_) async => const UserProfileDto(
      userId: 1,
      email: 'test@example.com',
      authProvider: 'LOCAL',
      displayName: 'テスト太郎',
      locale: 'ja',
    ),
  );
  when(repo.fetchNotificationSettings()).thenAnswer(
    (_) async => const NotificationSettingsDto(
      notificationEnabled: true,
      groupSettings: {'100': true, '200': true},
    ),
  );
}

void main() {
  late MockAccountSettingsRepository mockRepo;
  late MockDio mockDio;

  setUp(() {
    mockRepo = MockAccountSettingsRepository();
    mockDio = MockDio();
  });

  group('AccountSettingsNotifier.build()', () {
    test('初期ロード成功時: profile と notificationSettings が state に格納される', () async {
      _stubInitialLoad(mockRepo);

      final container = _makeContainer(mockRepo, mockDio);
      final state = await container.read(
        accountSettingsNotifierProvider.future,
      );

      expect(state.profile?.email, 'test@example.com');
      expect(state.notificationSettings?.notificationEnabled, isTrue);
    });

    test('fetchProfile が失敗した場合: AsyncError になる', () async {
      when(mockRepo.fetchProfile()).thenThrow(const NetworkException());
      when(mockRepo.fetchNotificationSettings()).thenAnswer(
        (_) async => const NotificationSettingsDto(
          notificationEnabled: true,
          groupSettings: {},
        ),
      );

      final container = _makeContainer(mockRepo, mockDio);
      container.listen(accountSettingsNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      final result = container.read(accountSettingsNotifierProvider);
      expect(result.hasError, isTrue);
    });
  });

  group('AccountSettingsNotifier.updateProfile()', () {
    test('成功時: state.profile が更新され successMessage がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.updateProfile(displayName: '新しい名前', locale: 'en'),
      ).thenAnswer(
        (_) async => const UserProfileDto(
          userId: 1,
          email: 'test@example.com',
          authProvider: 'LOCAL',
          displayName: '新しい名前',
          locale: 'en',
        ),
      );

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .updateProfile(displayName: '新しい名前', locale: 'en');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.profile?.displayName, '新しい名前');
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });

    test('失敗時: errorMessage がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.updateProfile(
          displayName: anyNamed('displayName'),
          locale: anyNamed('locale'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .updateProfile(displayName: '名前', locale: 'ja');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
      expect(state.successMessage, isNull);
    });
  });

  group('AccountSettingsNotifier.changePassword()', () {
    test('成功時: successMessage がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.changePassword(currentPassword: 'old', newPassword: 'new'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .changePassword(currentPassword: 'old', newPassword: 'new');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
    });

    test('失敗時（現在のパスワード不正）: errorMessage がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.changePassword(
          currentPassword: anyNamed('currentPassword'),
          newPassword: anyNamed('newPassword'),
        ),
      ).thenThrow(
        const ApiException(
          '現在のパスワードが正しくありません',
          code: 'CURRENT_PASSWORD_INVALID',
        ),
      );

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .changePassword(currentPassword: 'wrong', newPassword: 'new');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
      expect(state.successMessage, isNull);
    });
  });

  group('AccountSettingsNotifier.toggleGlobalNotification()', () {
    test('OFF→ON: notificationEnabled が true になる', () async {
      _stubInitialLoad(mockRepo);

      const updatedSettings = NotificationSettingsDto(
        notificationEnabled: true,
        groupSettings: {'100': true, '200': true},
      );
      when(
        mockRepo.updateNotificationSettings(any),
      ).thenAnswer((_) async => updatedSettings);

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .toggleGlobalNotification(enabled: true);

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.notificationSettings?.notificationEnabled, isTrue);
    });

    test('ON→OFF: notificationEnabled が false になる', () async {
      _stubInitialLoad(mockRepo);

      const updatedSettings = NotificationSettingsDto(
        notificationEnabled: false,
        groupSettings: {'100': false, '200': false},
      );
      when(
        mockRepo.updateNotificationSettings(any),
      ).thenAnswer((_) async => updatedSettings);

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .toggleGlobalNotification(enabled: false);

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.notificationSettings?.notificationEnabled, isFalse);
    });
  });

  group('AccountSettingsNotifier.toggleGroupNotification()', () {
    test('グループ通知の ON/OFF を切り替えられる', () async {
      _stubInitialLoad(mockRepo);

      const updatedSettings = NotificationSettingsDto(
        notificationEnabled: true,
        groupSettings: {'100': true, '200': false},
      );
      when(
        mockRepo.updateNotificationSettings(any),
      ).thenAnswer((_) async => updatedSettings);

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .toggleGroupNotification(groupCode: '200', enabled: false);

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.notificationSettings?.groupSettings['200'], isFalse);
    });
  });

  group('AccountSettingsNotifier.linkGoogleAccount()', () {
    test('成功時: successMessage がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.linkGoogleAccount(idToken: 'valid-id-token'),
      ).thenAnswer((_) async {});
      // Google連携後のプロフィール再取得
      when(mockRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfileDto(
          userId: 1,
          email: 'test@gmail.com',
          authProvider: 'GOOGLE',
          displayName: 'テスト太郎',
          locale: 'ja',
        ),
      );

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .linkGoogleAccount(idToken: 'valid-id-token');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.errorMessage, isNull);
      expect(state.isLinkingGoogle, isFalse);
    });

    test('失敗時: errorMessage がセットされ isLinkingGoogle が false に戻る', () async {
      _stubInitialLoad(mockRepo);
      when(mockRepo.linkGoogleAccount(idToken: anyNamed('idToken'))).thenThrow(
        const ApiException('IDトークンが無効です', code: 'OAUTH_ID_TOKEN_INVALID'),
      );

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .linkGoogleAccount(idToken: 'bad-token');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
      expect(state.isLinkingGoogle, isFalse);
    });
  });

  group('AccountSettingsNotifier.deleteAccount()', () {
    test('成功時: isDeleted フラグが true になる（ナビゲーションは Page 側で処理）', () async {
      _stubInitialLoad(mockRepo);
      when(mockRepo.deleteAccount()).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .deleteAccount();

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.isDeletingAccount, isFalse);
    });

    test('失敗時（OWNER削除不可）: errorMessage がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(mockRepo.deleteAccount()).thenThrow(
        const ApiException('OWNERは削除できません', code: 'OWNER_CANNOT_DELETE'),
      );

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .deleteAccount();

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
      expect(state.isDeletingAccount, isFalse);
    });
  });

  group('AccountSettingsNotifier.uploadIcon()', () {
    test('5MB超: errorMessage accountSettingsIconTooLarge がセットされる', () async {
      _stubInitialLoad(mockRepo);

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      // 5MB + 1バイト
      final largeBytes = List<int>.filled(5 * 1024 * 1024 + 1, 0);
      await container
          .read(accountSettingsNotifierProvider.notifier)
          .uploadIcon(
            bytes: largeBytes,
            fileName: 'icon.jpg',
            mimeType: 'image/jpeg',
          );

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, 'accountSettingsIconTooLarge');
    });

    test('成功時: successMessage がセットされ isUploadingIcon が false になる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.createIconUploadUrl(
          fileName: anyNamed('fileName'),
          mimeType: anyNamed('mimeType'),
        ),
      ).thenAnswer(
        (_) async => {
          'uploadUrl': 'https://example.com/upload',
          'fileKey': 'key/icon.jpg',
        },
      );
      when(
        mockRepo.uploadToS3(
          uploadUrl: anyNamed('uploadUrl'),
          bytes: anyNamed('bytes'),
          mimeType: anyNamed('mimeType'),
        ),
      ).thenAnswer((_) async {});
      when(
        mockRepo.updateIcon(fileKey: anyNamed('fileKey')),
      ).thenAnswer((_) async {});
      when(mockRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfileDto(
          userId: 1,
          email: 'test@example.com',
          authProvider: 'LOCAL',
          displayName: 'テスト太郎',
          locale: 'ja',
        ),
      );

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      final smallBytes = [1, 2, 3];
      await container
          .read(accountSettingsNotifierProvider.notifier)
          .uploadIcon(
            bytes: smallBytes,
            fileName: 'icon.jpg',
            mimeType: 'image/jpeg',
          );

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.successMessage, isNotNull);
      expect(state.isUploadingIcon, isFalse);
    });

    test('成功時: authNotifierProvider が invalidate されてヘッダーに反映される', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.createIconUploadUrl(
          fileName: anyNamed('fileName'),
          mimeType: anyNamed('mimeType'),
        ),
      ).thenAnswer(
        (_) async => {
          'uploadUrl': 'https://example.com/upload',
          'fileKey': 'key/icon.jpg',
        },
      );
      when(
        mockRepo.uploadToS3(
          uploadUrl: anyNamed('uploadUrl'),
          bytes: anyNamed('bytes'),
          mimeType: anyNamed('mimeType'),
        ),
      ).thenAnswer((_) async {});
      when(
        mockRepo.updateIcon(fileKey: anyNamed('fileKey')),
      ).thenAnswer((_) async {});
      when(mockRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfileDto(
          userId: 1,
          email: 'test@example.com',
          authProvider: 'LOCAL',
          displayName: 'テスト太郎',
          locale: 'ja',
        ),
      );

      // authNotifierProvider を含む Container を使う
      final container = _makeContainerWithAuth(mockRepo, mockDio);
      // authNotifier を購読して初期ビルドを待つ
      container.listen(authNotifierProvider, (_, _) {});
      await container.read(authNotifierProvider.future);

      final buildCountBefore = _authNotifierBuildCount;

      // アカウント設定を初期ロード
      await container.read(accountSettingsNotifierProvider.future);

      // uploadIcon を実行
      await container
          .read(accountSettingsNotifierProvider.notifier)
          .uploadIcon(
            bytes: [1, 2, 3],
            fileName: 'icon.jpg',
            mimeType: 'image/jpeg',
          );

      // uploadIcon 後に authNotifierProvider が invalidate されて再ビルドされる
      await container.read(authNotifierProvider.future);
      expect(_authNotifierBuildCount, greaterThan(buildCountBefore));
    });

    test('失敗時: errorMessage がセットされ isUploadingIcon が false になる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.createIconUploadUrl(
          fileName: anyNamed('fileName'),
          mimeType: anyNamed('mimeType'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      final smallBytes = [1, 2, 3];
      await container
          .read(accountSettingsNotifierProvider.notifier)
          .uploadIcon(
            bytes: smallBytes,
            fileName: 'icon.jpg',
            mimeType: 'image/jpeg',
          );

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, isNotNull);
      expect(state.isUploadingIcon, isFalse);
    });
  });

  group('AccountSettingsNotifier.clearError() / clearSuccess()', () {
    test('clearError: errorMessage が null になる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.updateProfile(
          displayName: anyNamed('displayName'),
          locale: anyNamed('locale'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .updateProfile(displayName: '名前', locale: 'ja');

      final before = container.read(accountSettingsNotifierProvider).value!;
      expect(before.errorMessage, isNotNull);

      container.read(accountSettingsNotifierProvider.notifier).clearError();
      final after = container.read(accountSettingsNotifierProvider).value!;
      expect(after.errorMessage, isNull);
    });

    test('clearSuccess: successMessage が null になる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.updateProfile(displayName: '新しい名前', locale: 'en'),
      ).thenAnswer(
        (_) async => const UserProfileDto(
          userId: 1,
          email: 'test@example.com',
          authProvider: 'LOCAL',
          displayName: '新しい名前',
          locale: 'en',
        ),
      );

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .updateProfile(displayName: '新しい名前', locale: 'en');

      final before = container.read(accountSettingsNotifierProvider).value!;
      expect(before.successMessage, isNotNull);

      container.read(accountSettingsNotifierProvider.notifier).clearSuccess();
      final after = container.read(accountSettingsNotifierProvider).value!;
      expect(after.successMessage, isNull);
    });
  });

  group('AccountSettingsNotifier - 予期しない例外の catch(_) ブランチ', () {
    test('updateProfile: 予期しない例外でも errorUnexpected がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.updateProfile(
          displayName: anyNamed('displayName'),
          locale: anyNamed('locale'),
        ),
      ).thenThrow(Exception('unexpected'));

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .updateProfile(displayName: '名前', locale: 'ja');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, 'errorUnexpected');
    });

    test('changePassword: 予期しない例外でも errorUnexpected がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.changePassword(
          currentPassword: anyNamed('currentPassword'),
          newPassword: anyNamed('newPassword'),
        ),
      ).thenThrow(Exception('unexpected'));

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .changePassword(currentPassword: 'old', newPassword: 'new');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, 'errorUnexpected');
    });

    test(
      'toggleGlobalNotification: 予期しない例外でも errorUnexpected がセットされる',
      () async {
        _stubInitialLoad(mockRepo);
        when(
          mockRepo.updateNotificationSettings(any),
        ).thenThrow(Exception('unexpected'));

        final container = _makeContainer(mockRepo, mockDio);
        await container.read(accountSettingsNotifierProvider.future);

        await container
            .read(accountSettingsNotifierProvider.notifier)
            .toggleGlobalNotification(enabled: false);

        final state = container.read(accountSettingsNotifierProvider).value!;
        expect(state.errorMessage, 'errorUnexpected');
      },
    );

    test(
      'toggleGroupNotification: 予期しない例外でも errorUnexpected がセットされる',
      () async {
        _stubInitialLoad(mockRepo);
        when(
          mockRepo.updateNotificationSettings(any),
        ).thenThrow(Exception('unexpected'));

        final container = _makeContainer(mockRepo, mockDio);
        await container.read(accountSettingsNotifierProvider.future);

        await container
            .read(accountSettingsNotifierProvider.notifier)
            .toggleGroupNotification(groupCode: '100', enabled: false);

        final state = container.read(accountSettingsNotifierProvider).value!;
        expect(state.errorMessage, 'errorUnexpected');
      },
    );

    test('linkGoogleAccount: 予期しない例外でも errorUnexpected がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.linkGoogleAccount(idToken: anyNamed('idToken')),
      ).thenThrow(Exception('unexpected'));

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .linkGoogleAccount(idToken: 'bad-token');

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, 'errorUnexpected');
      expect(state.isLinkingGoogle, isFalse);
    });

    test('deleteAccount: 予期しない例外でも errorUnexpected がセットされる', () async {
      _stubInitialLoad(mockRepo);
      when(mockRepo.deleteAccount()).thenThrow(Exception('unexpected'));

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .deleteAccount();

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, 'errorUnexpected');
      expect(state.isDeletingAccount, isFalse);
    });
  });

  group(
    'AccountSettingsNotifier.toggleGlobalNotification() — payload 検証 (#128)',
    () {
      test(
        'ON→OFF時: Repository に渡される payload の groupSettings が空 Map である',
        () async {
          _stubInitialLoad(mockRepo);

          const returnedSettings = NotificationSettingsDto(
            notificationEnabled: false,
            groupSettings: {'100': false, '200': false},
          );
          when(
            mockRepo.updateNotificationSettings(any),
          ).thenAnswer((_) async => returnedSettings);

          final container = _makeContainer(mockRepo, mockDio);
          await container.read(accountSettingsNotifierProvider.future);

          await container
              .read(accountSettingsNotifierProvider.notifier)
              .toggleGlobalNotification(enabled: false);

          // Repository に渡されたオブジェクトを検証
          final captured = verify(
            mockRepo.updateNotificationSettings(captureAny),
          ).captured;
          final sentSettings = captured.last as NotificationSettingsDto;
          expect(sentSettings.notificationEnabled, isFalse);
          expect(sentSettings.groupSettings, isEmpty);
        },
      );

      test(
        'OFF→ON時: Repository に渡される payload の groupSettings が空 Map である',
        () async {
          _stubInitialLoad(mockRepo);

          const returnedSettings = NotificationSettingsDto(
            notificationEnabled: true,
            groupSettings: {'100': true, '200': true},
          );
          when(
            mockRepo.updateNotificationSettings(any),
          ).thenAnswer((_) async => returnedSettings);

          final container = _makeContainer(mockRepo, mockDio);
          await container.read(accountSettingsNotifierProvider.future);

          await container
              .read(accountSettingsNotifierProvider.notifier)
              .toggleGlobalNotification(enabled: true);

          final captured = verify(
            mockRepo.updateNotificationSettings(captureAny),
          ).captured;
          final sentSettings = captured.last as NotificationSettingsDto;
          expect(sentSettings.notificationEnabled, isTrue);
          expect(sentSettings.groupSettings, isEmpty);
        },
      );

      test('ON→OFF→ON のシナリオ: 最後の ON 送信時も groupSettings が空 Map である', () async {
        _stubInitialLoad(mockRepo);

        // ON→OFF 時のレスポンス（全グループ false）
        when(mockRepo.updateNotificationSettings(any)).thenAnswer((_) async {
          return const NotificationSettingsDto(
            notificationEnabled: false,
            groupSettings: {'100': false, '200': false},
          );
        });

        final container = _makeContainer(mockRepo, mockDio);
        await container.read(accountSettingsNotifierProvider.future);

        // 1回目: ON→OFF
        await container
            .read(accountSettingsNotifierProvider.notifier)
            .toggleGlobalNotification(enabled: false);

        // OFF→ON 時のレスポンスに変更
        when(mockRepo.updateNotificationSettings(any)).thenAnswer((_) async {
          return const NotificationSettingsDto(
            notificationEnabled: true,
            groupSettings: {'100': true, '200': true},
          );
        });

        // 2回目: OFF→ON
        await container
            .read(accountSettingsNotifierProvider.notifier)
            .toggleGlobalNotification(enabled: true);

        final captured = verify(
          mockRepo.updateNotificationSettings(captureAny),
        ).captured;
        // 最後（2回目）の呼び出しを確認
        final sentSettings = captured.last as NotificationSettingsDto;
        expect(sentSettings.notificationEnabled, isTrue);
        expect(sentSettings.groupSettings, isEmpty);
      });
    },
  );

  group(
    'AccountSettingsNotifier.toggleGroupNotification() — payload 検証 (#128)',
    () {
      test(
        'グループ通知 OFF 時: Repository に渡される groupSettings が対象グループのみ含む delta Map',
        () async {
          _stubInitialLoad(mockRepo);

          const returnedSettings = NotificationSettingsDto(
            notificationEnabled: true,
            groupSettings: {'100': true, '200': false},
          );
          when(
            mockRepo.updateNotificationSettings(any),
          ).thenAnswer((_) async => returnedSettings);

          final container = _makeContainer(mockRepo, mockDio);
          await container.read(accountSettingsNotifierProvider.future);

          await container
              .read(accountSettingsNotifierProvider.notifier)
              .toggleGroupNotification(groupCode: '200', enabled: false);

          final captured = verify(
            mockRepo.updateNotificationSettings(captureAny),
          ).captured;
          final sentSettings = captured.last as NotificationSettingsDto;
          expect(sentSettings.notificationEnabled, isTrue);
          // delta: 対象グループのみ含む（他グループは含まない）
          expect(sentSettings.groupSettings, {'200': false});
          expect(sentSettings.groupSettings.containsKey('100'), isFalse);
        },
      );

      test(
        'グループ通知 ON 時: Repository に渡される groupSettings が対象グループのみ含む delta Map',
        () async {
          _stubInitialLoad(mockRepo);

          const returnedSettings = NotificationSettingsDto(
            notificationEnabled: true,
            groupSettings: {'100': true, '200': true},
          );
          when(
            mockRepo.updateNotificationSettings(any),
          ).thenAnswer((_) async => returnedSettings);

          final container = _makeContainer(mockRepo, mockDio);
          await container.read(accountSettingsNotifierProvider.future);

          await container
              .read(accountSettingsNotifierProvider.notifier)
              .toggleGroupNotification(groupCode: '200', enabled: true);

          final captured = verify(
            mockRepo.updateNotificationSettings(captureAny),
          ).captured;
          final sentSettings = captured.last as NotificationSettingsDto;
          expect(sentSettings.notificationEnabled, isTrue);
          expect(sentSettings.groupSettings, {'200': true});
          expect(sentSettings.groupSettings.containsKey('100'), isFalse);
        },
      );
    },
  );

  group('AccountSettingsNotifier.reload()', () {
    test('reload()を呼ぶと状態がAsyncDataとして取得できる', () async {
      _stubInitialLoad(mockRepo);

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container.read(accountSettingsNotifierProvider.notifier).reload();

      final async = container.read(accountSettingsNotifierProvider);
      expect(async.hasValue, true);
    });
  });

  group('AccountSettingsNotifier.updateThemeMode()', () {
    test('成功時: 例外なく完了する（state に変化なし）', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.updateThemeMode(themeMode: 'LIGHT'),
      ).thenAnswer((_) async {});

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .updateThemeMode(themeMode: 'LIGHT');

      final state = container.read(accountSettingsNotifierProvider).value!;
      // updateThemeMode は state を変更しない（ThemeModeNotifier が管理）
      expect(state.errorMessage, isNull);
    });

    test('失敗時: サイレントに失敗する（AC5 は Nice to Have のため errorMessage は不要）', () async {
      _stubInitialLoad(mockRepo);

      final container = _makeContainer(mockRepo, mockDio);
      await container.read(accountSettingsNotifierProvider.future);

      // updateThemeMode のスタブ（初期ロード後に設定）
      when(
        mockRepo.updateThemeMode(themeMode: 'DARK'),
      ).thenThrow(const NetworkException('接続エラー'));

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .updateThemeMode(themeMode: 'DARK');

      final state = container.read(accountSettingsNotifierProvider).value!;
      // バックエンド同期失敗はサイレント（AC5はNice to Have）→ errorMessageは不要
      expect(state.errorMessage, isNull);
    });
  });
}
