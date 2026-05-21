import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hw_hub_mobile/features/shopping/presentation/widgets/image_picker_field.dart';

import '../../../../helpers/widget_test_helpers.dart';

void main() {
  group('ImagePickerField', () {
    testWidgets('imageBytes=null: 画像追加ボタンが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: ImagePickerField(
              imageBytes: null,
              imageName: null,
              onPickCamera: () async {},
              onPickGallery: () async {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('imageBytes 設定時: サムネイルが表示される', (tester) async {
      // 最小の有効なPNG (1x1 透明ピクセル)
      final dummyBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
        0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
        0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
        0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      // Image.memory のロードエラーはテスト環境で無視する
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        // 画像デコードエラーはテストで無視
      };

      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: ImagePickerField(
              imageBytes: dummyBytes,
              imageName: 'test.jpg',
              onPickCamera: () async {},
              onPickGallery: () async {},
              onClear: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      FlutterError.onError = originalOnError;

      // サムネイルコンテナ（Stack）が表示される
      expect(find.byType(Stack), findsWidgets);
      // クリアボタン（cancel icon）が表示される
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('画像追加ボタンタップ: ボトムシートが表示される', (tester) async {
      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: ImagePickerField(
              imageBytes: null,
              imageName: null,
              onPickCamera: () async {},
              onPickGallery: () async {},
              onClear: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // ボトムシートが表示される（カメラ・ギャラリーオプション）
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.photo_library), findsOneWidget);
    });

    testWidgets('onClear コールバックが呼ばれる', (tester) async {
      var clearCalled = false;
      final dummyBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0x90,
        0x77,
        0x53,
        0xDE,
        0x00,
        0x00,
        0x00,
        0x0C,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0xD7,
        0x63,
        0xF8,
        0xCF,
        0xC0,
        0x00,
        0x00,
        0x00,
        0x02,
        0x00,
        0x01,
        0xE2,
        0x21,
        0xBC,
        0x33,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (_) {};

      await tester.pumpWidget(
        buildTestPage(
          Scaffold(
            body: ImagePickerField(
              imageBytes: dummyBytes,
              imageName: 'test.jpg',
              onPickCamera: () async {},
              onPickGallery: () async {},
              onClear: () => clearCalled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      FlutterError.onError = originalOnError;

      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pump();

      expect(clearCalled, isTrue);
    });
  });
}
