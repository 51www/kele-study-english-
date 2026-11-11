import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/formatters.dart';
import '../../domain/models/models.dart';
import '../../services/tts/tts_engine.dart';

/// 表达本：既收纳复盘里收藏的句子，也可以自己新建、编辑、试听和管理。
///
/// 空态不再是「只能等复盘」的死胡同：顶部常驻「添加表达」，
/// 空态里还有一键添加 + 常用表达推荐，保证板块始终有内容可看、有入口可加。
class PhrasebookPage extends ConsumerStatefulWidget {
  const PhrasebookPage({super.key});

  @override
  ConsumerState<PhrasebookPage> createState() => _PhrasebookPageState();
}

class _PhrasebookPageState extends ConsumerState<PhrasebookPage> {
  final _en = TextEditingController();
  final _zh = TextEditingController();
  String? _playingId;
  bool _formOpen = false;
  Phrase? _editing;

  static const _suggestions = <(String, String)>[
    ('Could you say that again, please?', '能再说一遍吗？'),
    ('Let me think about it for a second.', '让我想一下。'),
    ('That works for me.', '我这边没问题。'),
  ];

  @override
  void dispose() {
    _en.dispose();
    _zh.dispose();
    super.dispose();
  }

  Future<void> _play(Phrase phrase) async {
    if (_playingId == phrase.id) {
      await ref.read(ttsRouterProvider).stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = phrase.id);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref.read(ttsRouterProvider).speak(
            phrase.textEn,
            voice: settings.getString(SettingsKeys.ttsVoice, 'en-US-AriaNeural'),
            rate: settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0),
            preferEdge: settings.getString(SettingsKeys.ttsEngine, 'edge') != 'system',
          );
    } on TtsException {
      if (mounted) showAppToast(context, '朗读暂不可用', error: true);
    } finally {
      if (mounted) setState(() => _playingId = null);
    }
  }

  void _openForm([Phrase? phrase]) {
    _editing = phrase;
    _en.text = phrase?.textEn ?? '';
    _zh.text = phrase?.textZh ?? '';
    setState(() => _formOpen = true);
  }

  void _closeForm() {
    setState(() {
      _formOpen = false;
      _editing = null;
    });
  }

  Future<void> _save() async {
    final english = _en.text.trim();
    if (english.isEmpty) {
      showAppToast(context, '先写一句英文表达', error: true);
      return;
    }
    final chinese = _zh.text.trim();
    final now = DateTime.now();
    final existing = _editing;
    final phrase = existing == null
        ? Phrase(
            id: 'p_${now.microsecondsSinceEpoch}',
            textEn: english,
            textZh: chinese.isEmpty ? null : chinese,
            createdAt: now.millisecondsSinceEpoch,
          )
        : existing.copyWith(
            textEn: english,
            textZh: chinese.isEmpty ? null : chinese,
          );
    await ref.read(sessionRepositoryProvider).savePhrase(phrase);
    ref.invalidate(phrasesProvider);
    _closeForm();
    if (mounted) {
      showAppToast(context, existing == null ? '已添加表达' : '已更新表达');
    }
  }

  Future<void> _quickAdd(String english, String chinese) async {
    final now = DateTime.now();
    await ref.read(sessionRepositoryProvider).savePhrase(Phrase(
          id: 'p_${now.microsecondsSinceEpoch}',
          textEn: english,
          textZh: chinese,
          createdAt: now.millisecondsSinceEpoch,
        ));
    ref.invalidate(phrasesProvider);
    if (mounted) showAppToast(context, '已添加表达');
  }

  Future<void> _delete(Phrase phrase) async {
    final ok = await showConfirmDialog(
      context,
      title: '移出表达本？',
      message: '「${phrase.textEn}」会被删除，不影响原来的练习记录。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok) return;
    await ref.read(sessionRepositoryProvider).deletePhrase(phrase.id);
    ref.invalidate(phrasesProvider);
    if (mounted) showAppToast(context, '已删除该表达');
  }

  Future<void> _toggleMastered(Phrase phrase) async {
    await ref.read(sessionRepositoryProvider).savePhrase(
          phrase.copyWith(mastered: !phrase.mastered),
        );
    ref.invalidate(phrasesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(phrasesProvider);
    final scenarios = ref.watch(homeDataProvider).asData?.value.scenarios ?? const <Scenario>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('表达本', style: AppText.h1),
                    const SizedBox(height: 4),
                    Text('把想说的句子攒起来', style: AppText.bodySecondary),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _openForm(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWash,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.primaryTint),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryDeep),
                      const SizedBox(width: 4),
                      Text(
                        '添加表达',
                        style: AppText.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_formOpen) _buildForm(),
        const SizedBox(height: 12),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorBanner(
                  message: '加载表达本失败：$error',
                  onRetry: () => ref.invalidate(phrasesProvider),
                ),
              ),
            ),
            data: (phrases) {
              if (phrases.isEmpty) return _buildEmpty();
              return ListView.separated(
                padding: shellPagePadding,
                itemCount: phrases.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final phrase = phrases[index];
                  final scenario =
                      scenarios.where((e) => e.id == phrase.sourceScenarioId).firstOrNull;
                  return _PhraseCard(
                    phrase: phrase,
                    sourceLabel: scenario?.titleZh,
                    playing: _playingId == phrase.id,
                    onPlay: () => _play(phrase),
                    onEdit: () => _openForm(phrase),
                    onDelete: () => _delete(phrase),
                    onToggleMastered: () => _toggleMastered(phrase),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _editing == null ? '添加一句表达' : '编辑表达',
                  style: AppText.cardTitle,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _closeForm,
                  child: const Icon(Icons.close_rounded, size: 17, color: AppColors.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _en,
              label: '英文表达',
              hint: '例如：Could you say that again, please?',
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _zh,
              label: '中文意思（选填）',
              hint: '例如：能再说一遍吗？',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: '取消',
                    height: 40,
                    onPressed: _closeForm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: '保存',
                    icon: Icons.check_rounded,
                    height: 40,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return SingleChildScrollView(
      padding: shellPagePadding,
      child: Column(
        children: [
          const SizedBox(height: 24),
          const EmptyState(
            icon: Icons.bookmark_border_rounded,
            title: '表达本还是空的',
            message: '点右上角「添加表达」自己记一句，或复盘时收藏好用的句子。',
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: '添加一句表达',
            icon: Icons.add_rounded,
            onPressed: () => _openForm(),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: '查看练习记录',
            icon: Icons.history_rounded,
            onPressed: () => context.go('/history'),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('试试这些常用表达', style: AppText.section),
          ),
          const SizedBox(height: 10),
          ..._suggestions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                shadow: false,
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: AppText.body.copyWith(height: 1.4)),
                          const SizedBox(height: 3),
                          Text(item.$2, style: AppText.caption),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _quickAdd(item.$1, item.$2),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryWash,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 17,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    required this.phrase,
    required this.sourceLabel,
    required this.playing,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleMastered,
  });

  final Phrase phrase;
  final String? sourceLabel;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleMastered;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phrase.textEn, style: AppText.body.copyWith(height: 1.5)),
          if (phrase.textZh != null && phrase.textZh!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              phrase.textZh!,
              style: AppText.caption.copyWith(color: AppColors.inkSecondary),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bookmark_rounded, size: 12, color: AppColors.primaryDeep),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '来自 ${sourceLabel ?? '自由练习'} · ${formatDate(DateTime.fromMillisecondsSinceEpoch(phrase.createdAt))}',
                  style: AppText.caption.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (phrase.mastered)
                const AppTag(label: '已掌握', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _IconAction(
                icon: playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                label: playing ? '停止朗读' : '朗读表达',
                onTap: onPlay,
                active: playing,
              ),
              _IconAction(
                icon: Icons.edit_outlined,
                label: '编辑表达',
                onTap: onEdit,
              ),
              _IconAction(
                icon: phrase.mastered ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                label: phrase.mastered ? '取消已掌握' : '标记已掌握',
                onTap: onToggleMastered,
                active: phrase.mastered,
              ),
              _IconAction(
                icon: Icons.delete_outline_rounded,
                label: '删除表达',
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryWash : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: active ? AppColors.primaryDeep : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
