import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/errors.dart';
import '../../core/formatters.dart';
import '../../domain/models/models.dart';
import '../../services/tts/tts_engine.dart';

class PhrasebookPage extends ConsumerStatefulWidget {
  const PhrasebookPage({super.key});

  @override
  ConsumerState<PhrasebookPage> createState() => _PhrasebookPageState();
}

class _PhrasebookPageState extends ConsumerState<PhrasebookPage> {
  String? _playingId;

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

  Future<void> _delete(Phrase phrase) async {
    await ref.read(sessionRepositoryProvider).deletePhrase(phrase.id);
    ref.invalidate(phrasesProvider);
    if (mounted) showAppToast(context, '已删除该表达');
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('表达本', style: AppText.h1),
              const SizedBox(height: 4),
              Text('把想说的句子攒起来', style: AppText.bodySecondary),
            ],
          ),
        ),
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
              if (phrases.isEmpty) {
                return SingleChildScrollView(
                  padding: shellPagePadding,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 300,
                    child: Column(
                      children: [
                        const Expanded(
                          child: EmptyState(
                            icon: Icons.bookmark_border_rounded,
                            title: '表达本还是空的',
                            message: '复盘时把好用的句子收藏到这里，下次开口就能用上。',
                          ),
                        ),
                        SecondaryButton(
                          label: '查看练习记录',
                          icon: Icons.history_rounded,
                          onPressed: () => context.go('/history'),
                        ),
                      ],
                    ),
                  ),
                );
              }
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
                    onDelete: () => _delete(phrase),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    required this.phrase,
    required this.sourceLabel,
    required this.playing,
    required this.onPlay,
    required this.onDelete,
  });

  final Phrase phrase;
  final String? sourceLabel;
  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phrase.textEn, style: AppText.body.copyWith(height: 1.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.bookmark_rounded,
                      size: 12,
                      color: AppColors.primaryDeep,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '来自 ${sourceLabel ?? '自由练习'} · ${formatDate(DateTime.fromMillisecondsSinceEpoch(phrase.createdAt))}',
                        style: AppText.caption.copyWith(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: playing ? '停止朗读' : '朗读表达',
            child: GestureDetector(
              onTap: onPlay,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: playing ? AppColors.primaryWash : AppColors.surfaceTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 17,
                  color: playing ? AppColors.primaryDeep : AppColors.inkSecondary,
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '删除表达',
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 17,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
