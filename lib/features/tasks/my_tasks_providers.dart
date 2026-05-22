import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/my_tasks_repository.dart';
import 'presentation/my_tasks_notifier.dart';
import 'presentation/my_tasks_state.dart';

export 'presentation/my_tasks_notifier.dart';
export 'presentation/my_tasks_state.dart';

final myTasksRepositoryProvider = Provider<MyTasksRepository>((ref) {
  return MyTasksRepositoryImpl(ref.watch(dioProvider));
});

final myTasksNotifierProvider =
    AsyncNotifierProvider.autoDispose<MyTasksNotifier, MyTasksState>(
      MyTasksNotifier.new,
    );
