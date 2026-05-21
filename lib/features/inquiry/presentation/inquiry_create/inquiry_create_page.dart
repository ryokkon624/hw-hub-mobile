import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/models/inquiry_category.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import 'inquiry_create_notifier.dart';
import 'inquiry_create_state.dart';

class InquiryCreatePage extends ConsumerStatefulWidget {
  const InquiryCreatePage({super.key});

  @override
  ConsumerState<InquiryCreatePage> createState() => _InquiryCreatePageState();
}

class _InquiryCreatePageState extends ConsumerState<InquiryCreatePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final state = ref.watch(inquiryCreateNotifierProvider);

    // 送信成功後: スナックバー表示→詳細画面へ遷移
    ref.listen(inquiryCreateNotifierProvider, (prev, next) {
      if (next.createdInquiryId != null &&
          next.createdInquiryId != prev?.createdInquiryId) {
        AppSnackBar.showSuccess(l10n.inquiryCreateSuccessMessage);
        context.go(
          AppRoutes.settingsInquiryDetail(next.createdInquiryId.toString()),
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          !_isValidationError(next.errorMessage!)) {
        AppSnackBar.showError(next.errorMessage!);
      }
    });

    final categoryOptions = _buildCategoryOptions(l10n);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceCard,
        elevation: 0,
        title: Text(
          l10n.pageTitleInquiryCreate,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: colors.textHeading,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 説明文
            Text(
              l10n.inquiryCreateDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            // フォームカード
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリ
                  _buildLabel(context, l10n.inquiryCreateCategoryLabel, colors),
                  const SizedBox(height: 4),
                  _buildCategoryDropdown(
                    context,
                    l10n,
                    colors,
                    state,
                    categoryOptions,
                  ),
                  if (state.errorMessage ==
                      'inquiryCreateErrorCategoryRequired')
                    _buildError(
                      context,
                      l10n.inquiryCreateErrorCategoryRequired,
                    ),
                  const SizedBox(height: 16),

                  // 件名
                  _buildLabel(context, l10n.inquiryCreateTitleLabel, colors),
                  const SizedBox(height: 4),
                  TextField(
                    key: const Key('titleField'),
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: l10n.inquiryCreateTitleHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (v) => ref
                        .read(inquiryCreateNotifierProvider.notifier)
                        .setTitle(v),
                  ),
                  if (state.errorMessage == 'inquiryCreateErrorTitleRequired')
                    _buildError(context, l10n.inquiryCreateErrorTitleRequired)
                  else if (state.errorMessage ==
                      'inquiryCreateErrorTitleTooLong')
                    _buildError(context, l10n.inquiryCreateErrorTitleTooLong),
                  const SizedBox(height: 16),

                  // お問い合わせ内容
                  _buildLabel(context, l10n.inquiryCreateBodyLabel, colors),
                  const SizedBox(height: 4),
                  TextField(
                    key: const Key('bodyField'),
                    controller: _bodyController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: l10n.inquiryCreateBodyHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (v) => ref
                        .read(inquiryCreateNotifierProvider.notifier)
                        .setBody(v),
                  ),
                  if (state.errorMessage == 'inquiryCreateErrorBodyRequired')
                    _buildError(context, l10n.inquiryCreateErrorBodyRequired),
                  const SizedBox(height: 24),

                  // ボタン
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('cancelButton'),
                          onPressed: () =>
                              context.go(AppRoutes.settingsInquiries),
                          child: Text(l10n.inquiryCreateCancelButton),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('submitButton'),
                          onPressed: state.isSubmitting
                              ? null
                              : () => ref
                                    .read(
                                      inquiryCreateNotifierProvider.notifier,
                                    )
                                    .submit(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(l10n.inquiryCreateSubmitButton),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text, AppColorScheme colors) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colors.textHeading,
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(
    BuildContext context,
    AppLocalizations l10n,
    AppColorScheme colors,
    InquiryCreateState state,
    List<({String value, String label})> options,
  ) {
    return DropdownButtonFormField<String>(
      key: const Key('categoryDropdown'),
      initialValue: state.selectedCategory,
      hint: Text(l10n.inquiryCreateCategoryPlaceholder),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((opt) {
        return DropdownMenuItem<String>(
          value: opt.value,
          child: Text(opt.label),
        );
      }).toList(),
      onChanged: (v) =>
          ref.read(inquiryCreateNotifierProvider.notifier).setCategory(v),
    );
  }

  List<({String value, String label})> _buildCategoryOptions(
    AppLocalizations l10n,
  ) {
    return [
      (value: InquiryCategory.general.code, label: l10n.inquiryCategoryGeneral),
      (
        value: InquiryCategory.housework.code,
        label: l10n.inquiryCategoryHousework,
      ),
      (
        value: InquiryCategory.shopping.code,
        label: l10n.inquiryCategoryShopping,
      ),
      (
        value: InquiryCategory.accountSettings.code,
        label: l10n.inquiryCategoryAccount,
      ),
      (value: InquiryCategory.bugReport.code, label: l10n.inquiryCategoryBug),
    ];
  }

  bool _isValidationError(String errorMessage) {
    return [
      'inquiryCreateErrorCategoryRequired',
      'inquiryCreateErrorTitleRequired',
      'inquiryCreateErrorTitleTooLong',
      'inquiryCreateErrorBodyRequired',
    ].contains(errorMessage);
  }
}
