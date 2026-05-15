import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/housework_assign_repository.dart';

final houseworkAssignRepositoryProvider = Provider<HouseworkAssignRepository>((
  ref,
) {
  return HouseworkAssignRepositoryImpl(ref.watch(dioProvider));
});
