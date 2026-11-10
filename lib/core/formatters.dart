String formatDuration(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final m = (safe ~/ 60).toString().padLeft(2, '0');
  final s = (safe % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

String formatMinutes(int seconds) {
  if (seconds <= 0) return '0 分钟';
  final minutes = (seconds / 60).round();
  return '$minutes 分钟';
}

String formatDate(DateTime time) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(time.year, time.month, time.day);
  final diff = today.difference(target).inDays;
  String two(int v) => v.toString().padLeft(2, '0');
  if (diff == 0) return '今天 ${two(time.hour)}:${two(time.minute)}';
  if (diff == 1) return '昨天 ${two(time.hour)}:${two(time.minute)}';
  if (time.year == now.year) {
    return '${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }
  return '${time.year}-${two(time.month)}-${two(time.day)}';
}

String greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 6) return '夜深了';
  if (hour < 12) return '早上好';
  if (hour < 14) return '中午好';
  if (hour < 18) return '下午好';
  return '晚上好';
}
