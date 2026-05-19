import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/app_info_repository.dart';
import 'presentation/app_info_notifier.dart';
import 'presentation/app_info_state.dart';

export 'presentation/app_info_notifier.dart';
export 'presentation/app_info_state.dart';

final appInfoRepositoryProvider = Provider<AppInfoRepository>((ref) {
  return AppInfoRepositoryImpl(ref.watch(dioProvider));
});

final appInfoNotifierProvider =
    NotifierProvider.autoDispose<AppInfoNotifier, AppInfoState>(
      AppInfoNotifier.new,
    );
