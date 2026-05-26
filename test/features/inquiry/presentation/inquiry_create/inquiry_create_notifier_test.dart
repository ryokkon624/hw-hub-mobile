import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/core/network/app_exception.dart';
import 'package:hw_hub_mobile/features/app_info/app_info_providers.dart';
import 'package:hw_hub_mobile/features/inquiry/inquiry_providers.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app_info/app_info_mocks.mocks.dart';
import '../../inquiry_mocks.mocks.dart';

ProviderContainer _makeContainer({
  required MockInquiryRepository mockRepo,
  required MockAppInfoRepository mockAppInfoRepo,
}) {
  final container = ProviderContainer(
    overrides: [
      inquiryRepositoryProvider.overrideWithValue(mockRepo),
      appInfoRepositoryProvider.overrideWithValue(mockAppInfoRepo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockInquiryRepository mockRepo;
  late MockAppInfoRepository mockAppInfoRepo;

  setUp(() {
    mockRepo = MockInquiryRepository();
    mockAppInfoRepo = MockAppInfoRepository();
    // PackageInfo をモック
    PackageInfo.setMockInitialValues(
      appName: 'HwHub',
      packageName: 'com.hwhub.mobile',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  group('InquiryCreateNotifier 初期状態', () {
    test('初期状態: 各フィールドが空・isSubmitting=false', () {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      final state = container.read(inquiryCreateNotifierProvider);
      expect(state.selectedCategory, isNull);
      expect(state.title, '');
      expect(state.body, '');
      expect(state.isSubmitting, false);
      expect(state.errorMessage, isNull);
      expect(state.createdInquiryId, isNull);
    });
  });

  group('InquiryCreateNotifier.setCategory()', () {
    test('カテゴリが変更される', () {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      expect(
        container.read(inquiryCreateNotifierProvider).selectedCategory,
        '10',
      );
    });
  });

  group('InquiryCreateNotifier.setTitle()', () {
    test('タイトルが変更される', () {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setTitle('テスト件名');
      expect(container.read(inquiryCreateNotifierProvider).title, 'テスト件名');
    });
  });

  group('InquiryCreateNotifier.setBody()', () {
    test('本文が変更される', () {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setBody('テスト本文');
      expect(container.read(inquiryCreateNotifierProvider).body, 'テスト本文');
    });
  });

  group('InquiryCreateNotifier.submit() バリデーション', () {
    test('カテゴリ未選択: errorMessageがセットされる', () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setTitle('件名');
      container.read(inquiryCreateNotifierProvider.notifier).setBody('内容');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();
      expect(
        container.read(inquiryCreateNotifierProvider).errorMessage,
        'inquiryCreateErrorCategoryRequired',
      );
    });

    test('件名が空: errorMessageがセットされる', () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      container.read(inquiryCreateNotifierProvider.notifier).setBody('内容');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();
      expect(
        container.read(inquiryCreateNotifierProvider).errorMessage,
        'inquiryCreateErrorTitleRequired',
      );
    });

    test('件名が201文字: errorMessageがセットされる', () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      container
          .read(inquiryCreateNotifierProvider.notifier)
          .setTitle('a' * 201);
      container.read(inquiryCreateNotifierProvider.notifier).setBody('内容');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();
      expect(
        container.read(inquiryCreateNotifierProvider).errorMessage,
        'inquiryCreateErrorTitleTooLong',
      );
    });

    test('件名が200文字: バリデーション通過してAPIを呼ぶ', () async {
      when(mockAppInfoRepo.fetchApiVersion()).thenAnswer((_) async => '2.0.0');
      when(
        mockRepo.createInquiry(
          category: anyNamed('category'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          uiClient: anyNamed('uiClient'),
          uiVersion: anyNamed('uiVersion'),
          apiVersion: anyNamed('apiVersion'),
        ),
      ).thenAnswer((_) async => 1);

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      container
          .read(inquiryCreateNotifierProvider.notifier)
          .setTitle('a' * 200);
      container.read(inquiryCreateNotifierProvider.notifier).setBody('内容');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();

      verify(
        mockRepo.createInquiry(
          category: '10',
          title: anyNamed('title'),
          body: anyNamed('body'),
          uiClient: anyNamed('uiClient'),
          uiVersion: anyNamed('uiVersion'),
          apiVersion: anyNamed('apiVersion'),
        ),
      ).called(1);
    });

    test('本文が空: errorMessageがセットされる', () async {
      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      container.read(inquiryCreateNotifierProvider.notifier).setTitle('件名');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();
      expect(
        container.read(inquiryCreateNotifierProvider).errorMessage,
        'inquiryCreateErrorBodyRequired',
      );
    });
  });

  group('InquiryCreateNotifier.submit() 成功', () {
    test('送信成功時: createdInquiryIdがセットされ isSubmitting=false になる', () async {
      when(mockAppInfoRepo.fetchApiVersion()).thenAnswer((_) async => '2.0.0');
      when(
        mockRepo.createInquiry(
          category: anyNamed('category'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          uiClient: anyNamed('uiClient'),
          uiVersion: anyNamed('uiVersion'),
          apiVersion: anyNamed('apiVersion'),
        ),
      ).thenAnswer((_) async => 42);

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      container.read(inquiryCreateNotifierProvider.notifier).setTitle('件名テスト');
      container.read(inquiryCreateNotifierProvider.notifier).setBody('内容テスト');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();

      final state = container.read(inquiryCreateNotifierProvider);
      expect(state.createdInquiryId, 42);
      expect(state.isSubmitting, false);
      expect(state.errorMessage, isNull);
    });

    test(
      'submit()はuiClient=mobile・PackageInfoのversion・apiVersionをリポジトリに渡す',
      () async {
        when(
          mockAppInfoRepo.fetchApiVersion(),
        ).thenAnswer((_) async => '3.5.0');
        when(
          mockRepo.createInquiry(
            category: anyNamed('category'),
            title: anyNamed('title'),
            body: anyNamed('body'),
            uiClient: anyNamed('uiClient'),
            uiVersion: anyNamed('uiVersion'),
            apiVersion: anyNamed('apiVersion'),
          ),
        ).thenAnswer((_) async => 1);

        final container = _makeContainer(
          mockRepo: mockRepo,
          mockAppInfoRepo: mockAppInfoRepo,
        );
        container
            .read(inquiryCreateNotifierProvider.notifier)
            .setCategory('10');
        container.read(inquiryCreateNotifierProvider.notifier).setTitle('件名');
        container.read(inquiryCreateNotifierProvider.notifier).setBody('内容');
        await container.read(inquiryCreateNotifierProvider.notifier).submit();

        verify(
          mockRepo.createInquiry(
            category: '10',
            title: '件名',
            body: '内容',
            uiClient: 'mobile',
            uiVersion: '1.2.3', // PackageInfo.setMockInitialValuesで設定したversion
            apiVersion: '3.5.0',
          ),
        ).called(1);
      },
    );
  });

  group('InquiryCreateNotifier.submit() 失敗', () {
    test('AppException 時: errorMessageがセットされる', () async {
      when(mockAppInfoRepo.fetchApiVersion()).thenAnswer((_) async => '2.0.0');
      const exception = NetworkException('送信エラー');
      when(
        mockRepo.createInquiry(
          category: anyNamed('category'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          uiClient: anyNamed('uiClient'),
          uiVersion: anyNamed('uiVersion'),
          apiVersion: anyNamed('apiVersion'),
        ),
      ).thenThrow(exception);

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      container.read(inquiryCreateNotifierProvider.notifier).setTitle('件名');
      container.read(inquiryCreateNotifierProvider.notifier).setBody('内容');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();

      final state = container.read(inquiryCreateNotifierProvider);
      expect(state.errorMessage, exception.message);
      expect(state.isSubmitting, false);
    });

    test('予期しない例外: errorUnexpectedがセットされる', () async {
      when(mockAppInfoRepo.fetchApiVersion()).thenAnswer((_) async => '2.0.0');
      when(
        mockRepo.createInquiry(
          category: anyNamed('category'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          uiClient: anyNamed('uiClient'),
          uiVersion: anyNamed('uiVersion'),
          apiVersion: anyNamed('apiVersion'),
        ),
      ).thenThrow(Exception('予期しないエラー'));

      final container = _makeContainer(
        mockRepo: mockRepo,
        mockAppInfoRepo: mockAppInfoRepo,
      );
      container.read(inquiryCreateNotifierProvider.notifier).setCategory('10');
      container.read(inquiryCreateNotifierProvider.notifier).setTitle('件名');
      container.read(inquiryCreateNotifierProvider.notifier).setBody('内容');
      await container.read(inquiryCreateNotifierProvider.notifier).submit();

      final state = container.read(inquiryCreateNotifierProvider);
      expect(state.errorMessage, 'errorUnexpected');
      expect(state.isSubmitting, false);
    });
  });
}
