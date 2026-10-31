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
  final int highRiskCount;
  final List<String> itemNames;

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
    required this.highRiskCount,
    required this.itemNames,
  });

  double get progress => totalCount == 0 ? 0.0 : (packedCount / totalCount).clamp(0.0, 1.0);
}
