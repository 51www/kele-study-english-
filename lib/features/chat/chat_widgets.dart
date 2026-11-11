import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/errors.dart';
import '../../domain/models/models.dart';
import 'conversation_controller.dart';
import 'copy.dart';

/// 翻译三态：关闭（默认）/ 点按 / 常开双语字幕。
class TranslateModePicker extends StatelessWidget {
  const TranslateModePicker({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final String mode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final index = switch (mode) {
      'tap' => 1,
      'always' => 2,
      _ => 0,
    };
    return Row(
      children: [
        Text('翻译', style: AppText.caption.copyWith(fontSize: 11, color: AppColors.inkSecondary)),
        const SizedBox(width: 10),
        Expanded(
          child: SegmentedControl(
            items: const ['关闭', '点按', '常开'],
            index: index,
            onChanged: (i) => onChanged(const ['off', 'tap', 'always'][i]),
          ),
        ),
      ],
    );
  }
}

/// 按错误四分类给出不同文案与下一步操作。
class ChatErrorBanner extends StatelessWidget {
  const ChatErrorBanner({
    super.key,
    required this.error,
    required this.kind,
    this.onRetry,
    this.onConfig,
    this.onText,
  });

  final String error;
  final AppErrorKind? kind;
  final VoidCallback? onRetry;
  final VoidCallback? onConfig;
  final VoidCallback? onText;

  @override
  Widget build(BuildContext context) {
    final view = describeChatError(kind ?? AppErrorKind.unknown, error);
    VoidCallback? action;
    switch (view.action) {
      case ChatErrorAction.retry:
        action = onRetry;
        break;
      case ChatErrorAction.config:
        action = onConfig;
        break;
      case ChatErrorAction.text:
        action = onText;
        break;
      case ChatErrorAction.none:
        action = null;
        break;
    }
    return ErrorBanner(
      message: view.message,
      onRetry: action,
      retryLabel: view.actionLabel ?? '重试',
    );
  }
}

/// 提示面板：整块内联在对话页里，打开即给 L3 参考答案。
///
/// 不再展示 L1–L4 工具项，也不使用底部弹层；结果只放内存，
/// 不自动发送、不写入对话历史。
class InlineHintPanel extends StatelessWidget {
  const InlineHintPanel({
    super.key,
    required this.controller,
    required this.onClose,
  });

  final ConversationController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final hasResult = c.hintLoading || c.hintError != null || c.hasHint;
    return AppCard(
      color: AppColors.primaryWash,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 15, color: AppColors.primaryDeep),
              const SizedBox(width: 6),
              Text(
                '卡住了？给你一个参考答案',
                style: AppText.caption.copyWith(color: AppColors.primaryDeep, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.inkMuted),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: hasResult
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _HintResult(controller: c, onRetry: () => c.requestHint(3)),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _HintResult extends StatelessWidget {
  const _HintResult({required this.controller, required this.onRetry});

  final ConversationController controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.hintLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Text('正在准备参考答案…', style: AppText.caption),
        ],
      );
    }
    if (c.hintError != null) {
      return ErrorBanner(message: c.hintError!, onRetry: onRetry);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primaryTint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '参考答案',
            style: AppText.tag.copyWith(color: AppColors.primaryDeep),
          ),
          const SizedBox(height: 6),
          Text(c.hintText ?? '', style: AppText.body.copyWith(height: 1.5)),
          if (c.hintTextZh != null && c.hintTextZh!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              c.hintTextZh!,
              style: AppText.caption.copyWith(color: AppColors.inkSecondary, height: 1.5),
            ),
          ],
          const SizedBox(height: 6),
          Text('仅作参考，不会替你发送；请自己开口或点发送。', style: AppText.caption),
        ],
      ),
    );
  }
}

/// 「我想说」：中文 → 一句英文建议，用户自己决定是否填入输入框并发送。
Future<void> showWantToSaySheet(
  BuildContext context, {
  required ConversationController controller,
  required ValueChanged<String> onUse,
}) {
  // 在用户事件回调里清空，不在弹层 initState 里通知，避免 build 期间重建。
  controller.clearWantToSay();
  return showAppSheet<void>(
    context: context,
    title: '我想说…',
    child: _WantToSayBody(controller: controller, onUse: onUse),
  );
}

class _WantToSayBody extends StatefulWidget {
  const _WantToSayBody({required this.controller, required this.onUse});

  final ConversationController controller;
  final ValueChanged<String> onUse;

  @override
  State<_WantToSayBody> createState() => _WantToSayBodyState();
}

class _WantToSayBodyState extends State<_WantToSayBody> {
  final _chinese = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _chinese.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('输入中文，给一句能直接开口说的英文。不会自动发送。', style: AppText.caption),
          const SizedBox(height: 12),
          AppTextField(
            controller: _chinese,
            label: '中文想说的话',
            hint: '例如：我没听清，可以再说一遍吗？',
            maxLines: 2,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: '给一句英文',
            icon: Icons.translate_rounded,
            loading: c.wantToSayLoading,
            onPressed: c.wantToSayLoading
                ? null
                : () => c.requestWantToSay(_chinese.text),
          ),
          if (c.wantToSayError != null) ...[
            const SizedBox(height: 10),
            ErrorBanner(message: c.wantToSayError!),
          ],
          if (c.wantToSayText != null) ...[
            const SizedBox(height: 14),
            AppCard(
              color: AppColors.primaryWash,
              shadow: false,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('可以这样说', style: AppText.caption.copyWith(color: AppColors.primaryDeep)),
                  const SizedBox(height: 6),
                  Text(c.wantToSayText!, style: AppText.body.copyWith(height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: '填入输入框（不会发送）',
              icon: Icons.edit_outlined,
              onPressed: () {
                widget.onUse(c.wantToSayText!);
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// 用户气泡下的纠错展开：原句 / 改进句 / 中文原因 + 试听 + 删除。
class CorrectionPanel extends StatelessWidget {
  const CorrectionPanel({
    super.key,
    required this.corrections,
    this.playingId,
    required this.onPlay,
    required this.onDelete,
  });

  final List<Correction> corrections;
  final String? playingId;
  final ValueChanged<Correction> onPlay;
  final ValueChanged<Correction> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: corrections.map((item) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('原句：${item.original}', style: AppText.caption),
              const SizedBox(height: 4),
              Text('更好的说法：${item.improved}', style: AppText.body),
              const SizedBox(height: 4),
              Text(item.reasonZh, style: AppText.caption.copyWith(color: AppColors.inkSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MiniAction(
                    icon: playingId == item.id ? Icons.stop_rounded : Icons.volume_up_rounded,
                    label: playingId == item.id ? '停止' : '试听',
                    onTap: () => onPlay(item),
                  ),
                  const SizedBox(width: 8),
                  _MiniAction(
                    icon: Icons.delete_outline_rounded,
                    label: '删除',
                    onTap: () => onDelete(item),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.primaryDeep),
            const SizedBox(width: 4),
            Text(label, style: AppText.caption.copyWith(fontSize: 10, color: AppColors.primaryDeep)),
          ],
        ),
      ),
    );
  }
}
