import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// 画像選択フィールド（サムネイル表示・カメラ/ギャラリー選択ボトムシート付き）。
/// 実際の image_picker 呼び出しはウィジェット外で行い、バイトを直接渡す設計。
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    this.imageBytes,
    this.imageName,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final Future<void> Function() onPickCamera;
  final Future<void> Function() onPickGallery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (imageBytes != null) {
      return _ThumbnailPreview(
        imageBytes: imageBytes!,
        imageName: imageName,
        onClear: onClear,
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _showSourcePicker(context, l10n),
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: Text(l10n.shoppingNewImageHint),
    );
  }

  void _showSourcePicker(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.shoppingImagePickerCamera),
              onTap: () {
                Navigator.pop(context);
                onPickCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.shoppingImagePickerGallery),
              onTap: () {
                Navigator.pop(context);
                onPickGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.shoppingImagePickerCancel),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbnailPreview extends StatelessWidget {
  const _ThumbnailPreview({
    required this.imageBytes,
    this.imageName,
    required this.onClear,
  });

  final Uint8List imageBytes;
  final String? imageName;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.cancel),
          color: Colors.white,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black54,
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(28, 28),
          ),
        ),
      ],
    );
  }
}
