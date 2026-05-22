import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/housework_settings_repository.dart';
import 'presentation/housework_create/housework_create_notifier.dart';
import 'presentation/housework_create/housework_create_state.dart';
import 'presentation/housework_edit/housework_edit_notifier.dart';
import 'presentation/housework_edit/housework_edit_state.dart';
import 'presentation/housework_list/housework_list_notifier.dart';
import 'presentation/housework_list/housework_list_state.dart';

export 'presentation/housework_create/housework_create_notifier.dart';
export 'presentation/housework_create/housework_create_state.dart';
export 'presentation/housework_edit/housework_edit_notifier.dart';
export 'presentation/housework_edit/housework_edit_state.dart';
export 'presentation/housework_list/housework_list_notifier.dart';
export 'presentation/housework_list/housework_list_state.dart';

final houseworkSettingsRepositoryProvider =
    Provider<HouseworkSettingsRepository>((ref) {
      return HouseworkSettingsRepositoryImpl(ref.watch(dioProvider));
    });

final houseworkCreateNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      HouseworkCreateNotifier,
      HouseworkCreateState
    >(HouseworkCreateNotifier.new);

final houseworkEditNotifierProvider =
    AutoDisposeAsyncNotifierProvider.family<
      HouseworkEditNotifier,
      HouseworkEditState,
      int
    >(HouseworkEditNotifier.new);

final houseworkListNotifierProvider =
    AutoDisposeAsyncNotifierProvider<HouseworkListNotifier, HouseworkListState>(
      HouseworkListNotifier.new,
    );
