import 'package:flutter/material.dart';
import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/housework_template_dto.dart';

/// テンプレート選択モーダル。
class TemplatePickerModal extends StatefulWidget {
  const TemplatePickerModal({
    super.key,
    required this.templates,
    required this.onSelected,
  });

  final List<HouseworkTemplateDto> templates;
  final void Function(HouseworkTemplateDto) onSelected;

  @override
  State<TemplatePickerModal> createState() => _TemplatePickerModalState();
}

class _TemplatePickerModalState extends State<TemplatePickerModal> {
  String? _selectedCategory;

  List<HouseworkTemplateDto> get _filtered {
    if (_selectedCategory == null) return widget.templates;
    return widget.templates
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    final categories = [
      (null, l10n.houseworkTemplateFilterAll),
      ('CLEAN', l10n.houseworkTemplateCategoryClean),
      ('KITCHEN', l10n.houseworkTemplateCategoryKitchen),
      ('GARDEN', l10n.houseworkTemplateCategoryGarden),
      ('GARBAGE', l10n.houseworkTemplateCategoryGarbage),
      ('PET', l10n.houseworkTemplateCategoryPet),
      ('OTHER', l10n.houseworkTemplateCategoryOther),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル
          Row(
            children: [
              Text(
                l10n.houseworkTemplateModalTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textHeading,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const Key('templateModalClose'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // カテゴリフィルタ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((pair) {
                final isSelected = _selectedCategory == pair.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(pair.$2),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = pair.$1),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // テンプレート一覧
          Expanded(
            child: ListView(
              children: _filtered.map((t) {
                final locale = Localizations.localeOf(context).languageCode;
                final name = locale == 'es'
                    ? t.nameEs
                    : locale == 'en'
                    ? t.nameEn
                    : t.nameJa;
                return ListTile(
                  key: ValueKey(t.houseworkTemplateId),
                  title: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  onTap: () {
                    widget.onSelected(t);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
