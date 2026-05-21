import 'package:flutter/material.dart';
import '../../../../core/models/category.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/housework_settings_repository.dart';
import '../housework_create/housework_create_state.dart';
import 'month_day_selector.dart';
import 'nth_weekday_selector.dart';
import 'weekly_days_selector.dart';

/// 家事作成・編集の共通フォームウィジェット。
class HouseworkForm extends StatefulWidget {
  const HouseworkForm({
    super.key,
    required this.form,
    required this.members,
    required this.errors,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.onCategoryChanged,
    required this.onRecurrenceTypeChanged,
    required this.onWeeklyDayToggled,
    required this.onDayOfMonthChanged,
    required this.onNthWeekChanged,
    required this.onWeekdayChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onAssigneeChanged,
  });

  final HouseworkFormState form;
  final List<HouseholdMemberDto> members;
  final HouseworkFormErrors errors;
  final void Function(String) onNameChanged;
  final void Function(String) onDescriptionChanged;
  final void Function(String) onCategoryChanged;
  final void Function(String) onRecurrenceTypeChanged;
  final void Function(int) onWeeklyDayToggled;
  final void Function(int) onDayOfMonthChanged;
  final void Function(int) onNthWeekChanged;
  final void Function(int) onWeekdayChanged;
  final void Function(String) onStartDateChanged;
  final void Function(String) onEndDateChanged;
  final void Function(int?) onAssigneeChanged;

  @override
  State<HouseworkForm> createState() => _HouseworkFormState();
}

class _HouseworkFormState extends State<HouseworkForm> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.form.name);
    _descriptionController = TextEditingController(
      text: widget.form.description,
    );
  }

  @override
  void didUpdateWidget(HouseworkForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // テンプレート選択や外部からの form 変更を TextEditingController に反映する。
    // ユーザー入力中に上書きしないよう、現在のコントローラ値と異なる場合のみ更新する。
    if (widget.form.name != oldWidget.form.name &&
        widget.form.name != _nameController.text) {
      _nameController.text = widget.form.name;
    }
    if (widget.form.description != oldWidget.form.description &&
        widget.form.description != _descriptionController.text) {
      _descriptionController.text = widget.form.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    final categoryItems = [
      (Category.cleaning.code, l10n.houseworkCategoryClean),
      (Category.kitchen.code, l10n.houseworkCategoryKitchen),
      (Category.garden.code, l10n.houseworkCategoryGarden),
      (Category.garbage.code, l10n.houseworkCategoryGarbage),
      (Category.pet.code, l10n.houseworkCategoryPet),
      (Category.other.code, l10n.houseworkCategoryOther),
    ];

    final recurrenceItems = [
      ('1', l10n.houseworkRecurrenceTypeWeekly),
      ('2', l10n.houseworkRecurrenceTypeMonthly),
      ('3', l10n.houseworkRecurrenceTypeNthWeekday),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 基本情報セクション ───
        _SectionHeader(title: l10n.houseworkCreateBasicInfoSection),
        _FormCard(
          colors: colors,
          child: Column(
            children: [
              // 家事名
              TextFormField(
                key: const Key('houseworkNameField'),
                controller: _nameController,
                onChanged: widget.onNameChanged,
                decoration: InputDecoration(
                  labelText: l10n.houseworkCreateNameLabel,
                  hintText: l10n.houseworkCreateNameHint,
                  errorText: widget.errors.nameError != null
                      ? _errorText(context, l10n, widget.errors.nameError!)
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // 説明
              TextFormField(
                key: const Key('houseworkDescriptionField'),
                controller: _descriptionController,
                onChanged: widget.onDescriptionChanged,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.houseworkCreateDescriptionLabel,
                  hintText: l10n.houseworkCreateDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // カテゴリ
              DropdownButtonFormField<String>(
                key: const Key('houseworkCategoryDropdown'),
                initialValue: widget.form.category,
                items: categoryItems.map((pair) {
                  return DropdownMenuItem<String>(
                    value: pair.$1,
                    child: Text(pair.$2),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) widget.onCategoryChanged(val);
                },
                decoration: InputDecoration(
                  labelText: l10n.houseworkCreateCategoryLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── 周期設定セクション ───
        _SectionHeader(title: l10n.houseworkCreateRecurrenceSection),
        _FormCard(
          colors: colors,
          child: Column(
            children: [
              // 周期タイプ
              DropdownButtonFormField<String>(
                key: const Key('houseworkRecurrenceTypeDropdown'),
                initialValue: widget.form.recurrenceType,
                items: recurrenceItems.map((pair) {
                  return DropdownMenuItem<String>(
                    value: pair.$1,
                    child: Text(pair.$2),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) widget.onRecurrenceTypeChanged(val);
                },
                decoration: InputDecoration(
                  labelText: l10n.houseworkCreateRecurrenceTypeLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 周期タイプ別入力
              if (widget.form.recurrenceType == '1') ...[
                Text(
                  l10n.houseworkCreateWeeklyDaysLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                WeeklyDaysSelector(
                  weeklyDays: widget.form.weeklyDays,
                  onToggle: widget.onWeeklyDayToggled,
                  errorText: widget.errors.weeklyDaysError != null
                      ? _errorText(
                          context,
                          l10n,
                          widget.errors.weeklyDaysError!,
                        )
                      : null,
                ),
              ],
              if (widget.form.recurrenceType == '2') ...[
                MonthDaySelector(
                  dayOfMonth: widget.form.dayOfMonth,
                  onChanged: widget.onDayOfMonthChanged,
                ),
              ],
              if (widget.form.recurrenceType == '3') ...[
                NthWeekdaySelector(
                  nthWeek: widget.form.nthWeek,
                  weekday: widget.form.weekday,
                  onNthChanged: widget.onNthWeekChanged,
                  onWeekdayChanged: widget.onWeekdayChanged,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── 担当者・有効期間セクション ───
        _SectionHeader(title: l10n.houseworkCreateAssigneeSection),
        _FormCard(
          colors: colors,
          child: Column(
            children: [
              // デフォルト担当者
              DropdownButtonFormField<int?>(
                key: const Key('houseworkAssigneeDropdown'),
                initialValue: widget.form.defaultAssigneeUserId,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.houseworkCreateAssigneeNone),
                  ),
                  ...widget.members.map(
                    (m) => DropdownMenuItem<int?>(
                      value: m.userId,
                      child: Text(m.nickname ?? m.displayName),
                    ),
                  ),
                ],
                onChanged: widget.onAssigneeChanged,
                decoration: InputDecoration(
                  labelText: l10n.houseworkCreateAssigneeLabel,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 開始日
              TextFormField(
                key: const Key('houseworkStartDateField'),
                initialValue: widget.form.startDate,
                onChanged: widget.onStartDateChanged,
                decoration: InputDecoration(
                  labelText: l10n.houseworkCreateStartDateLabel,
                  errorText: widget.errors.startDateError != null
                      ? _errorText(context, l10n, widget.errors.startDateError!)
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // 終了日
              TextFormField(
                key: const Key('houseworkEndDateField'),
                initialValue: widget.form.endDate,
                onChanged: widget.onEndDateChanged,
                decoration: InputDecoration(
                  labelText: l10n.houseworkCreateEndDateLabel,
                  errorText: widget.errors.endDateError != null
                      ? _errorText(context, l10n, widget.errors.endDateError!)
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _errorText(BuildContext context, AppLocalizations l10n, String key) {
    switch (key) {
      case 'houseworkCreateErrorNameRequired':
        return l10n.houseworkCreateErrorNameRequired;
      case 'houseworkCreateErrorNameTooLong':
        return l10n.houseworkCreateErrorNameTooLong;
      case 'houseworkCreateErrorWeeklyDaysRequired':
        return l10n.houseworkCreateErrorWeeklyDaysRequired;
      case 'houseworkCreateErrorMonthlyDayRequired':
        return l10n.houseworkCreateErrorMonthlyDayRequired;
      case 'houseworkCreateErrorNthWeekRequired':
        return l10n.houseworkCreateErrorNthWeekRequired;
      case 'houseworkCreateErrorNthWeekdayRequired':
        return l10n.houseworkCreateErrorNthWeekdayRequired;
      case 'houseworkCreateErrorStartDateRequired':
        return l10n.houseworkCreateErrorStartDateRequired;
      case 'houseworkCreateErrorEndDateRequired':
        return l10n.houseworkCreateErrorEndDateRequired;
      case 'houseworkCreateErrorEndDateBeforeStart':
        return l10n.houseworkCreateErrorEndDateBeforeStart;
      case 'houseworkCreateErrorInvalidDate':
        return l10n.houseworkCreateErrorInvalidDate;
      default:
        return key;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: colors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.textMuted),
            ),
          ),
          Expanded(child: Divider(color: colors.border)),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.colors, required this.child});
  final AppColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}
