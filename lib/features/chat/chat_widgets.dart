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

/// 提示结果只展示，不自动发送、不写入对话历史。
class HintResultCard extends StatelessWidget {
  const HintResultCard({
    super.key,
    required this.level,
    required this.text,
    required this.error,
    required this.loading,
    required this.onClose,
    required this.onRetry,
  });

  final int? level;
  final String? text;
  final String? error;
  final bool loading;
  final VoidCallback onClose;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!loading && text == null && error == null) return const SizedBox.shrink();
    return AppCard(
      color: AppColors.primaryWash,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.primaryDeep),
              const SizedBox(width: 6),
              Text('L${level ?? 2} 提示', style: AppText.tag.copyWith(color: AppColors.primaryDeep)),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, size: 16, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (loading)
            Row(
              children: [
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text('正在准备提示…', style: AppText.caption),
              ],
            )
          else if (error != null)
            Row(
              children: [
                Expanded(child: Text(error!, style: AppText.caption.copyWith(color: AppColors.error))),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('重试', style: AppText.caption.copyWith(color: AppColors.primaryDeep)),
                ),
              ],
            )
          else ...[
            Text(text!, style: AppText.body.copyWith(height: 1.5)),
            const SizedBox(height: 6),
            Text('仅作参考，不会替你发送；请自己开口或点发送。', style: AppText.caption),
          ],
        ],
      ),
    );
  }
}

/// L1–L4 提示阶梯的入口 Sheet。
Future<void> showHintSheet(
  BuildContext context, {
  required ConversationController controller,
}) {
  return showAppSheet<void>(
    context: context,
    title: '卡住了？一步一步来',
    child: _HintSheetBody(controller: controller),
  );
}

class _HintSheetBody extends StatefulWidget {
  const _HintSheetBody({required this.controller});

  final ConversationController controller;

  @override
  State<_HintSheetBody> createState() => _HintSheetBodyState();
}

class _HintSheetBodyState extends State<_HintSheetBody> {
  final _chinese = TextEditingController();
  int _level = 1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // Controller 可能在页面 build 期间通知（例如弹层刚打开时），
    // 把重建推迟到当前帧结束，避免 setState() during build。
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

  Future<void> _request(int level) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.controller.requestHint(level, chinese: _chinese.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (widget.controller.hintError == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('提示是阶梯，不直接替你说话；任一级都不会自动发送。', style: AppText.caption),
          const SizedBox(height: 12),
          _HintOption(
            level: 1,
            selected: _level == 1,
            icon: Icons.replay_rounded,
            title: 'L1 · 重听 / 慢速',
            subtitle: '不给答案，只把 AI 上一句放慢再读一遍',
            onTap: () => setState(() => _level = 1),
          ),
          _HintOption(
            level: 2,
            selected: _level == 2,
            icon: Icons.keyboard_alt_outlined,
            title: 'L2 · 关键词 / 句型',
            subtitle: '给 3–5 个词或一个句型，不给完整句',
            onTap: () => setState(() => _level = 2),
          ),
          _HintOption(
            level: 3,
            selected: _level == 3,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'L3 · 参考回答',
            subtitle: '给 1 句完整英文，要你自己说出来',
            onTap: () => setState(() => _level = 3),
          ),
          _HintOption(
            level: 4,
            selected: _level == 4,
            icon: Icons.translate_rounded,
            title: 'L4 · 中 → 英',
            subtitle: '写下中文意思，给一句可以直接说的英文',
            onTap: () => setState(() => _level = 4),
          ),
          if (_level == 4) ...[
            const SizedBox(height: 12),
            AppTextField(
              controller: _chinese,
              label: '我想说的中文',
              hint: '例如：我想确认一下会议改到几点',
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: _level == 1 ? '慢速重听' : '获取 L$_level 提示',
            icon: Icons.lightbulb_outline_rounded,
            loading: _busy,
            onPressed: _busy ? null : () => _request(_level),
          ),
          if (widget.controller.hintError != null) ...[
            const SizedBox(height: 8),
            ErrorBanner(message: widget.controller.hintError!),
          ],
        ],
      ),
    );
  }
}

class _HintOption extends StatelessWidget {
  const _HintOption({
    required this.level,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int level;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.primaryWash : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: selected ? AppColors.primaryDeep : AppColors.inkMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.primaryDeep : AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.caption),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
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
