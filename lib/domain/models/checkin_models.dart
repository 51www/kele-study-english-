/// 每日打卡补记（App 外学习活动：背单词 / 影子跟读 / 其它）。
///
/// 字段与 SQLite `daily_checkin` 表、Web 兜底 JSON 完全一致。
/// 自动打卡（口语 / 轻量 / 听写）由 session / 听写表按天聚合，不进此表；
/// 此表只记录用户手动补记的当天学习构成与备注。
class DailyCheckin {
  const DailyCheckin({
    required this.date,
    this.extraTypes = const [],
    this.note,
    required this.updatedAt,
  });

  /// 'Y-M-D'（本地时区当天）。
  final String date;

  /// vocab / shadow / other。
  final List<String> extraTypes;

  final String? note;
  final int updatedAt;

  Map<String, Object?> toMap() => <String, Object?>{
        'date': date,
        'extra_types': extraTypes.join(','),
        'note': note,
        'updated_at': updatedAt,
      };

  factory DailyCheckin.fromMap(Map<String, Object?> map) => DailyCheckin(
        date: (map['date'] ?? '') as String,
        extraTypes: ((map['extra_types'] as String?)?.isEmpty ?? true)
            ? const []
            : (map['extra_types'] as String).split(','),
        note: map['note'] as String?,
        updatedAt: (map['updated_at'] as num?)?.toInt() ?? 0,
      );

  DailyCheckin copyWith({
    List<String>? extraTypes,
    String? note,
    int? updatedAt,
  }) =>
      DailyCheckin(
        date: date,
        extraTypes: extraTypes ?? this.extraTypes,
        note: note ?? this.note,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// 今日打卡聚合：自动活动类型 + 手动补记。
class TodayCheckin {
  const TodayCheckin({
    required this.date,
    this.activityTypes = const {},
    this.manual,
  });

  final String date;

  /// spoken / quick / dictation。
  final Set<String> activityTypes;
  final DailyCheckin? manual;

  bool get checkedIn =>
      activityTypes.isNotEmpty ||
      (manual != null && manual!.extraTypes.isNotEmpty);

  Set<String> get allTypes => <String>{...activityTypes, ...?manual?.extraTypes};
}

/// 日历单日聚合。
class DayCheckin {
  DayCheckin({Set<String>? types, this.manual}) : types = types ?? <String>{};

  /// spoken / quick / dictation（自动）。
  final Set<String> types;

  /// 该日手动补记（可能为 null）。
  final DailyCheckin? manual;

  bool get checkedIn =>
      types.isNotEmpty || (manual != null && manual!.extraTypes.isNotEmpty);
}

/// 某月打卡数据 + 连续统计。
class CheckinMonth {
  const CheckinMonth({
    required this.year,
    required this.month,
    required this.days,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int year;
  final int month;
  final Map<int, DayCheckin> days;

  /// 当前连续天数（从今天往前，含手动补记）。
  final int currentStreak;

  /// 历史最长连续天数。
  final int longestStreak;

  int get checkedDays => days.values.where((d) => d.checkedIn).length;
}
