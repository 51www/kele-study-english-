import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';
import '../../services/tts/tts_engine.dart';

/// 自定义场景：新建 / 编辑 / 删除，数据在对话页与内置场景表现完全一致。
///
/// 表单字段与 `Scenario` 一一对应；`isBuiltin = false` 的场景才可编辑或删除，
/// 删除只影响场景本身，历史会话里保存的 scenario_id 快照不受影响。
class ScenarioEditorPage extends ConsumerStatefulWidget {
  const ScenarioEditorPage({super.key, this.scenarioId});

  /// 为空表示新建；非空表示编辑指定自定义场景。
  final String? scenarioId;

  @override
  ConsumerState<ScenarioEditorPage> createState() => _ScenarioEditorPageState();
}

class _ScenarioEditorPageState extends ConsumerState<ScenarioEditorPage> {
  static const _categories = <String>['日常', '工作', '旅行', '社交', '健康', '观点'];
  static const _levels = <String>['A2', 'B1', 'B2'];
  static const _turns = <int>[8, 10, 12];

  final _titleZh = TextEditingController();
  final _titleEn = TextEditingController();
  final _aiRole = TextEditingController();
  final _userGoal = TextEditingController();
  final _openingLine = TextEditingController();
  final _successCriteria = TextEditingController();
  final _customCategory = TextEditingController();
  final List<TextEditingController> _phrases = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  String _category = '日常';
  bool _useCustomCategory = false;
  String _level = 'B1';
  int _expectedTurns = 8;
  bool _saving = false;
  bool _loading = false;
  bool _previewPlaying = false;
  int _sortOrder = 0;
  String? _branchHint;
  String? _loadError;

  bool get _editing => widget.scenarioId != null;

  @override
  void initState() {
    super.initState();
    _openingLine.addListener(_refreshPreview);
    if (_editing) _load();
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final scenario = await ref.read(scenarioRepositoryProvider).byId(widget.scenarioId!);
    if (!mounted) return;
    if (scenario == null || scenario.isBuiltin) {
      setState(() {
        _loading = false;
        _loadError = scenario == null ? '没有找到这个场景' : '内置场景不可编辑';
      });
      return;
    }
    _titleZh.text = scenario.titleZh;
    _titleEn.text = scenario.titleEn;
    _aiRole.text = scenario.aiRole;
    _userGoal.text = scenario.userGoal;
    _openingLine.text = scenario.openingLine;
    _successCriteria.text = scenario.successCriteria;
    _category = _categories.contains(scenario.category) ? scenario.category : '日常';
    _useCustomCategory = !_categories.contains(scenario.category);
    if (_useCustomCategory) _customCategory.text = scenario.category;
    _level = _levels.contains(scenario.level) ? scenario.level : 'B1';
    _expectedTurns = _turns.contains(scenario.expectedTurns) ? scenario.expectedTurns : 8;
    _sortOrder = scenario.sortOrder;
    _branchHint = scenario.branchHint;
    for (final controller in _phrases) {
      controller.dispose();
    }
    _phrases.clear();
    for (final phrase in scenario.targetPhrases.take(5)) {
      _phrases.add(TextEditingController(text: phrase));
    }
    while (_phrases.length < 3) {
      _phrases.add(TextEditingController());
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _openingLine.removeListener(_refreshPreview);
    for (final controller in [
      _titleZh,
      _titleEn,
      _aiRole,
      _userGoal,
      _openingLine,
      _successCriteria,
      _customCategory,
      ..._phrases,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _invalidateScenarios() {
    ref.invalidate(scenarioLibraryProvider);
    ref.invalidate(homeDataProvider);
    if (_editing) ref.invalidate(scenarioProvider(widget.scenarioId!));
  }

  Future<void> _save() async {
    if (_saving) return;
    final zh = _titleZh.text.trim();
    final en = _titleEn.text.trim();
    final role = _aiRole.text.trim();
    final goal = _userGoal.text.trim();
    final opening = _openingLine.text.trim();
    final success = _successCriteria.text.trim();
    final category = _useCustomCategory ? _customCategory.text.trim() : _category;
    final phrases = _phrases
        .map((e) => e.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (zh.isEmpty || en.isEmpty || role.isEmpty || goal.isEmpty ||
        opening.isEmpty || category.isEmpty || phrases.isEmpty) {
      showAppToast(context, '场景名、英文标题、分类、角色、目标、开场白和至少 1 条目标表达都要填', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(scenarioRepositoryProvider);
      final now = DateTime.now();
      final scenario = Scenario(
        id: widget.scenarioId ?? 'custom_${now.microsecondsSinceEpoch}',
        titleZh: zh,
        titleEn: en,
        category: category,
        level: _level,
        aiRole: role,
        userGoal: goal,
        openingLine: opening,
        targetPhrases: phrases,
        expectedTurns: _expectedTurns,
        successCriteria: success.isEmpty ? '用英语完成「$zh」的完整对话。' : success,
        branchHint: _branchHint,
        isBuiltin: false,
        sortOrder: _editing ? _sortOrder : await repo.nextSortOrder(),
      );
      await repo.saveCustom(scenario);
      _invalidateScenarios();
      if (mounted) {
        showAppToast(context, _editing ? '场景已更新' : '场景已创建');
        context.pop();
      }
    } catch (e) {
      if (mounted) showAppToast(context, '保存失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showConfirmDialog(
      context,
      title: '删除这个场景？',
      message: '场景会从场景库移除，已经练过的记录不受影响。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok) return;
    await ref.read(scenarioRepositoryProvider).deleteCustom(widget.scenarioId!);
    _invalidateScenarios();
    if (mounted) {
      showAppToast(context, '场景已删除');
      context.pop();
    }
  }

  Future<void> _previewSpeak() async {
    final text = _openingLine.text.trim();
    if (text.isEmpty) {
      showAppToast(context, '先写一句 AI 开场白', error: true);
      return;
    }
    setState(() => _previewPlaying = true);
    try {
      final settings = ref.read(settingsRepositoryProvider);
      await ref.read(ttsRouterProvider).speak(
            text,
            voice: settings.getString(SettingsKeys.ttsVoice, 'en-US-AriaNeural'),
            rate: settings.getDouble(SettingsKeys.ttsRate, fallback: 1.0),
            preferEdge: settings.getString(SettingsKeys.ttsEngine, 'edge') != 'system',
          );
    } on TtsException {
      if (mounted) showAppToast(context, '朗读暂不可用', error: true);
    } finally {
      if (mounted) setState(() => _previewPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return PageScaffold(
        title: '编辑场景',
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: _loadError!,
          message: '可以在场景库里新建一个自己的场景。',
          actionLabel: '返回场景库',
          action: () => context.pop(),
        ),
      );
    }
    return PageScaffold(
      title: _editing ? '编辑场景' : '新建场景',
      bottomBar: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Row(
                children: [
                  if (_editing) ...[
                    Expanded(
                      child: SecondaryButton(
                        label: '删除',
                        icon: Icons.delete_outline_rounded,
                        onPressed: _saving ? null : _delete,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: _editing ? '保存修改' : '创建场景',
                      icon: Icons.check_rounded,
                      loading: _saving || _loading,
                      onPressed: _saving || _loading ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '按自己的练习情境搭一个场景，保存后就能直接开始对话。',
                        style: AppText.caption,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('场景名'),
                      AppTextField(controller: _titleZh, hint: '例如：和房东谈续租'),
                      const SizedBox(height: 12),
                      _FieldLabel('英文标题'),
                      AppTextField(controller: _titleEn, hint: 'Renewing a Lease'),
                      const SizedBox(height: 12),
                      _FieldLabel('分类'),
                      const SizedBox(height: 6),
                      // 横向单行可滚动：Wrap 的有界约束会让带 alignment 的
                      // Container 撑满整行，Chip 就变成通栏竖排了。
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final category in _categories) ...[
                              _ChoiceChip(
                                label: category,
                                selected: !_useCustomCategory && _category == category,
                                onTap: () => setState(() {
                                  _useCustomCategory = false;
                                  _category = category;
                                }),
                              ),
                              const SizedBox(width: 6),
                            ],
                            _ChoiceChip(
                              label: '自定义',
                              selected: _useCustomCategory,
                              onTap: () => setState(() => _useCustomCategory = true),
                            ),
                          ],
                        ),
                      ),
                      if (_useCustomCategory) ...[
                        const SizedBox(height: 8),
                        AppTextField(controller: _customCategory, hint: '输入分类名'),
                      ],
                      const SizedBox(height: 12),
                      _FieldLabel('难度'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final level in _levels) ...[
                            _ChoiceChip(
                              label: level,
                              selected: _level == level,
                              onTap: () => setState(() => _level = level),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel('AI 扮演的角色'),
                      AppTextField(
                        controller: _aiRole,
                        hint: 'You are a friendly landlord...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel('这次要练什么'),
                      AppTextField(
                        controller: _userGoal,
                        hint: '确认租金、提出一个小要求、约好看房时间。',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel('目标表达'),
                      const SizedBox(height: 6),
                      ..._phrases.asMap().entries.map((entry) {
                        final index = entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: entry.value,
                                  hint: '第 ${index + 1} 句，例如：Is the rent negotiable?',
                                ),
                              ),
                              if (_phrases.length > 1)
                                IconButton(
                                  onPressed: () {
                                    entry.value.dispose();
                                    setState(() => _phrases.removeAt(index));
                                  },
                                  icon: const Icon(Icons.close_rounded, size: 17),
                                  color: AppColors.inkMuted,
                                ),
                            ],
                          ),
                        );
                      }),
                      if (_phrases.length < 5)
                        TextButton.icon(
                          onPressed: () => setState(() => _phrases.add(TextEditingController())),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text('加一条目标表达', style: AppText.caption),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primaryDeep),
                        ),
                      const SizedBox(height: 8),
                      _FieldLabel('AI 开场白（保存前可预览 / 试听）'),
                      AppTextField(
                        controller: _openingLine,
                        hint: 'Hi! Thanks for reaching out about the lease.',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      _OpeningPreview(
                        text: _openingLine.text.trim(),
                        playing: _previewPlaying,
                        onPlay: _previewSpeak,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel('完成标准（选填）'),
                      AppTextField(
                        controller: _successCriteria,
                        hint: '说清租金、提出要求并确认下一步。',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _FieldLabel('预计对话轮数'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final turns in _turns) ...[
                            _ChoiceChip(
                              label: '$turns 轮',
                              selected: _expectedTurns == turns,
                              onTap: () => setState(() => _expectedTurns = turns),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          color: AppColors.inkSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            fontSize: 11,
            color: selected ? AppColors.primaryDeep : AppColors.inkSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _OpeningPreview extends StatelessWidget {
  const _OpeningPreview({
    required this.text,
    required this.playing,
    required this.onPlay,
  });

  final String text;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primaryWash,
      shadow: false,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primaryDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('开场白预览', style: AppText.tag.copyWith(color: AppColors.primaryDeep)),
                const SizedBox(height: 5),
                Text(
                  text.isEmpty ? '写下开场白后，这里会实时显示 AI 的第一句话。' : text,
                  style: AppText.body.copyWith(
                    height: 1.5,
                    color: text.isEmpty ? AppColors.inkMuted : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: playing
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        color: AppColors.primaryDeep,
                      ),
                    )
                  : const Icon(Icons.volume_up_rounded, size: 16, color: AppColors.primaryDeep),
            ),
          ),
        ],
      ),
    );
  }
}
