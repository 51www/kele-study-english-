import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 站内「方法 / 技巧」文章（本地 JSON 副本，随 App 一起打包）。
class TipArticle {
  const TipArticle({
    required this.id,
    required this.title,
    required this.source,
    required this.author,
    required this.publishedAt,
    required this.category,
    required this.summary,
    required this.points,
    required this.url,
    required this.content,
    required this.sourceBlock,
    required this.verified,
  });

  final String id;
  final String title;
  final String source;
  final String author;
  final String publishedAt;
  final String category;
  final String summary;
  final List<String> points;
  final String url;
  final String content;
  final String sourceBlock;
  final bool verified;

  /// 正文里原有配图不下载、不打包，按里程碑要求改成「[图：说明]」占位文字；
  /// 纯文本渲染时去掉 Markdown 强调符，避免「**」原样出现在屏幕上。
  String get displayContent => content
      .replaceAllMapped(
        RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
        (match) => '[图：${match.group(1)?.trim() ?? ''}]',
      )
      .replaceAll('**', '');

  factory TipArticle.fromJson(Map<String, Object?> json) => TipArticle(
        id: (json['id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        source: (json['source'] ?? '') as String,
        author: (json['author'] ?? '') as String,
        publishedAt: (json['publishedAt'] ?? '') as String,
        category: (json['category'] ?? '方法') as String,
        summary: (json['summary'] ?? '') as String,
        points: ((json['points'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        url: (json['url'] ?? '') as String,
        content: (json['content'] ?? '') as String,
        sourceBlock: (json['sourceBlock'] ?? '') as String,
        verified: json['verified'] != null,
      );
}

class TipsRepository {
  TipsRepository();

  static const assetPath = 'docs/tips-share/articles.json';

  Future<List<TipArticle>> all() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final items = decoded['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) => TipArticle.fromJson(e.cast<String, Object?>()))
        .where((e) => e.title.isNotEmpty && e.content.isNotEmpty)
        .toList();
  }
}
