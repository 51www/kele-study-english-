import 'dart:convert';

import '../../../data/db/local_store.dart';
import '../../../domain/models/dictation_models.dart';
import '../ingest/material_import_service.dart';

class MaterialStats {
  const MaterialStats({
    required this.total,
    required this.practiced,
    required this.passed,
    required this.wrong,
    required this.accuracy,
  });

  final int total;
  final int practiced;
  final int passed;
  final int wrong;

  /// 每句取最近一次提交的正确率再平均，0 表示还没练过。
  final double accuracy;

  double get progress => total == 0 ? 0 : (passed / total).clamp(0.0, 1.0);
}

class MaterialSummary {
  const MaterialSummary({required this.item, required this.stats});

  final MaterialItem item;
  final MaterialStats stats;
}

class MaterialDetail {
  const MaterialDetail({
    required this.material,
    required this.segments,
    required this.attempts,
    required this.stats,
    required this.latestBySegment,
  });

  final MaterialItem material;
  final List<MaterialSegment> segments;
  final List<DictationAttempt> attempts;
  final MaterialStats stats;
  final Map<String, DictationAttempt> latestBySegment;
}

class WrongEntry {
  const WrongEntry({
    required this.material,
    required this.segment,
    required this.attempt,
  });

  final MaterialItem material;
  final MaterialSegment segment;
  final DictationAttempt attempt;
}

class DictationPosition {
  const DictationPosition({this.index = 0, this.mode = 'all'});

  final int index;
  final String mode; // all / wrong

  Map<String, Object?> toMap() => {'index': index, 'mode': mode};

  factory DictationPosition.fromMap(Map<String, Object?> map) => DictationPosition(
        index: (map['index'] as num?)?.toInt() ?? 0,
        mode: (map['mode'] ?? 'all') as String,
      );
}

/// 二期数据组合层：教材库 / 教材详情 / 错句本 / 听写进度。
/// 不写 session / message / correction，首页统计口径保持 MVP 原样。
class MaterialRepository {
  MaterialRepository(this._store);

  final LocalStore _store;

  Future<List<MaterialItem>> materials() => _store.materials();

  Future<List<MaterialSummary>> library() async {
    final items = await _store.materials();
    final attempts = await _store.allAttempts();
    final byMaterial = <String, Map<String, DictationAttempt>>{};
    for (final attempt in attempts) {
      (byMaterial[attempt.materialId] ??= <String, DictationAttempt>{})[attempt.segmentId] =
          attempt;
    }
    return [
      for (final item in items)
        MaterialSummary(
          item: item,
          stats: _stats(item.segmentCount, byMaterial[item.id] ?? const {}),
        ),
    ];
  }

  Future<MaterialDetail?> detail(String id) async {
    final material = await _store.material(id);
    if (material == null) return null;
    final segments = await _store.segments(id);
    final attempts = await _store.attempts(id);
    final latest = _latestBySegment(attempts);
    return MaterialDetail(
      material: material,
      segments: segments,
      attempts: attempts,
      stats: _stats(segments.length, latest),
      latestBySegment: latest,
    );
  }

  Future<List<WrongEntry>> wrongSegments() async {
    final items = await _store.materials();
    if (items.isEmpty) return const [];
    final attempts = await _store.allAttempts();
    final latest = _latestBySegment(attempts);
    final wrongIds = latest.entries
        .where((e) => !e.value.passed)
        .map((e) => e.key)
        .toSet();
    if (wrongIds.isEmpty) return const [];
    final result = <WrongEntry>[];
    for (final item in items) {
      final segments = await _store.segments(item.id);
      for (final segment in segments) {
        final attempt = latest[segment.id];
        if (attempt != null && wrongIds.contains(segment.id)) {
          result.add(WrongEntry(material: item, segment: segment, attempt: attempt));
        }
      }
    }
    // 顺序稳定：按教材创建时间，再按教材内句子序号。
    result.sort((a, b) {
      final byMaterial = a.material.createdAt.compareTo(b.material.createdAt);
      return byMaterial != 0 ? byMaterial : a.segment.seq.compareTo(b.segment.seq);
    });
    return result;
  }

  Future<void> saveSegments(String materialId, List<MaterialSegment> segments) async {
    final ordered = <MaterialSegment>[
      for (var i = 0; i < segments.length; i++) segments[i].copyWith(seq: i),
    ];
    await _store.replaceSegments(materialId, ordered);
    final item = await _store.material(materialId);
    if (item != null) {
      await _store.upsertMaterial(item.copyWith(segmentCount: ordered.length));
    }
  }

  Future<void> setHard(String segmentId, bool hard, List<MaterialSegment> all) async {
    final index = all.indexWhere((e) => e.id == segmentId);
    if (index < 0) return;
    await _store.replaceSegments(
      all.first.materialId,
      [...all]..[index] = all[index].copyWith(isHard: hard),
    );
  }

  /// 听写页可能只筛出错句，标记「太难」必须基于该教材的完整句子列表。
  Future<void> toggleHard(String materialId, String segmentId) async {
    final all = await _store.segments(materialId);
    final index = all.indexWhere((e) => e.id == segmentId);
    if (index < 0) return;
    await _store.replaceSegments(
      materialId,
      [...all]..[index] = all[index].copyWith(isHard: !all[index].isHard),
    );
  }

  Future<void> saveAttempt(DictationAttempt attempt) async {
    await _store.upsertAttempt(attempt);
    final item = await _store.material(attempt.materialId);
    if (item != null) {
      await _store.upsertMaterial(
        item.copyWith(lastPracticedAt: attempt.createdAt),
      );
    }
  }

  Future<void> deleteMaterial(MaterialItem item, MaterialImportService service) async {
    await service.deleteAsset(item);
    await _store.deleteMaterial(item.id);
    await _store.setMeta(_positionKey(item.id), '');
  }

  Future<DictationPosition> position(String materialId) async {
    final raw = await _store.meta(_positionKey(materialId));
    if (raw == null || raw.isEmpty) return const DictationPosition();
    try {
      return DictationPosition.fromMap(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return const DictationPosition();
    }
  }

  Future<void> savePosition(String materialId, DictationPosition position) =>
      _store.setMeta(_positionKey(materialId), jsonEncode(position.toMap()));

  String _positionKey(String materialId) => 'dictation.position.$materialId';

  Map<String, DictationAttempt> _latestBySegment(List<DictationAttempt> attempts) {
    final latest = <String, DictationAttempt>{};
    for (final attempt in attempts) {
      latest[attempt.segmentId] = attempt;
    }
    return latest;
  }

  MaterialStats _stats(int total, Map<String, DictationAttempt> latest) {
    final values = latest.values.toList();
    final practiced = values.length;
    final passed = values.where((e) => e.passed).length;
    final accuracy = practiced == 0
        ? 0.0
        : values.fold<double>(0, (sum, e) => sum + e.accuracy) / practiced;
    return MaterialStats(
      total: total,
      practiced: practiced,
      passed: passed,
      wrong: practiced - passed,
      accuracy: accuracy,
    );
  }
}
