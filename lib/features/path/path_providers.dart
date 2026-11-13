import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/models/models.dart';
import '../dictation/providers.dart';
import 'path_model.dart';
import 'path_plan.dart';

/// 路径状态：只用一个 `app_meta` 键，零改表、双端零改动。
final learningPathProvider = FutureProvider<LearningPathState>((ref) async {
  final raw = await ref.watch(localStoreProvider).meta(pathMetaKey);
  return LearningPathState.decode(raw);
});

/// 把既有本地数据聚成一份快照，再交给纯函数算计划。
/// 全程无网络、无模型调用；断网 / 无密钥时路径与进度照样可看。
final pathPlanProvider = FutureProvider<PathPlan>((ref) async {
  final state = await ref.watch(learningPathProvider.future);
  final home = await ref.watch(homeDataProvider.future);
  final sessions = await ref.watch(recentSessionsProvider.future);
  final reviewItems = await ref.watch(reviewItemsProvider.future);
  final due = await ref.watch(dueReviewItemsProvider.future);
  final phrases = await ref.watch(phrasesProvider.future);
  final trends = await ref.watch(trendsProvider.future);
  final materials = await ref.watch(materialLibraryProvider.future);
  final settings = ref.watch(settingsControllerProvider);

  final practiceCounts = <String, int>{};
  final hintByScenario = <String, int>{};
  final lastCompletedAtByScenario = <String, int>{};
  for (final session in sessions) {
    final id = session.scenarioId;
    if (id == null || id.isEmpty) continue;
    if (session.turnCount > 0) {
      practiceCounts[id] = (practiceCounts[id] ?? 0) + 1;
    }
    // sessions 按 started_at DESC，第一次出现即最近一次。
    if (!hintByScenario.containsKey(id)) hintByScenario[id] = session.hintCount;
    if (session.status == 'completed' &&
        session.startedAt > (lastCompletedAtByScenario[id] ?? 0)) {
      lastCompletedAtByScenario[id] = session.startedAt;
    }
  }

  final snapshot = PathSnapshot(
    sessions: sessions,
    scenarios: home.scenarios,
    practiceCounts: practiceCounts,
    hintByScenario: hintByScenario,
    lastCompletedAtByScenario: lastCompletedAtByScenario,
    trends: trends,
    now: DateTime.now(),
    phrasesCount: phrases.length,
    masteredCount: phrases.where((e) => e.mastered).length,
    dueCount: due.length,
    consolidatedCount: reviewItems.where((e) => e.consolidated).length,
    weekSessions: home.weekSessions,
    todayMinutes: home.todayMinutes,
    materialCount: materials.length,
    materialPracticedCount: materials.where((e) => e.stats.practiced > 0).length,
    levelSetting: settings[SettingsKeys.level] ?? 'B1',
  );
  return computePathPlan(state, snapshot);
});

/// 所有写入都从这里走，集中失效，避免某个入口显示旧进度。
void invalidatePathProviders(WidgetRef ref) {
  ref.invalidate(learningPathProvider);
  ref.invalidate(pathPlanProvider);
  ref.invalidate(todayPlanProvider);
  ref.invalidate(homeDataProvider);
  ref.invalidate(scenarioLibraryProvider);
}

Future<void> writePath(WidgetRef ref, LearningPathState state) async {
  await ref.read(localStoreProvider).setMeta(pathMetaKey, state.encode());
  invalidatePathProviders(ref);
}

Future<void> updatePath(
  WidgetRef ref,
  LearningPathState Function(LearningPathState state) update,
) async {
  final current = await ref.read(learningPathProvider.future);
  await writePath(ref, update(current));
}
