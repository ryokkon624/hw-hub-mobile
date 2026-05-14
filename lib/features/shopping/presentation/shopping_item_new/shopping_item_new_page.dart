import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/shopping_repository.dart';
import '../../shopping_providers.dart';
import '../widgets/favorite_picker_bottom_sheet.dart';
import '../widgets/history_picker_bottom_sheet.dart';
import '../widgets/image_picker_field.dart';
import 'shopping_item_new_notifier.dart';

class ShoppingItemNewPage extends ConsumerWidget {
  const ShoppingItemNewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(shoppingItemNewNotifierProvider);
    final notifier = ref.read(shoppingItemNewNotifierProvider.notifier);

    // 登録成功後に前の画面に戻る
    ref.listen(shoppingItemNewNotifierProvider, (prev, next) {
      if (next.successItemId != null && prev?.successItemId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shoppingNewToastSuccess)));
        context.pop();
      }
      if (next.errorMessage != null && prev?.errorMessage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shoppingNewToastError)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingNewTitle),
        actions: [
          TextButton(
            onPressed: state.canSubmit
                ? () => _submit(context, ref, notifier)
                : null,
            child: Text(l10n.shoppingNewSubmit),
          ),
        ],
      ),
      body: state.isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : _ShoppingItemNewForm(notifier: notifier, state: state),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    ShoppingItemNewNotifier notifier,
  ) async {
    final householdAsync = ref.read(householdNotifierProvider);
    final householdId = householdAsync.valueOrNull?.selectedHousehold?.id;
    if (householdId == null) return;
    await notifier.submit(householdId: householdId);
  }
}

class _ShoppingItemNewForm extends ConsumerStatefulWidget {
  const _ShoppingItemNewForm({required this.notifier, required this.state});

  final ShoppingItemNewNotifier notifier;
  final ShoppingItemNewState state;

  @override
  ConsumerState<_ShoppingItemNewForm> createState() =>
      _ShoppingItemNewFormState();
}

class _ShoppingItemNewFormState extends ConsumerState<_ShoppingItemNewForm> {
  final _imagePicker = ImagePicker();

  Future<void> _pickCamera() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    widget.notifier.setPickedImage(bytes, file.name);
  }

  Future<void> _pickGallery() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    widget.notifier.setPickedImage(bytes, file.name);
  }

  Future<void> _showHistoryPicker() async {
    final householdAsync = ref.read(householdNotifierProvider);
    final householdId = householdAsync.valueOrNull?.selectedHousehold?.id;
    if (householdId == null) return;

    final repo = ref.read(shoppingRepositoryProvider);
    List<ShoppingItemHistorySuggestionDto> suggestions = [];
    try {
      suggestions = await repo.fetchHistorySuggestions(
        householdId: householdId,
      );
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HistoryPickerBottomSheet(
        suggestions: suggestions,
        onSelected: (s) {
          widget.notifier.setFromHistory(s);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _showFavoritePicker() async {
    final householdAsync = ref.read(householdNotifierProvider);
    final householdId = householdAsync.valueOrNull?.selectedHousehold?.id;
    if (householdId == null) return;

    final repo = ref.read(shoppingRepositoryProvider);
    final favorites = <ShoppingItemDto>[];
    try {
      favorites.addAll(await repo.fetchFavorites(householdId: householdId));
    } catch (_) {}

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FavoritePickerBottomSheet(
        favorites: List.from(favorites),
        onSelected: (item) {
          widget.notifier.setFromFavorite(item);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 説明文
          Text(l10n.shoppingNewIntro),
          const SizedBox(height: AppSpacing.md),

          // 履歴・お気に入りショートカット
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('historyButton'),
                  onPressed: _showHistoryPicker,
                  icon: const Icon(Icons.history),
                  label: Text(l10n.shoppingNewSelectFromHistory),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('favoriteButton'),
                  onPressed: _showFavoritePicker,
                  icon: const Icon(Icons.star_border),
                  label: Text(l10n.shoppingNewSelectFromFavorite),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // アイテム名
          Text(
            l10n.shoppingNewName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: state.name,
            key: ValueKey(state.name), // 履歴/お気に入りから選択時に再描画
            onChanged: widget.notifier.setName,
            decoration: InputDecoration(
              hintText: l10n.shoppingNewName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // メモ
          Text(
            l10n.shoppingNewMemo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: state.memo,
            key: ValueKey('memo_${state.memo}'),
            onChanged: widget.notifier.setMemo,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.shoppingNewMemo,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 購入場所
          Text(
            l10n.shoppingNewStoreType,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          _StoreTypeSelector(
            value: state.storeType,
            onChanged: widget.notifier.setStoreType,
          ),
          const SizedBox(height: AppSpacing.md),

          // お気に入り
          SwitchListTile(
            title: Text(l10n.shoppingNewFavorite),
            value: state.favorite == '1',
            onChanged: (v) => widget.notifier.setFavorite(v ? '1' : '0'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),

          // 画像
          Text(
            l10n.shoppingNewImage,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ImagePickerField(
            imageBytes: state.pickedImageBytes,
            imageName: state.pickedImageName,
            onPickCamera: _pickCamera,
            onPickGallery: _pickGallery,
            onClear: widget.notifier.clearImage,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
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
    const options = [
      ('1', 'shoppingFilterSupermarket'),
      ('2', 'shoppingFilterOnline'),
      ('3', 'shoppingFilterDrugstore'),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final code = opt.$1;
        final isSelected = value == code;
        return ChoiceChip(
          label: Text(_labelOf(l10n, code)),
          selected: isSelected,
          onSelected: (_) => onChanged(code),
        );
      }).toList(),
    );
  }

  String _labelOf(AppLocalizations l10n, String code) {
    switch (code) {
      case '1':
        return l10n.shoppingFilterSupermarket;
      case '2':
        return l10n.shoppingFilterOnline;
      case '3':
        return l10n.shoppingFilterDrugstore;
      default:
        return code;
    }
  }
}
