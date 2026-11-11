import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text.dart';
import '../../../app/widgets/common.dart';
import '../../../domain/models/dictation_models.dart';
import '../../../domain/models/models.dart';
import '../../../services/audio/clip_player.dart';
import '../providers.dart';
import '../repository/material_repository.dart';
import '../scoring/dictation_scorer.dart';
import '../widgets/word_diff_view.dart';

/// 单句听写（`/materials/:id/dictation?mode=all|wrong`）。
///
/// 独立链路：不写对话历史、不生成复盘、不改首页统计；判分纯离线。
class DictationPage extends ConsumerStatefulWidget {
  const DictationPage({super.key, required this.materialId, this.mode = 'all'});

  final String materialId;
  final String mode;

  @override
  ConsumerState<DictationPage> createState() => _DictationPageState();
}

class _DictationPageState extends ConsumerState<DictationPage> {
  final TextEditingController _input = TextEditingController();
  ClipPlayerService? _player;
  final Map<String, MaterialItem> _materials = <String, MaterialItem>{};
  List<MaterialSegment> _segments = <MaterialSegment>[];
  int _index = 0;
  int _runPassed = 0;
  int _runSubmitted = 0;
  double _speed = 1.0;
  ScoringOptions _options = const ScoringOptions();
  ScoringResult? _result;
  bool _showAnswer = false;
  bool _ready = false;
  bool _listening = false;
  String? _fatal;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 与 MVP 朗读共用一个音频焦点：进页先停掉全局 TTS，避免两段音频叠加。
    ref.read(audioPlayerProvider).stop();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _player?.dispose();
    if (_listening) ref.read(asrEngineProvider).cancel();
    _input.dispose();
    _savePosition();
    super.dispose();
  }

  /// 跨教材「只练全部错句」用独立的进度键，不与单本教材混在一起。
  String get _positionKey =>
      widget.materialId == 'all' ? 'all-wrong' : widget.materialId;

  Future<void> _load() async {
    try {
      final repo = ref.read(materialRepositoryProvider);
      final settings = ref.read(settingsControllerProvider);
      final threshold =
          (int.tryParse(settings[SettingsKeys.dictationPassThreshold] ?? '90') ?? 90) / 100;
      _options = ScoringOptions(
        passThreshold: threshold.clamp(0.5, 1.0).toDouble(),
        contractionEquivalent:
            (settings[SettingsKeys.dictationContractionEquivalent] ?? 'true') == 'true',
        numberEquivalent:
            (settings[SettingsKeys.dictationNumberEquivalent] ?? 'true') == 'true',
      );
      _speed = double.tryParse(settings[SettingsKeys.dictationSpeed] ?? '1.0') ?? 1.0;

      late List<MaterialSegment> segments;
      if (widget.materialId == 'all') {
        final wrong = await repo.wrongSegments();
        segments = wrong.map((entry) => entry.segment).toList();
        for (final entry in wrong) {
          _materials[entry.material.id] = entry.material;
        }
      } else {
        final detail = await repo.detail(widget.materialId);
        if (detail == null) throw Exception('教材不存在，请返回教材库重新导入。');
        _materials[detail.material.id] = detail.material;
        segments = detail.segments;
        if (widget.mode == 'wrong') {
          segments = segments.where((segment) {
            final attempt = detail.latestBySegment[segment.id];
            return attempt != null && !attempt.passed;
          }).toList();
        }
      }
      if (segments.isEmpty) {
        setState(() {
          _ready = true;
          _fatal = widget.mode == 'wrong'
              ? '目前没有错句，先把几句听完再来复练吧。'
              : '这份教材还没有可练的句子。';
        });
        return;
      }
      final position = await repo.position(_positionKey);
      _segments = segments;
      _index = (position.mode == widget.mode ? position.index : 0).clamp(0, segments.length - 1);
      _player = ClipPlayerService();
      setState(() => _ready = true);
      await _loadClip();
    } on Object catch (e) {
      setState(() {
        _ready = true;
        _fatal = '$e';
      });
    }
  }

  Future<void> _loadClip() async {
    final player = _player;
    if (player == null) return;
    final segment = _segments[_index];
    final material = _materials[segment.materialId];
    if (material == null) {
      if (mounted) setState(() => _error = '找不到这句所属的教材，请返回重新进入。');
      return;
    }
    try {
      final uri = ref.read(materialImportServiceProvider).playableUri(material);
      await player.load(
        uri,
        startMs: segment.startMs,
        endMs: segment.endMs,
        speed: _speed,
      );
      if (mounted) setState(() => _error = null);
      await player.replay();
    } on Object catch (e) {
      if (mounted) setState(() => _error = '这句暂时播不出来：$e');
    }
  }

  Future<void> _savePosition() async {
    await ref.read(materialRepositoryProvider).savePosition(
          _positionKey,
          DictationPosition(index: _index, mode: widget.mode),
        );
  }

  Future<void> _moveTo(int index) async {
    if (index < 0 || index >= _segments.length) return;
    setState(() {
      _index = index;
      _result = null;
      _showAnswer = false;
      _error = null;
      _input.clear();
    });
    await _loadClip();
    await _savePosition();
  }

  Future<void> _submit() async {
    if (_result != null) return;
    final segment = _segments[_index];
    final result = DictationScorer.score(
      segment.textEn,
      _input.text,
      options: _options,
    );
    final attempt = DictationAttempt(
      id: const Uuid().v4(),
      materialId: segment.materialId,
      segmentId: segment.id,
      userText: _input.text,
      accuracy: result.accuracy,
      passed: result.passed,
      diffJson: WordDiff.encode(result.diffs),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.read(materialRepositoryProvider).saveAttempt(attempt);
    ref.invalidate(materialDetailProvider(segment.materialId));
    ref.invalidate(materialLibraryProvider);
    ref.invalidate(wrongSegmentsProvider);
    if (!mounted) return;
    setState(() {
      _result = result;
      _showAnswer = false;
      _runSubmitted++;
      if (result.passed) _runPassed++;
    });
  }

  Future<void> _toggleSpeed() async {
    setState(() => _speed = _speed == 1.0 ? 0.75 : 1.0);
    await _player?.setSpeed(_speed);
  }

  Future<void> _toggleVoice() async {
    final engine = ref.read(asrEngineProvider);
    if (_listening) {
      try {
        final text = await engine.stop();
        if (text.isNotEmpty) {
          final current = _input.text.trim();
          _input.text = current.isEmpty ? text : '$current $text';
        } else if (mounted) {
          showAppToast(context, '没听清，直接用键盘接着写就行', error: true);
        }
      } on Object {
        if (mounted) showAppToast(context, '识别失败，输入内容还在，继续用键盘写吧', error: true);
      }
      if (mounted) setState(() => _listening = false);
      return;
    }
    await _player?.pause();
    final available = await engine.initialize();
    if (!available) {
      if (mounted) showAppToast(context, '这台设备没有可用的语音识别，直接用键盘写就行', error: true);
      return;
    }
    try {
      await engine.start();
      if (mounted) setState(() => _listening = true);
    } on Object {
      if (mounted) showAppToast(context, '没能开始识别，输入内容还在，继续用键盘写吧', error: true);
    }
  }

  Future<void> _toggleHard() async {
    final segment = _segments[_index];
    await ref.read(materialRepositoryProvider).toggleHard(segment.materialId, segment.id);
    if (!mounted) return;
    setState(() {
      final next = [..._segments];
      next[_index] = segment.copyWith(isHard: !segment.isHard);
      _segments = next;
    });
    ref.invalidate(materialDetailProvider(widget.materialId));
  }

  Future<void> _storePhrase() async {
    final segment = _segments[_index];
    await ref.read(localStoreProvider).upsertPhrase(
          Phrase(
            id: const Uuid().v4(),
            textEn: segment.textEn,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    ref.invalidate(phrasesProvider);
    if (mounted) showAppToast(context, '已存入表达本');
  }

  Future<void> _finish() async {
    await _savePosition();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(widget.materialId == 'all'
          ? '/materials/wrong'
          : '/materials/${widget.materialId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: widget.materialId == 'all'
          ? '只练错句（全部教材）'
          : (widget.mode == 'wrong' ? '只练错句' : '单句听写'),
      onBack: _finish,
      child: !_ready
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _fatal != null
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    AppCard(
                      child: EmptyState(
                        icon: Icons.hearing_outlined,
                        title: '暂时练不了',
                        message: _fatal!,
                        action: _finish,
                        actionLabel: '返回教材',
                      ),
                    ),
                  ],
                )
              : _buildPractice(context),
    );
  }

  Widget _buildPractice(BuildContext context) {
    final segment = _segments[_index];
    final result = _result;
    final isLast = _index == _segments.length - 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        // 唯一主视觉：一句的播放控制条，序列编号是真实顺序。
        AppCard(
          color: AppColors.primaryWash,
          shadow: false,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '第 ${(_index + 1).toString().padLeft(2, '0')} / '
                    '${_segments.length.toString().padLeft(2, '0')} 句',
                    style: AppText.caption.copyWith(color: AppColors.primaryDeep),
                  ),
                  const Spacer(),
                  Text('${segment.wordCount} 个词', style: AppText.caption),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundControl(
                    label: '${_speed == 1.0 ? '1.0' : '0.75'}x',
                    onTap: _toggleSpeed,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _loadClip,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _RoundControl(icon: Icons.replay_rounded, onTap: _loadClip),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<Duration>(
                stream: _player?.positionStream,
                initialData: Duration.zero,
                builder: (context, snapshot) {
                  final total = _player?.clipLength.inMilliseconds ?? 0;
                  final value = total <= 0
                      ? 0.0
                      : ((snapshot.data?.inMilliseconds ?? 0) / total)
                          .clamp(0.0, 1.0)
                          .toDouble();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      backgroundColor: AppColors.line,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(message: _error!, onRetry: _loadClip),
        ],
        const SizedBox(height: 16),
        AppTextField(
          controller: _input,
          hint: '把你听到的一句写下来',
          maxLines: 3,
          enabled: result == null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: result == null ? '提交这句' : '已提交',
                onPressed: result == null ? _submit : null,
              ),
            ),
            const SizedBox(width: 10),
            _RoundControl(
              icon: _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
              onTap: _toggleVoice,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_options.describe(), style: AppText.caption.copyWith(height: 1.6)),
        if (result != null) ...[
          const SizedBox(height: 20),
          _ResultCard(
            result: result,
            onReplay: _loadClip,
            onShowAnswer: () => setState(() => _showAnswer = !_showAnswer),
            showAnswer: _showAnswer,
            onStorePhrase: _showAnswer ? _storePhrase : null,
            onNext: isLast ? _finish : () => _moveTo(_index + 1),
            nextLabel: isLast ? '完成本轮' : '下一句',
          ),
          if (_showAnswer) ...[
            const SizedBox(height: 12),
            AppCard(
              color: AppColors.primaryWash,
              shadow: false,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('原句', style: AppText.caption),
                  const SizedBox(height: 6),
                  Text(segment.textEn, style: AppText.body.copyWith(height: 1.5)),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _index > 0 ? () => _moveTo(_index - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: Text('上一句', style: AppText.caption),
            ),
            Text('本轮 $_runPassed / $_runSubmitted 通过', style: AppText.caption),
            TextButton(
              onPressed: _toggleHard,
              child: Text(
                segment.isHard ? '取消太难' : '这句太难',
                style: AppText.caption.copyWith(color: AppColors.primaryDeep),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({this.icon, this.label, required this.onTap});

  final IconData? icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 16, color: AppColors.inkSecondary)
            : Text(label ?? '', style: AppText.caption.copyWith(fontSize: 9)),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.onReplay,
    required this.onShowAnswer,
    required this.showAnswer,
    required this.onStorePhrase,
    required this.onNext,
    required this.nextLabel,
  });

  final ScoringResult result;
  final VoidCallback onReplay;
  final VoidCallback onShowAnswer;
  final bool showAnswer;
  final VoidCallback? onStorePhrase;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('正确率 ${result.accuracyLabel}', style: AppText.h2),
              const Spacer(),
              AppTag(
                label: result.passed ? '通过' : '再听一次',
                color: result.passed ? AppColors.success : AppColors.warning,
                background: result.passed
                    ? AppColors.mint.withValues(alpha: 0.28)
                    : AppColors.warning.withValues(alpha: 0.10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(result.explanation, style: AppText.caption),
          const SizedBox(height: 12),
          WordDiffView(diffs: result.diffs),
          if (!result.passed) ...[
            const SizedBox(height: 10),
            Text('先看看差在哪，再复听一次；需要原文时点「显示答案」。',
                style: AppText.caption.copyWith(height: 1.6)),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SecondaryButton(
                label: '复听',
                expanded: false,
                height: 36,
                onPressed: onReplay,
              ),
              SecondaryButton(
                label: showAnswer ? '收起答案' : '显示答案',
                expanded: false,
                height: 36,
                onPressed: onShowAnswer,
              ),
              if (onStorePhrase != null)
                SecondaryButton(
                  label: '存入表达本',
                  expanded: false,
                  height: 36,
                  onPressed: onStorePhrase,
                ),
              PrimaryButton(
                label: nextLabel,
                expanded: false,
                height: 36,
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
