/// High-risk evaluation logic according to Section 7.3.
class HighRiskRules {
  HighRiskRules._();

  static const int expirationDays = 60;
  static const int requiredConsecutivePacked = 3;

  /// Check whether an item is currently high-risk.
  /// [lastForgotAt]: When it was last recorded as forgotten.
  /// [consecutivePackedCountAfterLastForgot]: How many consecutive times it has been packed
  /// in departed sessions since the last forgot record.
  /// [now]: Reference time (defaults to DateTime.now()).
  static bool isHighRisk({
    required DateTime? lastForgotAt,
    required int consecutivePackedCountAfterLastForgot,
    DateTime? now,
  }) {
    if (lastForgotAt == null) return false;

    final currentTime = now ?? DateTime.now();
    final difference = currentTime.difference(lastForgotAt);

    // Rule 1: Expiration after 60 days
    if (difference.inDays >= expirationDays) {
      return false;
    }

    // Rule 2: Cleared after 3 consecutive successful packings in departed sessions
    if (consecutivePackedCountAfterLastForgot >= requiredConsecutivePacked) {
      return false;
    }

    return true;
  }
}
