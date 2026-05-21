import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../household_settings_notifier.dart';

/// ニックネーム設定セクション（AC4）。
class NicknameSection extends ConsumerStatefulWidget {
  const NicknameSection({super.key});

  @override
  ConsumerState<NicknameSection> createState() => _NicknameSectionState();
}

class _NicknameSectionState extends ConsumerState<NicknameSection> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // 初期表示: 既に State が利用可能な場合は currentNickname をセット
    final currentNickname = ref
        .read(householdSettingsNotifierProvider)
        .valueOrNull
        ?.currentNickname;
    if (currentNickname != null) {
      _controller.text = currentNickname;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasInput => _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notifierState = ref.watch(householdSettingsNotifierProvider);
    final isSaving = notifierState.valueOrNull?.isSavingNickname ?? false;

    // 世帯切り替えで currentNickname が変化したらコントローラーを更新する
    ref.listen(householdSettingsNotifierProvider, (prev, next) {
      final prevNickname = prev?.valueOrNull?.currentNickname;
      final nextNickname = next.valueOrNull?.currentNickname;
      if (nextNickname != null && nextNickname != prevNickname) {
        setState(() {
          _controller.text = nextNickname;
        });
      }
    });

    return Card(
      key: const Key('nicknameSection'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.householdSettingsNicknameSection,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: l10n.householdSettingsNicknameLabel,
                hintText: l10n.householdSettingsNicknameHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                key: const Key('saveNicknameButton'),
                onPressed: _hasInput && !isSaving
                    ? () async {
                        await ref
                            .read(householdSettingsNotifierProvider.notifier)
                            .saveNickname(nickname: _controller.text.trim());
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
