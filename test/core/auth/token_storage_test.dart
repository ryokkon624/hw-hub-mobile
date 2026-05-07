import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/auth/token_storage.dart';
import 'package:hw_hub_mobile/core/storage/storage_keys.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mocks.mocks.dart';

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage sut;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    sut = TokenStorage(mockStorage);
  });

  group('TokenStorage.getAccessToken', () {
    test('reads access_token key', () async {
      when(mockStorage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => 'token_abc');

      final result = await sut.getAccessToken();

      expect(result, 'token_abc');
      verify(mockStorage.read(key: StorageKeys.accessToken)).called(1);
    });

    test('returns null when not stored', () async {
      when(mockStorage.read(key: StorageKeys.accessToken))
          .thenAnswer((_) async => null);

      final result = await sut.getAccessToken();

      expect(result, isNull);
    });
  });

  group('TokenStorage.saveTokens', () {
    test('writes both access and refresh tokens', () async {
      when(mockStorage.write(
              key: StorageKeys.accessToken, value: 'access'))
          .thenAnswer((_) async {});
      when(mockStorage.write(
              key: StorageKeys.refreshToken, value: 'refresh'))
          .thenAnswer((_) async {});

      await sut.saveTokens(accessToken: 'access', refreshToken: 'refresh');

      verify(mockStorage.write(
              key: StorageKeys.accessToken, value: 'access'))
          .called(1);
      verify(mockStorage.write(
              key: StorageKeys.refreshToken, value: 'refresh'))
          .called(1);
    });
  });

  group('TokenStorage.clearTokens', () {
    test('deletes both access and refresh tokens', () async {
      when(mockStorage.delete(key: StorageKeys.accessToken))
          .thenAnswer((_) async {});
      when(mockStorage.delete(key: StorageKeys.refreshToken))
          .thenAnswer((_) async {});

      await sut.clearTokens();

      verify(mockStorage.delete(key: StorageKeys.accessToken)).called(1);
      verify(mockStorage.delete(key: StorageKeys.refreshToken)).called(1);
    });
  });
}
