/// Normalizes item names for GlobalItem cross-list identity matching.
/// Specification (Section 7.2):
/// 去掉首尾空格，英文转小写，全角字符转半角。
class NameNormalizer {
  NameNormalizer._();

  static String normalize(String input) {
    var s = input.trim().toLowerCase();

    // Convert full-width characters to half-width
    final buffer = StringBuffer();
    for (int i = 0; i < s.runes.length; i++) {
      final code = s.runes.elementAt(i);
      if (code == 0x3000) {
        // Full-width space
        buffer.write(' ');
      } else if (code >= 0xFF01 && code <= 0xFF5E) {
        // Full-width ASCII variants (！ to ～)
        buffer.writeCharCode(code - 0xFEE0);
      } else {
        buffer.writeCharCode(code);
      }
    }

    return buffer.toString().trim();
  }
}
