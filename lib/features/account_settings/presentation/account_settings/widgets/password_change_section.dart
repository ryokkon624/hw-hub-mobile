import 'package:flutter/material.dart';

import '../../../../../core/theme/app_color_scheme.dart';
import '../../../../../l10n/app_localizations.dart';

/// AC2: パスワード変更セクション（StatefulWidget で入力検証）
class PasswordChangeSection extends StatefulWidget {
  const PasswordChangeSection({super.key, required this.onSave});

  final Future<void> Function(String currentPassword, String newPassword)
  onSave;

  @override
  State<PasswordChangeSection> createState() => _PasswordChangeSectionState();
}

class _PasswordChangeSectionState extends State<PasswordChangeSection> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _currentController.text.isNotEmpty &&
      _newController.text.length >= 8 &&
      _newController.text == _confirmController.text;

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.onSave(_currentController.text, _newController.text);
      if (mounted) {
        _currentController.clear();
        _newController.clear();
        _confirmController.clear();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountSettingsPasswordSection,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PasswordField(
                controller: _currentController,
                label: l10n.accountSettingsCurrentPassword,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _newController,
                label: l10n.accountSettingsNewPassword,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirmController,
                label: l10n.accountSettingsNewPasswordConfirm,
                onChanged: (_) => setState(() {}),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: colors.danger, fontSize: 13),
                ),
              ],
              if (_newController.text.isNotEmpty &&
                  _confirmController.text.isNotEmpty &&
                  _newController.text != _confirmController.text) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.accountSettingsPasswordMismatch,
                  style: TextStyle(color: colors.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _canSave && !_isSaving ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.accountSettingsChangePasswordButton),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return TextField(
      controller: controller,
      obscureText: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: colors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
