import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import 'data/inquiry_repository.dart';
import 'presentation/inquiry_create/inquiry_create_notifier.dart';
import 'presentation/inquiry_create/inquiry_create_state.dart';
import 'presentation/inquiry_detail/inquiry_detail_notifier.dart';
import 'presentation/inquiry_detail/inquiry_detail_state.dart';
import 'presentation/inquiry_list/inquiry_list_notifier.dart';

export 'presentation/inquiry_create/inquiry_create_notifier.dart';
export 'presentation/inquiry_create/inquiry_create_state.dart';
export 'presentation/inquiry_detail/inquiry_detail_notifier.dart';
export 'presentation/inquiry_detail/inquiry_detail_state.dart';
export 'presentation/inquiry_list/inquiry_list_notifier.dart'; // exports InquiryListNotifier + InquiryListState

final inquiryRepositoryProvider = Provider<InquiryRepository>((ref) {
  return InquiryRepositoryImpl(ref.watch(dioProvider));
});

final inquiryCreateNotifierProvider =
    NotifierProvider.autoDispose<InquiryCreateNotifier, InquiryCreateState>(
      InquiryCreateNotifier.new,
    );

final inquiryListNotifierProvider =
    NotifierProvider.autoDispose<InquiryListNotifier, InquiryListState>(
      InquiryListNotifier.new,
    );

final inquiryDetailNotifierProvider = NotifierProvider.autoDispose
    .family<InquiryDetailNotifier, InquiryDetailState, int>(
      InquiryDetailNotifier.new,
    );
