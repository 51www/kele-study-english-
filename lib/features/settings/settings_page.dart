import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';

final cacheBytesProvider = FutureProvider<double>((ref) async {
  final store = ref.watch(localStoreProvider);
  final rows = await store.ttsCache();
  return rows.fold<double>(0, (sum, e) => sum + e.bytes);
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final cacheAsync = ref.watch(cacheBytesProvider);
    final engine = settings[SettingsKeys.ttsEngine] ?? 'edge';
    final voice = settings[SettingsKeys.ttsVoice] ?? 'en-US-AriaNeural';
    final rate = double.tryParse(settings[SettingsKeys.ttsRate] ?? '1.0') ?? 1.0;
    final level = settings[SettingsKeys.level] ?? 'B1';
    final correction = settings[SettingsKeys.correctionMode] ?? 'gentle';
    final translate = settings[SettingsKeys.translateDefault] == 'on';
    final autoPlay = settings[SettingsKeys.ttsAutoPlay] != 'false';
    final targetMinutes = int.tryParse(settings[SettingsKeys.targetMinutes] ?? '10') ?? 10;
    final budget = int.tryParse(settings[SettingsKeys.monthlyBudget] ?? '50') ?? 50;
    final asrModel = settings[SettingsKeys.asrModel] ?? 'FunAudioLLM/SenseVoiceSmall';

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
                  value: '${rate.toStringAsFixed(1)}x',
                  onTap: () => _pick(
                    context,
                    title: '朗读语速',
                    options: const ['0.8x', '1.0x', '1.2x'],
                    current: '${rate.toStringAsFixed(1)}x',
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
                  title: '默认显示翻译',
                  subtitle: '对话气泡默认附带中文',
                  trailing: Switch(
                    value: translate,
                    activeTrackColor: AppColors.primary,
                    onChanged: (value) => set(SettingsKeys.translateDefault, value ? 'on' : 'off'),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '数据'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.sd_storage_outlined,
                  title: '语音缓存',
                  value: cacheAsync.when(
                    data: (bytes) => _bytesLabel(bytes),
                    loading: () => '计算中',
                    error: (_, __) => '未知',
                  ),
                  subtitle: '清理后下次朗读会重新生成',
                  onTap: () async {
                    final paths = (await ref.read(localStoreProvider).ttsCache()).map((e) => e.hash).toList();
                    await ref.read(sessionRepositoryProvider).clearCache(paths);
                    ref.invalidate(cacheBytesProvider);
                    if (context.mounted) showAppToast(context, '语音缓存已清理');
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                SettingRow(
                  icon: Icons.delete_sweep_outlined,
                  title: '清空练习数据',
                  danger: true,
                  subtitle: '删除全部对话、复盘与表达本（保留密钥与设置）',
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: '清空练习数据？',
                      message: '所有对话记录、复盘和表达本都会被删除，且无法恢复。密钥与设置会保留。',
                      confirmLabel: '确认清空',
                      danger: true,
                    );
                    if (!ok) return;
                    final repo = ref.read(sessionRepositoryProvider);
                    final sessions = await repo.list();
                    for (final session in sessions) {
                      await repo.deleteSession(session.id);
                    }
                    final phrases = await repo.phrases();
                    for (final phrase in phrases) {
                      await repo.deletePhrase(phrase.id);
                    }
                    ref.invalidate(homeDataProvider);
                    ref.invalidate(recentSessionsProvider);
                    if (context.mounted) showAppToast(context, '练习数据已清空');
                  },
                ),
              ],
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
                  onTap: () => showLicensePage(context: context, applicationName: '开口练', applicationVersion: '0.1.0'),
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

  String _bytesLabel(double bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }

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
