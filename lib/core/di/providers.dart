import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../auth/token_storage.dart';
import '../household/household_notifier.dart';
import '../household/household_state.dart';
import '../network/dio_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final dioProvider = Provider<Dio>((ref) {
  return DioClient.create(storage: ref.watch(secureStorageProvider), ref: ref);
});

final householdNotifierProvider =
    AsyncNotifierProvider<HouseholdNotifier, HouseholdState>(
      HouseholdNotifier.new,
    );
