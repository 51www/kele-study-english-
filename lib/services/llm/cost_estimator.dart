import 'llm_models.dart';

/// 一次模型请求的成本样本（人民币）。
class CostSample {
  const CostSample({required this.cny, required this.estimated});

  final double cny;

  /// true 表示接口没给 usage，按字符数本地估算；UI 必须标注「估算」。
  final bool estimated;
}

/// 成本估算（M4 / T4.5）。
///
/// 优先用 OpenAI 兼容响应里的 `usage`；缺失时按「4 字符 ≈ 1 token」兜底。
/// 单价是本地可解释的估算常量，不是厂商账单；因此界面统一标注「估算」。
class CostEstimator {
  CostEstimator._();

  /// ¥ / 1K tokens，按常见中低价模型量级估算。
  static const double inputPer1k = 0.014;
  static const double outputPer1k = 0.042;
  static const double charsPerToken = 4;

  static CostSample estimate({
    required int promptChars,
    required String output,
    LlmUsage? usage,
  }) {
    if (usage != null && usage.totalTokens > 0) {
      final input = usage.promptTokens > 0
          ? usage.promptTokens
          : (usage.totalTokens * 0.7).round();
      final completion = usage.completionTokens > 0
          ? usage.completionTokens
          : (usage.totalTokens - input).clamp(0, usage.totalTokens);
      return CostSample(
        cny: input / 1000 * inputPer1k + completion / 1000 * outputPer1k,
        estimated: false,
      );
    }
    final inputTokens = promptChars / charsPerToken;
    final outputTokens = output.length / charsPerToken;
    return CostSample(
      cny: inputTokens / 1000 * inputPer1k + outputTokens / 1000 * outputPer1k,
      estimated: true,
    );
  }

  static String format(double cny) =>
      '¥${cny.toStringAsFixed(cny > 0 && cny < 0.01 ? 3 : 2)}';
}
