/// Appendix A: Common items and emoji mapping presets.
class EmojiPresets {
  EmojiPresets._();

  static const String fallbackEmoji = '📦';

  static const List<MapEntry<List<String>, String>> _keywordMapping = [
    MapEntry(['身份证'], '🆔'),
    MapEntry(['护照'], '🛂'),
    MapEntry(['手机'], '📱'),
    MapEntry(['钥匙'], '🔑'),
    MapEntry(['钱包'], '👛'),
    MapEntry(['银行卡', '卡'], '💳'),
    MapEntry(['充电器', '充电线'], '🔌'),
    MapEntry(['充电宝'], '🔋'),
    MapEntry(['耳机'], '🎧'),
    MapEntry(['电脑', '笔记本'], '💻'),
    MapEntry(['雨伞', '伞'], '☂️'),
    MapEntry(['眼镜'], '👓'),
    MapEntry(['墨镜'], '🕶️'),
    MapEntry(['口罩'], '😷'),
    MapEntry(['药'], '💊'),
    MapEntry(['水杯', '水壶'], '🥤'),
    MapEntry(['纸巾'], '🧻'),
    MapEntry(['工牌', '门禁卡'], '🏷️'),
    MapEntry(['外套'], '🧥'),
    MapEntry(['牙刷'], '🪥'),
    MapEntry(['防晒'], '🧴'),
    MapEntry(['相机'], '📷'),
    MapEntry(['书'], '📖'),
    MapEntry(['帽子'], '🧢'),
    MapEntry(['运动鞋'], '👟'),
    MapEntry(['午饭', '饭盒'], '🍱'),
  ];

  /// Top 12 common items for quick tags.
  static const List<String> commonShortcuts = [
    '身份证',
    '手机',
    '钥匙',
    '钱包',
    '充电器',
    '充电宝',
    '耳机',
    '电脑',
    '雨伞',
    '口罩',
    '纸巾',
    '水杯',
  ];

  /// Match emoji by keywords. If matched, returns the emoji; otherwise returns fallback 📦.
  static String matchEmoji(String itemName) {
    final trimmed = itemName.trim();
    if (trimmed.isEmpty) return fallbackEmoji;

    for (final entry in _keywordMapping) {
      for (final keyword in entry.key) {
        if (trimmed.contains(keyword)) {
          return entry.value;
        }
      }
    }
    return fallbackEmoji;
  }
}
