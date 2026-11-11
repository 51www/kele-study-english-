import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'ingest/material_import_service.dart';
import 'repository/material_repository.dart';

final materialRepositoryProvider = Provider<MaterialRepository>(
  (ref) => MaterialRepository(ref.watch(localStoreProvider)),
);

final materialImportServiceProvider = Provider<MaterialImportService>(
  (ref) => MaterialImportService(ref.watch(localStoreProvider)),
);

/// 教材库：每份教材的已练句数 / 正确率只从 dictation_attempt 聚合。
final materialLibraryProvider = FutureProvider<List<MaterialSummary>>((ref) {
  return ref.watch(materialRepositoryProvider).library();
});

/// 教材详情：句子、最近一次提交与状态统计。
final materialDetailProvider =
    FutureProvider.family<MaterialDetail?, String>((ref, id) {
  return ref.watch(materialRepositoryProvider).detail(id);
});

/// 错句本：跨教材汇总最近一次未通过的句子，顺序稳定。
final wrongSegmentsProvider = FutureProvider<List<WrongEntry>>((ref) {
  return ref.watch(materialRepositoryProvider).wrongSegments();
});
