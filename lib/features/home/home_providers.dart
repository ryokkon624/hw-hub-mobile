import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/network/s3_url_resolver.dart';
import 'data/home_repository.dart';
import 'presentation/home_notifier.dart';
import 'presentation/home_state.dart';

export 'presentation/home_notifier.dart';
export 'presentation/home_state.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    ref.watch(dioProvider),
    S3UrlResolver(isDebug: kDebugMode),
  );
});

final homeNotifierProvider =
    AsyncNotifierProvider.autoDispose<HomeNotifier, HomeState>(
      HomeNotifier.new,
    );
