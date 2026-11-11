import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_text.dart';
import '../../app/widgets/common.dart';
import '../../core/formatters.dart';
import '../../data/db/defaults.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/models/models.dart';
import '../dictation/providers.dart';

/// 数据与存储：`/settings/data`。
///
/// 与「练习与语音设置」分开，避免「我的」页两个入口跳到同一个地址。
/// 语音缓存与清空数据只在这里实现一次。
class DataSettingsPage extends ConsumerWidget {
  const DataSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheAsync = ref.watch(cacheBytesProvider);
    return PageScaffold(
      title: '数据与存储',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Text(
            '对话记录、复盘、表达本与听写教材只保存在本机应用私有目录；密钥存在系统安全存储。没有账号、没有云端同步。',
            style: AppText.caption.copyWith(height: 1.6),
          ),
          const SizedBox(height: 20),
          const SectionTitle(title: '缓存'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.sd_storage_outlined,
                  title: '语音缓存',
                  value: cacheAsync.when(
                    data: formatBytes,
                    loading: () => '计算中',
                    error: (_, _) => '未知',
                  ),
                  subtitle: '清理内存、磁盘文件与缓存索引；下次朗读会重新生成',
                  onTap: () async {
                    await ref.read(ttsDiskCacheProvider).clear();
                    ref.invalidate(cacheBytesProvider);
                    if (context.mounted) showAppToast(context, '语音缓存已清理');
                  },
                ),
                const Divider(height: 1),
                SettingRow(
                  icon: Icons.audio_file_outlined,
                  title: '听写素材',
                  value: '本机',
                  subtitle: '删除全部听写教材、句子、记录与音频副本；视频源文件仍在原处',
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: '清空听写素材？',
                      message: '所有教材、句子、听写记录与本机音频副本都会删除；视频源文件仍保留在你原来的位置。',
                      confirmLabel: '确认清理',
                      danger: true,
                    );
                    if (!ok) return;
                    final repo = ref.read(materialRepositoryProvider);
                    final service = ref.read(materialImportServiceProvider);
                    for (final item in await repo.materials()) {
                      await repo.deleteMaterial(item, service);
                    }
                    await service.clearAssets();
                    ref.invalidate(materialLibraryProvider);
                    ref.invalidate(wrongSegmentsProvider);
                    if (context.mounted) showAppToast(context, '听写素材已清理');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle(title: '清理'),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: SettingRow(
              icon: Icons.delete_sweep_outlined,
              title: '清空练习数据',
              danger: true,
              subtitle: '记录、表达本、听写教材、接口配置、密钥与缓存全部清掉，回到首次启动状态',
              onTap: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: '清空所有数据？',
                  message: '记录、复盘、表达本、听写教材、接口配置、密钥与朗读缓存都会清除，设置恢复默认，且无法恢复。',
                  confirmLabel: '确认清空',
                  danger: true,
                );
                if (!ok) return;
                await ref.read(localStoreProvider).clearAll();
                await ref.read(materialImportServiceProvider).clearAssets();
                await ref.read(scenarioRepositoryProvider).restoreSeeds();
                final keyStore = ref.read(keyStoreProvider);
                for (final refName in [
                  LlmProfileRepository.defaultKeyRef,
                  SettingsKeys.asrKeyRef,
                  SettingsKeys.asrExperimentalKeyRef,
                ]) {
                  await keyStore.delete(refName);
                }
                final settingsRepo = ref.read(settingsRepositoryProvider);
                await settingsRepo.load();
                for (final entry in defaultSettings.entries) {
                  await settingsRepo.set(entry.key, entry.value);
                }
                await ref.read(ttsDiskCacheProvider).clear();
                ref.invalidate(settingsControllerProvider);
                ref.invalidate(profileInfoProvider);
                ref.invalidate(homeDataProvider);
                ref.invalidate(recentSessionsProvider);
                ref.invalidate(phrasesProvider);
                ref.invalidate(cacheBytesProvider);
                ref.invalidate(monthlyCostProvider);
                ref.invalidate(lastLatencyProvider);
                ref.invalidate(scenarioLibraryProvider);
                ref.invalidate(materialLibraryProvider);
                ref.invalidate(wrongSegmentsProvider);
                if (context.mounted) showAppToast(context, '已清空，回到首次启动状态');
              },
            ),
          ),
        ],
      ),
    );
  }
}
