import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/app_info/app_info_providers.dart';
import 'package:hw_hub_mobile/features/app_info/presentation/app_info_page.dart';

import '../../../helpers/widget_test_helpers.dart';

// APIバージョン取得成功の Fake Notifier
class _LoadedNotifier extends AppInfoNotifier {
  @override
  AppInfoState build() => AppInfoState(
    isLoadingApi: false,
    apiVersion: '1.2.3',
    appVersion: '0.9.0',
  );
}

// APIバージョン取得中の Fake Notifier
class _LoadingApiNotifier extends AppInfoNotifier {
  @override
  AppInfoState build() => const AppInfoState(
    isLoadingApi: true,
    apiVersion: null,
    appVersion: '0.9.0',
  );
}

// APIバージョン取得失敗の Fake Notifier
class _FailedApiNotifier extends AppInfoNotifier {
  @override
  AppInfoState build() => const AppInfoState(
    isLoadingApi: false,
    apiVersion: null,
    appVersion: '0.9.0',
  );
}

void main() {
  group('AppInfoPage', () {
    testWidgets('バージョン情報セクションが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AppInfoPage(),
          overrides: [
            appInfoNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('appInfoVersionSection')), findsOneWidget);
    });

    testWidgets('APIバージョン取得成功時: バージョン文字列が表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AppInfoPage(),
          overrides: [
            appInfoNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('apiVersionValue')), findsOneWidget);
    });

    testWidgets('APIバージョン取得中: ローディングインジケーターが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AppInfoPage(),
          overrides: [
            appInfoNotifierProvider.overrideWith(() => _LoadingApiNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('apiVersionLoading')), findsOneWidget);
    });

    testWidgets('APIバージョン取得失敗時: 不明ラベルが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AppInfoPage(),
          overrides: [
            appInfoNotifierProvider.overrideWith(() => _FailedApiNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('apiVersionUnknown')), findsOneWidget);
    });

    testWidgets('利用規約・プライバシーポリシーセクションが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AppInfoPage(),
          overrides: [
            appInfoNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('appInfoLegalSection')), findsOneWidget);
    });

    testWidgets('開発者情報セクションが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          const AppInfoPage(),
          overrides: [
            appInfoNotifierProvider.overrideWith(() => _LoadedNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('appInfoDeveloperSection')), findsOneWidget);
    });
  });
}
