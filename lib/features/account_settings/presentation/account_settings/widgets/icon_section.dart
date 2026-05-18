import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../core/ui/user_avatar.dart';
import '../../../../../l10n/app_localizations.dart';

/// AC4: プロフィール画像セクション（image_picker + S3 PUT）
class IconSection extends StatelessWidget {
  const IconSection({
    super.key,
    required this.iconUrl,
    required this.isUploading,
    required this.onImageSelected,
  });

  final String? iconUrl;
  final bool isUploading;
  final Future<void> Function(List<int> bytes, String fileName, String mimeType)
  onImageSelected;

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final fileName = file.name;

    // MIME タイプを拡張子から判定
    final mimeType = switch (fileName.toLowerCase().split('.').last) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };

    await onImageSelected(bytes, fileName, mimeType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountSettingsIconSection,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 現在のアイコン
              UserAvatar(iconUrl: iconUrl, label: 'U', size: UserAvatarSize.lg),
              const SizedBox(height: 16),
              if (isUploading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(context, ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(l10n.accountSettingsIconCamera),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primaryBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(context, ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(l10n.accountSettingsIconLibrary),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.primaryBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
