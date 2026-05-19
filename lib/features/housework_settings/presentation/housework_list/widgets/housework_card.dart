import 'package:flutter/material.dart';
import '../../../../../core/models/category.dart';
import '../../../../../core/models/recurrence_type.dart';
import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/models/housework_dto.dart';

/// 家事設定一覧のカードWidget。
class HouseworkCard extends StatelessWidget {
  const HouseworkCard({
    super.key,
    required this.housework,
    required this.assigneeName,
    required this.onTap,
  });

  final HouseworkDto housework;
  final String? assigneeName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 家事名 + カテゴリバッジ
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        housework.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.textHeading,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CategoryBadge(category: housework.category),
                  ],
                ),
                const SizedBox(height: 4),
                // 周期サマリー
                Text(
                  _recurrenceSummary(context, l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                // 担当者 + 有効期間
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assigneeName != null
                            ? l10n.houseworkSettingsAssigneeLabel(assigneeName!)
                            : l10n.houseworkSettingsAssigneeNone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      '${housework.startDate}〜',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _recurrenceSummary(BuildContext context, AppLocalizations l10n) {
    final rt = RecurrenceType.fromCode(housework.recurrenceType);

    if (rt == RecurrenceType.weekly) {
      final days = _weeklyDaysLabel(context, l10n, housework.weeklyDays ?? 0);
      return l10n.houseworkSettingsRecurrenceWeekly(days);
    } else if (rt == RecurrenceType.monthly) {
      final day = housework.dayOfMonth ?? 1;
      if (day == 31) {
        return l10n.houseworkSettingsRecurrenceMonthlyEnd;
      }
      return l10n.houseworkSettingsRecurrenceMonthly(day);
    } else if (rt == RecurrenceType.nthWeekday) {
      final nth = housework.nthWeek ?? 1;
      final wd = _weekdayLabel(l10n, housework.weekday ?? 0);
      return l10n.houseworkSettingsRecurrenceNthWeekday(nth, wd);
    }
    return housework.recurrenceType;
  }

  /// weeklyDaysビットマスクから曜日文字列を生成する。
  /// bit0=日曜, bit1=月曜, ... bit6=土曜
  String _weeklyDaysLabel(
    BuildContext context,
    AppLocalizations l10n,
    int mask,
  ) {
    final names = [
      l10n.houseworkWeekdaySun,
      l10n.houseworkWeekdayMon,
      l10n.houseworkWeekdayTue,
      l10n.houseworkWeekdayWed,
      l10n.houseworkWeekdayThu,
      l10n.houseworkWeekdayFri,
      l10n.houseworkWeekdaySat,
    ];
    final selected = <String>[];
    for (var i = 0; i < 7; i++) {
      if (mask & (1 << i) != 0) selected.add(names[i]);
    }
    return selected.join('・');
  }

  String _weekdayLabel(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case 0:
        return l10n.houseworkWeekdaySun;
      case 1:
        return l10n.houseworkWeekdayMon;
      case 2:
        return l10n.houseworkWeekdayTue;
      case 3:
        return l10n.houseworkWeekdayWed;
      case 4:
        return l10n.houseworkWeekdayThu;
      case 5:
        return l10n.houseworkWeekdayFri;
      case 6:
        return l10n.houseworkWeekdaySat;
      default:
        return '';
    }
  }
}

/// カテゴリバッジWidget。
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, bgColor, textColor) = _badgeStyle(context, l10n);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color, Color) _badgeStyle(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final cat = Category.fromCode(category);
    switch (cat) {
      case Category.cleaning:
        return (
          l10n.houseworkCategoryClean,
          Colors.blue.shade100,
          Colors.blue.shade700,
        );
      case Category.kitchen:
        return (
          l10n.houseworkCategoryKitchen,
          Colors.orange.shade100,
          Colors.orange.shade700,
        );
      case Category.garden:
        return (
          l10n.houseworkCategoryGarden,
          Colors.cyan.shade100,
          Colors.cyan.shade700,
        );
      case Category.garbage:
        return (
          l10n.houseworkCategoryGarbage,
          Colors.green.shade100,
          Colors.green.shade700,
        );
      case Category.pet:
        return (
          l10n.houseworkCategoryPet,
          Colors.purple.shade100,
          Colors.purple.shade700,
        );
      case Category.other:
        return (
          l10n.houseworkCategoryOther,
          Colors.grey.shade100,
          Colors.grey.shade700,
        );
      default:
        return (category, Colors.grey.shade100, Colors.grey.shade700);
    }
  }
}
