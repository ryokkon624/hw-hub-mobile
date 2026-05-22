import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/network/s3_url_resolver.dart';
import 'data/housework_assign_repository.dart';

final houseworkAssignRepositoryProvider = Provider<HouseworkAssignRepository>((
  ref,
) {
  return HouseworkAssignRepositoryImpl(
    ref.watch(dioProvider),
    S3UrlResolver(isDebug: kDebugMode),
  );
});
