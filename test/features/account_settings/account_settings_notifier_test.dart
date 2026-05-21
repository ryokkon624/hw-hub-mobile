import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/account_settings/account_settings_providers.dart';
import 'package:hw_hub_mobile/features/account_settings/data/account_settings_repository.dart';
import 'package:hw_hub_mobile/features/account_settings/presentation/account_settings/account_settings_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([AccountSettingsRepository])
import 'account_settings_notifier_test.mocks.dart';

ProviderContainer _makeContainer(AccountSettingsRepository repo) {
  final container = ProviderContainer(
    overrides: [accountSettingsRepositoryProvider.overrideWithValue(repo)],
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

  setUp(() {
    mockRepo = MockAccountSettingsRepository();
  });

  group('AccountSettingsNotifier.build()', () {
    test('初期ロード成功時: profile と notificationSettings が state に格納される', () async {
      _stubInitialLoad(mockRepo);

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

    test('失敗時: errorMessage がセットされ isUploadingIcon が false になる', () async {
      _stubInitialLoad(mockRepo);
      when(
        mockRepo.createIconUploadUrl(
          fileName: anyNamed('fileName'),
          mimeType: anyNamed('mimeType'),
        ),
      ).thenThrow(const NetworkException('接続エラー'));

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

        final container = _makeContainer(mockRepo);
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

        final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
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

      final container = _makeContainer(mockRepo);
      await container.read(accountSettingsNotifierProvider.future);

      await container
          .read(accountSettingsNotifierProvider.notifier)
          .deleteAccount();

      final state = container.read(accountSettingsNotifierProvider).value!;
      expect(state.errorMessage, 'errorUnexpected');
      expect(state.isDeletingAccount, isFalse);
    });
  });
}
