/// Session rules according to Section 7.1 and 7.4.
class SessionRules {
  SessionRules._();

  static const Duration maxSessionResumeDuration = Duration(hours: 12);

  /// Determine if an in-progress session can be resumed.
  static bool canResumeSession({
    required DateTime startedAt,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    return currentTime.difference(startedAt) <= maxSessionResumeDuration;
  }

  /// Sort pack items according to Section 5.2 and 6.3:
  /// Group 1: High-risk unpacked
  /// Group 2: Other unpacked
  /// Group 3: Packed
  /// Group 4: Skipped ("今天不带")
  /// Within the same group, order by user's checklist sortOrder.
  static int comparePackItems({
    required bool aIsSkipped,
    required bool aIsPacked,
    required bool aIsHighRisk,
    required int aSortOrder,
    required bool bIsSkipped,
    required bool bIsPacked,
    required bool bIsHighRisk,
    required int bSortOrder,
  }) {
    int getGroup(bool isSkipped, bool isPacked, bool isHighRisk) {
      if (isSkipped) return 4;
      if (isPacked) return 3;
      if (isHighRisk) return 1;
      return 2;
    }

    final groupA = getGroup(aIsSkipped, aIsPacked, aIsHighRisk);
    final groupB = getGroup(bIsSkipped, bIsPacked, bIsHighRisk);

    if (groupA != groupB) {
      return groupA.compareTo(groupB);
    }
    return aSortOrder.compareTo(bSortOrder);
  }

  /// Calculate consecutive zero-forgot count according to Section 7.4.
  /// [sessionHadForgotRecordDescending]: Chronologically descending (newest first) departed sessions.
  /// Each session has information on whether an associated forgot record exists within 24h.
  static int calculateStreakZeroForgot(List<bool> sessionHadForgotRecordDescending) {
    int streak = 0;
    for (final hadForgot in sessionHadForgotRecordDescending) {
      if (!hadForgot) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculate streak zero forgot including departed_incomplete handling.
  /// [sessionsDescending]: Chronologically descending list of departed sessions.
  /// - 'departed_incomplete' interrupts streak
  /// - 'departed' with hadForgot=true interrupts streak
  /// - 'departed' with hadForgot=false increments streak
  static int calculateStreak({
    required List<({String status, bool hadForgot})> sessionsDescending,
  }) {
    int streak = 0;
    for (final session in sessionsDescending) {
      if (session.status == 'departed_incomplete') {
        break;
      }
      if (session.status == 'departed') {
        if (session.hadForgot) {
          break;
        } else {
          streak++;
        }
      }
    }
    return streak;
  }
}
