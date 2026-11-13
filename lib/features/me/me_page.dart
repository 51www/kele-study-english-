import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_metrics.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../domain/models/models.dart';
import '../../services/llm/cost_estimator.dart';
import 'trend_section.dart';

class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeDataProvider).asData?.value;
    final profile = ref.watch(profileInfoProvider).asData?.value;
    final settings = ref.watch(settingsControllerProvider);
    final budget = int.tryParse(settings[SettingsKeys.monthlyBudget] ?? '50') ?? 50;
    final monthly = ref.watch(monthlyCostProvider).asData?.value ?? 0;
    final latency = ref.watch(lastLatencyProvider).asData?.value;
    return SingleChildScrollView(
      padding: shellPagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('我的', style: AppText.h1),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF839AFF), Color(0xFF5A74F0)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.primary,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                      ),
                      child: const Icon(Icons.emoji_emotions_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kele', style: AppText.h2.copyWith(color: Colors.white)),
                          const SizedBox(height: 3),
                          Text(
                            '每天开口，慢慢变好',
                            style: AppText.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '连续 ${home?.streakDays ?? 0} 天',
                            style: AppText.tag.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _Stat(label: '练习次数', value: '${home?.totalSessions ?? 0}')),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat(label: '今日开口', value: '${home?.todayTurns ?? 0} 轮')),
                  const SizedBox(width: 10),
                  Expanded(child: _Stat(label: '今日分钟', value: '${home?.todayMinutes ?? 0}')),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 16, color: AppColors.primaryDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '本月成本（估算）',
                            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${CostEstimator.format(monthly)} / 预算 ¥$budget',
                          style: AppText.bodySecondary.copyWith(color: AppColors.primaryDeep),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: budget <= 0 ? 0 : (monthly / budget).clamp(0.0, 1.0).toDouble(),
                        minHeight: 4,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          budget > 0 && monthly >= budget ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      budget > 0 && monthly >= budget
                          ? '已达到本月提醒额度，可以在设置里调整预算或缩短对话。'
                          : '按接口 usage 估算；缺失时按字符数估算，仅为本地参考。',
                      style: AppText.caption.copyWith(
                        color: budget > 0 && monthly >= budget ? AppColors.warning : null,
                      ),
                    ),
                    if (latency != null && (latency['firstAudio'] ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '上一回合：识别 ${((latency['asr'] ?? 0) / 1000).toStringAsFixed(1)}s · '
                        '首字 ${((latency['firstToken'] ?? 0) / 1000).toStringAsFixed(1)}s · '
                        '首音 ${((latency['firstAudio'] ?? 0) / 1000).toStringAsFixed(1)}s',
                        style: AppText.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const TrendSection(),
              const SizedBox(height: 12),
              SectionTitle(title: '设置'),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Column(
                  children: [
                    SettingRow(
                      icon: Icons.tune_rounded,
                      title: '模型配置',
                      subtitle: profile == null
                          ? '接口地址、密钥、模型名'
                          : '${profile.profile.model} · 密钥 ${profile.maskedKey}',
                      onTap: () => context.push('/settings/model'),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    SettingRow(
                      icon: Icons.settings_rounded,
                      title: '练习与语音设置',
                      onTap: () => context.push('/settings'),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    SettingRow(
                      icon: Icons.map_outlined,
                      title: '学习路径',
                      subtitle: '阶段计划、进度与下一步建议',
                      onTap: () => context.push('/path'),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    SettingRow(
                      icon: Icons.storage_rounded,
                      title: '数据与存储',
                      onTap: () => context.push('/settings/data'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Column(
                  children: [
                    SettingRow(
                      icon: Icons.info_outline_rounded,
                      title: '关于 Saylo',
                      value: 'v0.1.0',
                      onTap: () => showAppSheet(
                        context: context,
                        title: '关于 Saylo',
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('一个只给自己用的英语口语练习 App。', style: AppText.body),
                              const SizedBox(height: 8),
                              Text(
                                '对话由你配置的 OpenAI 兼容接口驱动；语音朗读优先使用 Edge TTS，识别优先使用系统能力。',
                                style: AppText.bodySecondary,
                              ),
                              const SizedBox(height: 14),
                              Text('版本 0.1.0（M0）', style: AppText.caption),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: AppText.h2.copyWith(color: AppColors.primaryDeep)),
          const SizedBox(height: 3),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}
