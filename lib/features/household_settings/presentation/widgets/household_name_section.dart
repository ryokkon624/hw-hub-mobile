import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../household_settings_providers.dart';

/// 世帯名変更セクション（AC3）。
class HouseholdNameSection extends ConsumerStatefulWidget {
  const HouseholdNameSection({super.key});

  @override
  ConsumerState<HouseholdNameSection> createState() =>
      _HouseholdNameSectionState();
}

class _HouseholdNameSectionState extends ConsumerState<HouseholdNameSection> {
  late TextEditingController _controller;
  String _originalName = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    final hs = ref
        .read(householdNotifierProvider)
        .valueOrNull
        ?.selectedHousehold;
    if (hs != null) {
      _originalName = hs.name;
      _controller.text = hs.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasChange =>
      _controller.text.trim().isNotEmpty &&
      _controller.text.trim() != _originalName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifierState = ref.watch(householdSettingsNotifierProvider);
    final isSaving = notifierState.valueOrNull?.isSavingName ?? false;

    // 世帯切り替えで selectedHousehold が変化したらコントローラーと _originalName を更新する
    ref.listen(householdNotifierProvider, (prev, next) {
      final prevName = prev?.valueOrNull?.selectedHousehold?.name;
      final nextName = next.valueOrNull?.selectedHousehold?.name;
      if (nextName != null && nextName != prevName) {
        setState(() {
          _controller.text = nextName;
          _originalName = nextName;
        });
      }
    });

    return Card(
      key: const Key('householdInfoSection'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.householdSettingsHouseholdInfoSection,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: l10n.householdSettingsHouseholdNameLabel,
                hintText: l10n.householdSettingsHouseholdNameHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                key: const Key('saveHouseholdNameButton'),
                onPressed: _hasChange && !isSaving
                    ? () async {
                        await ref
                            .read(householdSettingsNotifierProvider.notifier)
                            .saveHouseholdName(name: _controller.text.trim());
                        setState(() {
                          _originalName = _controller.text.trim();
                        });
                      }
                    : null,
                child: Text(l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
