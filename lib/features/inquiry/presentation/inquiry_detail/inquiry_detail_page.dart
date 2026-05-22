import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_router.dart';
import '../../../../core/models/inquiry_status.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/ui/app_dialog.dart';
import '../../../../core/ui/app_snack_bar.dart';
import '../../../../core/ui/main_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/inquiry_category_badge.dart';
import '../widgets/inquiry_status_badge.dart';
import '../../inquiry_providers.dart';
import 'widgets/message_bubble.dart';

class InquiryDetailPage extends ConsumerStatefulWidget {
  const InquiryDetailPage({super.key, required this.inquiryId});

  final int inquiryId;

  @override
  ConsumerState<InquiryDetailPage> createState() => _InquiryDetailPageState();
}

class _InquiryDetailPageState extends ConsumerState<InquiryDetailPage> {
  late final TextEditingController _replyController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppColorScheme>()!;
    final state = ref.watch(inquiryDetailNotifierProvider(widget.inquiryId));

    ref.listen(inquiryDetailNotifierProvider(widget.inquiryId), (prev, next) {
      if (next.fetchFailed && !(prev?.fetchFailed ?? false)) {
        // 取得失敗時: 問い合わせ一覧へリダイレクト
        context.go(AppRoutes.settingsInquiries);
        return;
      }
      if (next.replySent && !(prev?.replySent ?? false)) {
        _replyController.clear();
        ref
            .read(inquiryDetailNotifierProvider(widget.inquiryId).notifier)
            .clearReplySent();
        AppSnackBar.showSuccess(l10n.inquiryDetailReplySentMessage);
        _scrollToBottom();
      }
      if (next.closed && !(prev?.closed ?? false)) {
        AppSnackBar.showSuccess(l10n.inquiryDetailClosedMessage);
      }
      if (next.escalated && !(prev?.escalated ?? false)) {
        AppSnackBar.showSuccess(l10n.inquiryDetailEscalatedMessage);
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          !next.fetchFailed) {
        AppSnackBar.showError(next.errorMessage!);
      }
    });

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: MainAppBar(title: l10n.pageTitleInquiryDetail),
      body: _buildBody(context, state, l10n, colors),
    );
  }

  Widget _buildBody(
    BuildContext context,
    InquiryDetailState state,
    AppLocalizations l10n,
    AppColorScheme colors,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.fetchFailed || state.detail == null) {
      return Center(
        key: const Key('errorState'),
        child: Text(
          state.errorMessage ?? l10n.inquiryDetailErrorMessage,
          style: TextStyle(color: colors.textMuted),
        ),
      );
    }

    final detail = state.detail!;
    final status = InquiryStatus.fromCode(detail.status);
    final isClosed = status == InquiryStatus.closed;
    final canEscalate = status == InquiryStatus.aiAnswered;

    return Column(
      children: [
        // ヘッダー情報
        Container(
          key: const Key('detailHeader'),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceCard,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${detail.inquiryId}: ${detail.title}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textHeading,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  InquiryCategoryBadge(categoryCode: detail.category),
                  const SizedBox(width: 8),
                  InquiryStatusBadge(statusCode: detail.status),
                ],
              ),
              const SizedBox(height: 8),
              // ステータス説明
              Text(
                _statusDescription(status, l10n),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),

        // メッセージ一覧
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(inquiryDetailNotifierProvider(widget.inquiryId).notifier)
                .reload(),
            child: detail.messages.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Center(
                        key: const Key('noMessages'),
                        child: Text(
                          '',
                          style: TextStyle(color: colors.textMuted),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    key: const Key('messageList'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: detail.messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return MessageBubble(
                        key: ValueKey(detail.messages[index].messageId),
                        message: detail.messages[index],
                      );
                    },
                  ),
          ),
        ),

        // 返信エリア（クローズ済みは非表示）
        if (!isClosed) ...[
          Container(
            key: const Key('replyArea'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceCard,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Column(
              children: [
                // アクションボタン
                if (canEscalate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const Key('escalateButton'),
                        onPressed: () => _confirmEscalate(context, l10n),
                        child: Text(l10n.inquiryDetailEscalateButton),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('replyField'),
                        controller: _replyController,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: l10n.inquiryDetailReplyPlaceholder,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _replyController,
                      builder: (context, value, _) {
                        final canSend = value.text.trim().isNotEmpty;
                        return ElevatedButton(
                          key: const Key('sendButton'),
                          onPressed: canSend ? () => _sendReply() : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(l10n.inquiryDetailSendButton),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // クローズボタン
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('closeButton'),
                    onPressed: () => _confirmClose(context, l10n),
                    child: Text(l10n.inquiryDetailResolvedButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    await ref
        .read(inquiryDetailNotifierProvider(widget.inquiryId).notifier)
        .sendReply(body);
  }

  Future<void> _confirmClose(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.inquiryDetailCloseConfirmTitle,
      message: l10n.inquiryDetailCloseConfirmBody,
      confirmLabel: l10n.inquiryDetailResolvedButton,
      cancelLabel: l10n.commonCancel,
    );
    if (confirmed) {
      await ref
          .read(inquiryDetailNotifierProvider(widget.inquiryId).notifier)
          .close();
    }
  }

  Future<void> _confirmEscalate(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: l10n.inquiryDetailEscalateConfirmTitle,
      message: l10n.inquiryDetailEscalateConfirmBody,
      confirmLabel: l10n.inquiryDetailEscalateButton,
      cancelLabel: l10n.commonCancel,
    );
    if (confirmed) {
      await ref
          .read(inquiryDetailNotifierProvider(widget.inquiryId).notifier)
          .escalate();
    }
  }

  String _statusDescription(InquiryStatus? status, AppLocalizations l10n) {
    return switch (status) {
      InquiryStatus.open => l10n.inquiryDetailStatusOpen,
      InquiryStatus.aiAnswered => l10n.inquiryDetailStatusAiAnswered,
      InquiryStatus.pendingStaff => l10n.inquiryDetailStatusPendingStaff,
      InquiryStatus.staffAnswered => l10n.inquiryDetailStatusStaffAnswered,
      InquiryStatus.closed => l10n.inquiryDetailStatusClosed,
      null => '',
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
