import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/network/s3_url_resolver.dart';
import 'data/auth_api.dart';
import 'data/auth_repository.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    api: ref.watch(authApiProvider),
    s3UrlResolver: S3UrlResolver(isDebug: kDebugMode),
  );
});
