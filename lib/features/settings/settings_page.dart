import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final engine = settings[SettingsKeys.ttsEngine] ?? 'edge';
    final voice = settings[SettingsKeys.ttsVoice] ?? 'en-US-AriaNeural';
    final rate = double.tryParse(settings[SettingsKeys.ttsRate] ?? '1.0') ?? 1.0;
    final level = settings[SettingsKeys.level] ?? 'B1';
    final correction = settings[SettingsKeys.correctionMode] ?? 'gentle';
    final translateRaw = settings[SettingsKeys.translateDefault] ?? 'off';
    final translateLabel = switch (translateRaw) {
      'tap' => '点按翻译',
      'always' || 'on' => '常开字幕',
      _ => '关闭',
    };
    final autoPlay = settings[SettingsKeys.ttsAutoPlay] != 'false';
    final targetMinutes = int.tryParse(settings[SettingsKeys.targetMinutes] ?? '10') ?? 10;
    final budget = int.tryParse(settings[SettingsKeys.monthlyBudget] ?? '50') ?? 50;
    final asrModel = settings[SettingsKeys.asrModel] ?? 'FunAudioLLM/SenseVoiceSmall';
    final passThreshold =
        int.tryParse(settings[SettingsKeys.dictationPassThreshold] ?? '90') ?? 90;
    final contractionEquivalent =
        (settings[SettingsKeys.dictationContractionEquivalent] ?? 'true') == 'true';
    final numberEquivalent =
        (settings[SettingsKeys.dictationNumberEquivalent] ?? 'true') == 'true';
    final dictationSpeed =
        double.tryParse(settings[SettingsKeys.dictationSpeed] ?? '1.0') ?? 1.0;
    final learnerProfileEnabled =
        settings[SettingsKeys.learnerProfileEnabled] != 'false';
    final speakThreshold =
        int.tryParse(settings[SettingsKeys.reviewSpeakPassThreshold] ?? '80') ?? 80;
    final dailyLimit =
        int.tryParse(settings[SettingsKeys.reviewDailyLimit] ?? '5') ?? 5;

    Future<void> set(String key, String value) =>
        ref.read(settingsControllerProvider.notifier).set(key, value);

    return PageScaffold(
      title: '设置',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          const SectionTitle(title: '语音'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.record_voice_over_rounded,
                  title: '朗读引擎',
                  value: engine == 'edge' ? 'Edge TTS' : '系统 TTS',
                  onTap: () => _pick(
                    context,
                    title: '朗读引擎',
                    options: const ['Edge TTS', '系统 TTS'],
                    current: engine == 'edge' ? 'Edge TTS' : '系统 TTS',
                    onPick: (value) => set(SettingsKeys.ttsEngine, value == 'Edge TTS' ? 'edge' : 'system'),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.graphic_eq_rounded,
                  title: '音色',
                  value: _voiceLabel(voice),
                  onTap: () => _pick(
                    context,
                    title: '选择音色',
                    options: _voices.values.toList(),
                    current: _voiceLabel(voice),
                    onPick: (value) {
                      final entry = _voices.entries.where((e) => e.value == value).firstOrNull;
                      if (entry != null) set(SettingsKeys.ttsVoice, entry.key);
                    },
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.speed_rounded,
                  title: '语速',
                  value: rate == 0.75 ? '0.75x' : '${rate.toStringAsFixed(1)}x',
                  onTap: () => _pick(
                    context,
                    title: '朗读语速',
                    options: const ['0.75x', '0.8x', '1.0x', '1.2x'],
                    current: rate == 0.75 ? '0.75x' : '${rate.toStringAsFixed(1)}x',
                    onPick: (value) => set(SettingsKeys.ttsRate, value.replaceAll('x', '')),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.play_circle_outline_rounded,
                  title: '自动朗读回复',
                  trailing: Switch(
                    value: autoPlay,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) => set(SettingsKeys.ttsAutoPlay, value ? 'true' : 'false'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '练习'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.mic_external_on_rounded,
                  title: '语音识别配置',
                  value: asrModel.split('/').last,
                  subtitle: '与对话模型独立保存；未配置时用系统识别',
                  onTap: () => context.push('/settings/asr'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.signal_cellular_alt_rounded,
                  title: '难度等级',
                  value: level,
                  onTap: () => _pick(
                    context,
                    title: '难度等级',
                    options: const ['A2', 'B1', 'B2', 'C1'],
                    current: level,
                    onPick: (value) => set(SettingsKeys.level, value),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.spellcheck_rounded,
                  title: '纠错方式',
                  value: correction == 'gentle' ? '温和纠错' : '严格纠错',
                  subtitle: '严格纠错为 P1 能力，暂未开放',
                  onTap: () async {
                    final picked = await _pick(
                      context,
                      title: '纠错方式',
                      options: const ['温和纠错', '严格纠错'],
                      current: correction == 'gentle' ? '温和纠错' : '严格纠错',
                      disabled: const {'严格纠错'},
                      onPick: (value) => set(SettingsKeys.correctionMode, value == '温和纠错' ? 'gentle' : 'strict'),
                    );
                    if (picked != null && picked == '严格纠错' && context.mounted) {
                      showAppToast(context, '严格纠错属于 P1 能力，当前版本暂不开放');
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.translate_rounded,
                  title: '翻译默认方式',
                  subtitle: '关闭 / 点按 / 常开双语字幕，进入对话前选好默认方式',
                  value: translateLabel,
                  onTap: () => _pick(
                    context,
                    title: '翻译默认方式',
                    options: const ['关闭', '点按翻译', '常开字幕'],
                    current: translateLabel,
                    onPick: (value) => set(
                      SettingsKeys.translateDefault,
                      switch (value) {
                        '点按翻译' => 'tap',
                        '常开字幕' => 'always',
                        _ => 'off',
                      },
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.timer_outlined,
                  title: '每日目标',
                  value: '$targetMinutes 分钟',
                  onTap: () => _pick(
                    context,
                    title: '每日目标',
                    options: const ['5 分钟', '10 分钟', '15 分钟', '20 分钟'],
                    current: '$targetMinutes 分钟',
                    onPick: (value) => set(SettingsKeys.targetMinutes, value.replaceAll(' 分钟', '')),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.map_outlined,
                  title: '学习路径',
                  subtitle: '阶段计划、进度与下一步建议；可随时改目标、换阶段',
                  value: '查看',
                  onTap: () => context.push('/path'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.mic_none_rounded,
                  title: '开口复述通过阈值',
                  subtitle: '90 秒开口练习按词级匹配判定，与听写阈值独立',
                  value: '$speakThreshold%',
                  onTap: () => _pick(
                    context,
                    title: '开口复述通过阈值',
                    options: const ['70%', '75%', '80%', '85%', '90%'],
                    current: '$speakThreshold%',
                    onPick: (value) => set(
                      SettingsKeys.reviewSpeakPassThreshold,
                      value.replaceAll('%', ''),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.format_list_bulleted_rounded,
                  title: '每日待复练上限',
                  subtitle: '每天最多提醒 N 条到期复练，超出顺延到第二天',
                  value: '$dailyLimit 条',
                  onTap: () => _pick(
                    context,
                    title: '每日待复练上限',
                    options: const ['3 条', '5 条', '8 条', '10 条'],
                    current: '$dailyLimit 条',
                    onPick: (value) => set(
                      SettingsKeys.reviewDailyLimit,
                      value.replaceAll(' 条', ''),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.payments_outlined,
                  title: '月度成本提醒',
                  value: '¥ $budget',
                  subtitle: '超过预算时在「我的」提示',
                  onTap: () => _pick(
                    context,
                    title: '月度成本提醒',
                    options: const ['¥ 0', '¥ 20', '¥ 50', '¥ 100'],
                    current: '¥ $budget',
                    onPick: (value) => set(SettingsKeys.monthlyBudget, value.replaceAll('¥ ', '')),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.psychology_alt_outlined,
                  title: '学习者档案',
                  subtitle: '主对话参考最近的常犯错误、已掌握表达与上次话题，避免重复提问；关闭后回到原始对话',
                  trailing: Switch(
                    value: learnerProfileEnabled,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) => set(
                      SettingsKeys.learnerProfileEnabled,
                      value ? 'true' : 'false',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '听写练习'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.rule_rounded,
                  title: '通过阈值',
                  value: '$passThreshold%',
                  subtitle: '按逐词正确率判定，判分完全离线',
                  onTap: () => _pick(
                    context,
                    title: '通过阈值',
                    options: const ['80%', '85%', '90%', '95%'],
                    current: '$passThreshold%',
                    onPick: (value) => set(
                      SettingsKeys.dictationPassThreshold,
                      value.replaceAll('%', ''),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.short_text_rounded,
                  title: '缩写等价',
                  subtitle: "I'd like 与 I would like 按同一句处理",
                  trailing: Switch(
                    value: contractionEquivalent,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) => set(
                      SettingsKeys.dictationContractionEquivalent,
                      value ? 'true' : 'false',
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.numbers_rounded,
                  title: '数字等价',
                  subtitle: '10 与 ten、\$5 与 five dollars 不判错',
                  trailing: Switch(
                    value: numberEquivalent,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) => set(
                      SettingsKeys.dictationNumberEquivalent,
                      value ? 'true' : 'false',
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.speed_rounded,
                  title: '默认播放速度',
                  value: dictationSpeed == 0.75 ? '0.75x' : '1.0x',
                  onTap: () => _pick(
                    context,
                    title: '默认播放速度',
                    options: const ['0.75x', '1.0x'],
                    current: dictationSpeed == 0.75 ? '0.75x' : '1.0x',
                    onPick: (value) => set(
                      SettingsKeys.dictationSpeed,
                      value.replaceAll('x', ''),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '判分规则：忽略大小写、标点和多余空格；长词拼错按半词计，多写的词计入分母；不使用模型接口。听写页也会显示当前规则。',
            style: AppText.caption.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '数据与存储'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: SettingRow(
              icon: Icons.storage_rounded,
              title: '数据与存储',
              subtitle: '语音缓存、清空练习数据',
              onTap: () => context.push('/settings/data'),
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '关于'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                const SettingRow(
                  icon: Icons.info_outline_rounded,
                  title: '版本',
                  value: '0.1.0',
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.description_outlined,
                  title: '开源许可',
                  onTap: () => showLicensePage(context: context, applicationName: 'Saylo', applicationVersion: '0.1.0'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _voices = <String, String>{
    'en-US-AriaNeural': 'Aria（女声·美音）',
    'en-US-GuyNeural': 'Guy（男声·美音）',
    'en-GB-SoniaNeural': 'Sonia（女声·英音）',
    'en-GB-RyanNeural': 'Ryan（男声·英音）',
  };

  String _voiceLabel(String voice) => _voices[voice] ?? voice;

  Future<String?> _pick(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onPick,
    Set<String> disabled = const {},
  }) {
    return showAppSheet<String>(
      context: context,
      title: title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            final selected = option == current;
            final isDisabled = disabled.contains(option);
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                option,
                style: AppText.body.copyWith(
                  color: isDisabled ? AppColors.inkMuted : AppColors.ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                  : isDisabled
                      ? Text('P1', style: AppText.tag.copyWith(color: AppColors.inkMuted))
                      : null,
              onTap: () {
                if (isDisabled) return;
                Navigator.of(context).pop(option);
                onPick(option);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
