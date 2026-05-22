import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// AC6: Google アカウント連携セクション（@gmail.com のみ表示）
class GoogleLinkSection extends StatefulWidget {
  const GoogleLinkSection({
    super.key,
    required this.isLinked,
    required this.isLinking,
    required this.onLink,
  });

  final bool isLinked;
  final bool isLinking;
  final Future<void> Function(String idToken) onLink;

  @override
  State<GoogleLinkSection> createState() => _GoogleLinkSectionState();
}

class _GoogleLinkSectionState extends State<GoogleLinkSection> {
  Future<void> _handleLink() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) return; // キャンセル

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        debugPrint('Google sign-in: idToken was null');
        return;
      }

      await widget.onLink(idToken);
    } on AppException catch (e) {
      AppSnackBar.showError(e.message);
    } catch (_) {
      debugPrint('Google sign-in failed');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackBar.showError(l10n.errorUnexpected);
      }
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
          l10n.accountSettingsGoogleSection,
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
          child: widget.isLinked
              ? _buildLinked(context, l10n, colors)
              : _buildUnlinked(context, l10n, colors),
        ),
      ],
    );
  }

  Widget _buildLinked(
    BuildContext context,
    AppLocalizations l10n,
    AppColorScheme colors,
  ) {
    return Row(
      children: [
        Container(
          key: const Key('googleLinkedBadge'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.paletteEmeraldSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.paletteEmeraldBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: colors.paletteEmeraldText,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.accountSettingsGoogleAlreadyLinked,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.paletteEmeraldText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.accountSettingsGoogleLinkedNote,
            style: TextStyle(fontSize: 13, color: colors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlinked(
    BuildContext context,
    AppLocalizations l10n,
    AppColorScheme colors,
  ) {
    if (widget.isLinking) {
      return const Center(child: CircularProgressIndicator());
    }
    return ElevatedButton.icon(
      key: const Key('googleLinkButton'),
      onPressed: _handleLink,
      icon: const Icon(Icons.login, size: 18),
      label: Text(l10n.accountSettingsGoogleLinkButton),
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.surfaceCard,
        foregroundColor: colors.textBody,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
