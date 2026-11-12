import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';

/// 3 分钟轻量练习：1 条待复练 + 3 句接话 + 1 条重点，全程离线。
///
/// 会话写回 `session` 表并用 `model_name = quick-3min` 标记（零改表）；
/// 计入今日分钟，但不计入需求 §3.2 的「每周 ≥3 次、每次 ≥8 分钟」有效次数。
class QuickPracticePage extends ConsumerStatefulWidget {
  const QuickPracticePage({super.key});

  @override
  ConsumerState<QuickPracticePage> createState() => _QuickPracticePageState();
}

class _QuickPracticePageState extends ConsumerState<QuickPracticePage> {
  final TextEditingController _input = TextEditingController();
  int _step = 0;
  int _phraseIndex = 0;
  bool? _lastOk;
  bool _loading = true;
  bool _finished = false;
  String _takeaway = '';
  String? _scenarioId;
  List<String> _phrases = <String>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final due = await ref.read(dueReviewItemsProvider.future);
    final home = await ref.read(homeDataProvider.future);
    final scenario = home.scenarios.firstOrNull;
    final phrases = (scenario?.targetPhrases ?? const <String>[])
        .where((e) => e.trim().isNotEmpty)
        .take(3)
        .toList();
    if (!mounted) return;
    setState(() {
      _scenarioId = scenario?.id;
      _phrases = phrases;
      _takeaway = due.firstOrNull?.textEn.trim().isNotEmpty == true
          ? due.first.textEn.trim()
          : (phrases.firstOrNull ?? 'Take your time and speak clearly.');
      _loading = false;
    });
  }

  List<String> _keywords(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2)
      .toList();

  bool _saidIt(String target, String answer) {
    final words = _keywords(target);
    final spoken = answer.toLowerCase();
    if (words.isEmpty) return answer.trim().isNotEmpty;
    final hits = words.where((word) => spoken.contains(word)).length;
    return hits >= (words.length / 2).ceil();
  }

  String get _currentSentence {
    if (_step == 0) return _takeaway;
    if (_step == 1 && _phraseIndex < _phrases.length) {
      return _phrases[_phraseIndex];
    }
    return _takeaway;
  }

  void _advance() {
    if (_step == 0) {
      setState(() {
        _step = _phrases.isEmpty ? 2 : 1;
        _input.clear();
        _lastOk = null;
      });
    } else if (_step == 1) {
      if (_phraseIndex + 1 < _phrases.length) {
        setState(() {
          _phraseIndex++;
          _input.clear();
          _lastOk = null;
        });
      } else {
        setState(() {
          _step = 2;
          _input.clear();
          _lastOk = null;
        });
      }
    }
  }

  Future<void> _finish() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.read(sessionRepositoryProvider).saveSession(
          SessionRecord(
            id: 'quick_$now',
            scenarioId: _scenarioId,
            startedAt: now - 180000,
            endedAt: now,
            durationSec: 180,
            turnCount: 3,
            status: 'completed',
            modelName: quickSessionTag,
            reviewJson: null,
          ),
        );
    ref.invalidate(homeDataProvider);
    ref.invalidate(recentSessionsProvider);
    ref.invalidate(trendsProvider);
    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: '3 分钟轻量练习',
      showBack: true,
      onBack: () => context.go('/home'),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Text(
                  '低能量日也能练一轮：开口说、接住话、带走一句。',
                  style: AppText.bodySecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  '计入今日分钟，不计入每周 3 次有效练习（每次需 ≥8 分钟）。',
                  style: AppText.caption,
                ),
                const SizedBox(height: 14),
                if (_finished)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 28, color: AppColors.success),
                        const SizedBox(height: 10),
                        const Text('这一轮练完了', style: AppText.cardTitle),
                        const SizedBox(height: 6),
                        Text('带走这一句：$_takeaway', style: AppText.bodySecondary),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: '回首页',
                          onPressed: () => context.go('/home'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _StepBar(step: _step, total: 3),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _step == 0
                              ? '第 1 步 · 把上次改过的说法再说一遍'
                              : _step == 1
                                  ? '第 2 步 · 接话练习 ${_phraseIndex + 1}/${_phrases.length}'
                                  : '第 3 步 · 带走今天这一句',
                          style: AppText.caption,
                        ),
                        const SizedBox(height: 8),
                        Text(_currentSentence, style: AppText.body),
                        if (_step < 2) ...[
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _input,
                            hint: '说出或写出这句英文',
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: _lastOk == true ? '说到了 · 下一句' : '检查这一遍',
                              onPressed: () {
                                if (_lastOk == true) {
                                  _advance();
                                } else {
                                  final ok = _saidIt(_currentSentence, _input.text);
                                  setState(() => _lastOk = ok);
                                }
                              },
                            ),
                          ),
                          if (_lastOk != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _lastOk! ? '听到了，继续。' : '还没说全，再看一眼原句。',
                              style: AppText.caption,
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 14),
                          Text(
                            '把这句记下来，下次遇到同样场景直接用。',
                            style: AppText.bodySecondary,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              label: '完成这一轮',
                              icon: Icons.check_rounded,
                              onPressed: _finish,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= step ? AppColors.primary : AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
