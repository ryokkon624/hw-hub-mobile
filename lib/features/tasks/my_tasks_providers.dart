import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/my_tasks_repository.dart';

final myTasksRepositoryProvider = Provider<MyTasksRepository>((ref) {
  return MyTasksRepositoryImpl(ref.watch(dioProvider));
});
