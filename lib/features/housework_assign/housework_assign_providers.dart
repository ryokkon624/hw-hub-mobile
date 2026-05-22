import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/network/s3_url_resolver.dart';
import 'data/housework_assign_repository.dart';
import 'presentation/housework_assign_notifier.dart';
import 'presentation/housework_assign_state.dart';

export 'presentation/housework_assign_notifier.dart';
export 'presentation/housework_assign_state.dart';

final houseworkAssignRepositoryProvider = Provider<HouseworkAssignRepository>((
  ref,
) {
  return HouseworkAssignRepositoryImpl(
    ref.watch(dioProvider),
    S3UrlResolver(isDebug: kDebugMode),
  );
});

final houseworkAssignNotifierProvider =
    AsyncNotifierProvider.autoDispose<
      HouseworkAssignNotifier,
      HouseworkAssignState
    >(HouseworkAssignNotifier.new);
