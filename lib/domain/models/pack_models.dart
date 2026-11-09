class PackItemModel {
  final String listItemId;
  final String globalItemId;
  final String name;
  final String emoji;
  final int sortOrder;
  final bool isPacked;
  final bool isHighRisk;
  final bool isSkipped;
  final DateTime? packedAt;

  const PackItemModel({
    required this.listItemId,
    required this.globalItemId,
    required this.name,
    required this.emoji,
    required this.sortOrder,
    required this.isPacked,
    required this.isHighRisk,
    required this.isSkipped,
    this.packedAt,
  });

  PackItemModel copyWith({
    String? listItemId,
    String? globalItemId,
    String? name,
    String? emoji,
    int? sortOrder,
    bool? isPacked,
    bool? isHighRisk,
    bool? isSkipped,
    DateTime? packedAt,
  }) {
    return PackItemModel(
      listItemId: listItemId ?? this.listItemId,
      globalItemId: globalItemId ?? this.globalItemId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      sortOrder: sortOrder ?? this.sortOrder,
      isPacked: isPacked ?? this.isPacked,
      isHighRisk: isHighRisk ?? this.isHighRisk,
      isSkipped: isSkipped ?? this.isSkipped,
      packedAt: packedAt ?? this.packedAt,
    );
  }
}

class ChecklistSummaryModel {
  final String id;
  final String name;
  final String emoji;
  final bool isPreset;
  final String? mnemonic;
  final int sortOrder;
  final bool reminderEnabled;
  final String? reminderTime;
  final List<int> reminderWeekdays;
  final int totalCount;
  final int packedCount;
  final int skippedCount;
  final int highRiskCount;
  final List<String> itemNames;
  final DateTime? activeSessionStartedAt;
  final DateTime? lastUsedAt;

  const ChecklistSummaryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isPreset,
    this.mnemonic,
    required this.sortOrder,
    required this.reminderEnabled,
    this.reminderTime,
    required this.reminderWeekdays,
    required this.totalCount,
    required this.packedCount,
    this.skippedCount = 0,
    required this.highRiskCount,
    required this.itemNames,
    this.activeSessionStartedAt,
    this.lastUsedAt,
  });

  /// 当前会话有效应装总数（扣除“今天不带”跳过的物品）
  int get activeTotalCount => (totalCount - skippedCount).clamp(0, totalCount);

  double get progress =>
      activeTotalCount == 0 ? 0.0 : (packedCount / activeTotalCount).clamp(0.0, 1.0);

  // 剩余未装件数
  int get remainingCount => (activeTotalCount - packedCount).clamp(0, activeTotalCount);

  // 是否存在未完成的进行中会话（12 小时有效期内且尚未全部装完）
  bool get hasUnfinishedActiveSession =>
      activeSessionStartedAt != null && activeTotalCount > 0 && packedCount < activeTotalCount;

  /// 计算距离下一次定时提醒的时间间隔（仅当启用提醒且时间/星期有效时返回非空）。
  Duration? nextReminderDelay(DateTime now) {
    if (!reminderEnabled || reminderTime == null || reminderWeekdays.isEmpty) {
      return null;
    }
    final parts = reminderTime!.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    for (int dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + dayOffset,
        hour,
        minute,
      );
      if (!reminderWeekdays.contains(candidate.weekday)) continue;
      final diff = candidate.difference(now);
      // 允许刚到点 15 分钟内的提醒仍视为当前临近提醒
      if (diff >= const Duration(minutes: -15)) {
        return diff.isNegative ? Duration.zero : diff;
      }
    }
    return null;
  }
}
