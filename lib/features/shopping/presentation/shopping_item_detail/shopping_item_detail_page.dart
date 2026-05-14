import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/favorite_flag.dart';
import '../../../../core/models/purchase_location_type.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_attachment_repository.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/status_step_selector.dart';
import 'shopping_item_detail_notifier.dart';

class ShoppingItemDetailPage extends ConsumerWidget {
  const ShoppingItemDetailPage({super.key, required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(shoppingItemDetailNotifierProvider(itemId));
    final notifier = ref.read(
      shoppingItemDetailNotifierProvider(itemId).notifier,
    );

    // 削除後に前の画面に戻る
    ref.listen(shoppingItemDetailNotifierProvider(itemId), (prev, next) {
      if (next.isDeleted && !(prev?.isDeleted ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shoppingDetailToastDeleteSuccess)),
        );
        context.pop();
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_resolveErrorMessage(l10n, next.errorMessage!)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(state.item?.name ?? l10n.shoppingDetailTitle),
        actions: [
          if (!state.isLoading && !state.isSaving)
            TextButton(
              key: const Key('saveButton'),
              onPressed: () => _save(context, notifier, l10n),
              child: Text(l10n.shoppingDetailSave),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.item == null
          ? _ErrorBody(
              errorMessage: state.errorMessage,
              onRetry: () {
                ref.invalidate(shoppingItemDetailNotifierProvider(itemId));
              },
            )
          : _DetailBody(notifier: notifier, state: state, itemId: itemId),
    );
  }

  Future<void> _save(
    BuildContext context,
    ShoppingItemDetailNotifier notifier,
    AppLocalizations l10n,
  ) async {
    await notifier.save();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.shoppingDetailToastSaveSuccess)),
    );
  }
}

/// エラー表示ボディ
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({this.errorMessage, this.onRetry});

  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            errorMessage ?? l10n.errorUnexpected,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ],
      ),
    );
  }
}

/// 詳細フォーム本体
class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.notifier,
    required this.state,
    required this.itemId,
  });

  final ShoppingItemDetailNotifier notifier;
  final ShoppingItemDetailState state;
  final int itemId;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  final _imagePicker = ImagePicker();

  Future<void> _pickCamera() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await widget.notifier.addImage(bytes: bytes, fileName: file.name);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.shoppingDetailToastImageAddSuccess)),
    );
  }

  Future<void> _pickGallery() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await widget.notifier.addImage(bytes: bytes, fileName: file.name);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.shoppingDetailToastImageAddSuccess)),
    );
  }

  Future<void> _confirmDeleteAttachment(
    BuildContext context,
    int attachmentId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(l10n.shoppingDetailImageDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.shoppingDetailImageDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.notifier.deleteAttachment(attachmentId);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.shoppingDetailToastImageDeleteSuccess)),
    );
  }

  Future<void> _confirmDeleteItem(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(l10n.shoppingDetailDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.shoppingDetailDeleteItem),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.notifier.deleteItem();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 説明文
          Text(l10n.shoppingDetailIntro),
          const SizedBox(height: 16),

          // ステータスステップ
          Text(
            l10n.shoppingDetailStatus,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StatusStepSelector(
            key: const Key('statusStepSelector'),
            currentStatus: state.item!.status,
            onChanged: widget.notifier.updateStatus,
          ),
          const SizedBox(height: 16),

          // アイテム名
          Text(
            l10n.shoppingNewName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('name_${state.item!.shoppingItemId}'),
            initialValue: state.currentName,
            onChanged: widget.notifier.setName,
            decoration: InputDecoration(
              hintText: l10n.shoppingNewName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // メモ
          Text(
            l10n.shoppingNewMemo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('memo_${state.currentMemo}'),
            initialValue: state.currentMemo,
            onChanged: widget.notifier.setMemo,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.shoppingNewMemo,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // 購入場所
          Text(
            l10n.shoppingNewStoreType,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _StoreTypeSelector(
            value: state.currentStoreType,
            onChanged: widget.notifier.setStoreType,
          ),
          const SizedBox(height: 16),

          // お気に入り
          SwitchListTile(
            key: const Key('favoriteSwitch'),
            title: Text(l10n.shoppingNewFavorite),
            value: state.currentFavorite == FavoriteFlag.favorite.code,
            onChanged: (_) => widget.notifier.toggleFavorite(),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // 添付画像セクション
          Text(
            l10n.shoppingDetailImageSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _AttachmentsSection(
            attachments: state.attachments,
            onAddCamera: _pickCamera,
            onAddGallery: _pickGallery,
            onDeleteAttachment: (id) => _confirmDeleteAttachment(context, id),
          ),
          const SizedBox(height: 24),

          // 削除ボタン（未購入ステータス時のみ表示）
          if (state.isNotPurchased) ...[
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('deleteItemButton'),
                onPressed: () => _confirmDeleteItem(context),
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(
                  l10n.shoppingDetailDeleteItem,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

/// 添付画像セクション
class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({
    required this.attachments,
    required this.onAddCamera,
    required this.onAddGallery,
    required this.onDeleteAttachment,
  });

  final List<ShoppingAttachmentDto> attachments;
  final Future<void> Function() onAddCamera;
  final Future<void> Function() onAddGallery;
  final Future<void> Function(int) onDeleteAttachment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (attachments.isNotEmpty) ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final att = attachments[i];
                return _AttachmentThumbnail(
                  imageUrl: att.imageUrl,
                  onDelete: () => onDeleteAttachment(att.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        // 画像追加ボタン
        ImagePickerField(
          imageBytes: null,
          imageName: null,
          onPickCamera: onAddCamera,
          onPickGallery: onAddGallery,
          onClear: () {},
        ),
      ],
    );
  }
}

/// 添付画像サムネイル（URL経由）
class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({required this.imageUrl, required this.onDelete});

  final String imageUrl;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 100,
              height: 100,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        GestureDetector(
          onTap: onDelete,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}

/// 購入場所セレクター（3択チップ）
class _StoreTypeSelector extends StatelessWidget {
  const _StoreTypeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 8,
      children: PurchaseLocationType.values.map((type) {
        final isSelected = value == type.code;
        return ChoiceChip(
          label: Text(_labelOf(l10n, type)),
          selected: isSelected,
          onSelected: (_) => onChanged(type.code),
        );
      }).toList(),
    );
  }

  String _labelOf(AppLocalizations l10n, PurchaseLocationType type) {
    switch (type) {
      case PurchaseLocationType.supermarket:
        return l10n.shoppingFilterSupermarket;
      case PurchaseLocationType.online:
        return l10n.shoppingFilterOnline;
      case PurchaseLocationType.drugstore:
        return l10n.shoppingFilterDrugstore;
    }
  }
}

/// l10nキー名からローカライズ済みエラーメッセージを解決する。
/// Notifier が l10n キー名をエラーメッセージとして設定している場合に変換する。
/// AppException から来たメッセージ（キー名でないもの）はそのまま返す。
String _resolveErrorMessage(AppLocalizations l10n, String messageOrKey) {
  switch (messageOrKey) {
    case 'shoppingDetailItemNotFound':
      return l10n.shoppingDetailItemNotFound;
    case 'shoppingDetailLoadError':
      return l10n.shoppingDetailLoadError;
    case 'shoppingDetailSaveError':
      return l10n.shoppingDetailSaveError;
    case 'shoppingDetailDeleteError':
      return l10n.shoppingDetailDeleteError;
    default:
      return messageOrKey;
  }
}
