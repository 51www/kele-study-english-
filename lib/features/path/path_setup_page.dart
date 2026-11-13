import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';
import 'path_model.dart';
import 'path_plan.dart';
import 'path_providers.dart';

const List<String> _levels = <String>['A2', 'B1', 'B2', 'C1'];
const List<int> _minuteOptions = <int>[5, 10, 15, 20];
const List<int> _weekOptions = <int>[2, 3, 4, 5];

/// 起点 3 问（不考试）：目标场合 + 具体诉求、当前水平、投入节奏。
/// 已有路径时进来是「改目标 / 改起点」，只重排计划、不丢历史。
class PathSetupPage extends ConsumerStatefulWidget {
  const PathSetupPage({super.key});

  @override
  ConsumerState<PathSetupPage> createState() => _PathSetupPageState();
}

class _PathSetupPageState extends ConsumerState<PathSetupPage> {
  late final TextEditingController _detail;
  int _goalIndex = 0;
  int _levelIndex = 1;
  int _minutesIndex = 1;
  int _weekIndex = 1;
  int _stageIndex = 1;
  int _confidence = 3;
  int _createdAt = 0;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _detail = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final state = await ref.read(learningPathProvider.future);
    final home = await ref.read(homeDataProvider.future);
    if (!mounted) return;
    setState(() {
      _goalIndex = pathGoalKeys.indexOf(state.goal).clamp(0, pathGoalKeys.length - 1);
      _detail.text = state.specificGoal;
      _levelIndex = _levels.indexOf(state.level).clamp(0, _levels.length - 1);
      _minutesIndex =
          _minuteOptions.indexOf(state.targetMinutes).clamp(0, _minuteOptions.length - 1);
      _weekIndex = _weekOptions
          .indexOf(state.sessionsPerWeek)
          .clamp(0, _weekOptions.length - 1);
      _stageIndex = (state.configured
              ? state.stage
              : suggestStageIndex(state.level, home.totalSessions))
          .clamp(1, kPathStages.length);
      _confidence = state.confidence;
      _createdAt = state.createdAt;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final level = _levels[_levelIndex];
    final minutes = _minuteOptions[_minutesIndex];
    final state = LearningPathState(
      configured: true,
      goal: pathGoalKeys[_goalIndex],
      specificGoal: _detail.text.trim(),
      level: level,
      targetMinutes: minutes,
      sessionsPerWeek: _weekOptions[_weekIndex],
      stage: _stageIndex,
      items: const <PathItem>[],
      alternativeIndex: 0,
      confidence: _confidence,
      createdAt: _createdAt == 0 ? now : _createdAt,
      updatedAt: now,
    );
    await writePath(ref, state);
    // 统一「设置里的水平」与路径起点，避免两套口径各管一摊。
    await ref.read(settingsControllerProvider.notifier).set(SettingsKeys.level, level);
    await ref.read(settingsControllerProvider.notifier).set(
          SettingsKeys.targetMinutes,
          '$minutes',
        );
    if (!mounted) return;
    showAppToast(context, '路径已生成，今天从「下一步」开始');
    // 直接落到路径页：深链进入时也没有可 pop 的栈，避免停在表单上。
    context.go('/path');
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(learningPathProvider).asData?.value.configured ?? false;
    return PageScaffold(
      title: configured ? '调整学习路径' : '设定学习路径',
      bottomBar: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: configured ? '保存并重排路径' : '生成我的路径',
            icon: Icons.arrow_forward_rounded,
            loading: _saving,
            onPressed: _loaded ? _save : null,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          AppCard(
            color: AppColors.primaryWash,
            shadow: false,
            child: Text(
              '只用 3 个问题定个方向，不考试、不打分。之后每次练完都会按你的记录重排，'
              '随时可以跳过、换阶段或改目标。',
              style: AppText.bodySecondary.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: '1 · 最想用在哪'),
          const SizedBox(height: 8),
          SegmentedControl(
            items: pathGoalKeys.map((e) => pathGoalLabels[e]!).toList(),
            index: _goalIndex,
            onChanged: (value) => setState(() => _goalIndex = value),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _detail,
            label: '具体诉求（可选）',
            hint: '例如：开会能追问和确认',
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '2 · 现在的水平'),
          const SizedBox(height: 8),
          SegmentedControl(
            items: _levels,
            index: _levelIndex,
            onChanged: (value) => setState(() {
              _levelIndex = value;
              _stageIndex = suggestStageIndex(_levels[value], 0).clamp(1, kPathStages.length);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '已练过的内容会让起点自动往后一点；这里选的等级也会同步到设置里，影响 AI 用词。',
            style: AppText.caption.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '3 · 投入节奏'),
          const SizedBox(height: 8),
          Text('每次时长', style: AppText.caption),
          const SizedBox(height: 6),
          SegmentedControl(
            items: _minuteOptions.map((e) => '$e 分钟').toList(),
            index: _minutesIndex,
            onChanged: (value) => setState(() => _minutesIndex = value),
          ),
          const SizedBox(height: 12),
          Text('每周次数', style: AppText.caption),
          const SizedBox(height: 6),
          SegmentedControl(
            items: _weekOptions.map((e) => '$e 次').toList(),
            index: _weekIndex,
            onChanged: (value) => setState(() => _weekIndex = value),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '从哪个阶段开始'),
          const SizedBox(height: 8),
          SegmentedControl(
            items: kPathStages.map((e) => '${e.index} ${e.name}').toList(),
            index: (_stageIndex - 1).clamp(0, kPathStages.length - 1),
            onChanged: (value) => setState(() => _stageIndex = value + 1),
          ),
          const SizedBox(height: 8),
          Text(
            '阶段不是关卡，4 段随时可换、可跳、可退；这里只是选个起点。',
            style: AppText.caption.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
