import 'package:flutter_test/flutter_test.dart';
import 'package:daiqi/domain/rules/name_normalizer.dart';
import 'package:daiqi/domain/rules/high_risk_rules.dart';
import 'package:daiqi/domain/rules/session_rules.dart';
import 'package:daiqi/shared/constants/emoji_presets.dart';

void main() {
  group('NameNormalizer Tests (Section 7.2)', () {
    test('trims whitespace and converts English to lowercase', () {
      expect(NameNormalizer.normalize('  iPhone  '), equals('iphone'));
      expect(NameNormalizer.normalize('MacBook Pro'), equals('macbook pro'));
    });

    test('converts full-width characters to half-width', () {
      // Full-width letters and numbers: ＡＢＣ -> abc, １２３ -> 123
      expect(NameNormalizer.normalize('ＡＢＣ'), equals('abc'));
      expect(NameNormalizer.normalize('手机１２３'), equals('手机123'));
      // Full-width space (U+3000)
      expect(NameNormalizer.normalize('身份证　证件'), equals('身份证 证件'));
    });
  });

  group('HighRiskRules Tests (Section 7.3)', () {
    final now = DateTime.utc(2026, 10, 31, 12, 0);

    test('never forgot is not high risk', () {
      final result = HighRiskRules.isHighRisk(
        lastForgotAt: null,
        consecutivePackedCountAfterLastForgot: 0,
        now: now,
      );
      expect(result, isFalse);
    });

    test('forgot within 60 days with < 3 consecutive packings is high risk', () {
      final forgotAt = now.subtract(const Duration(days: 10));
      // 0 packings
      expect(
        HighRiskRules.isHighRisk(
          lastForgotAt: forgotAt,
          consecutivePackedCountAfterLastForgot: 0,
          now: now,
        ),
        isTrue,
      );
      // 2 packings
      expect(
        HighRiskRules.isHighRisk(
          lastForgotAt: forgotAt,
          consecutivePackedCountAfterLastForgot: 2,
          now: now,
        ),
        isTrue,
      );
    });

    test('cleared when consecutive packings reaches 3', () {
      final forgotAt = now.subtract(const Duration(days: 10));
      expect(
        HighRiskRules.isHighRisk(
          lastForgotAt: forgotAt,
          consecutivePackedCountAfterLastForgot: 3,
          now: now,
        ),
        isFalse,
      );
    });

    test('cleared when elapsed days >= 60', () {
      final forgotAt = now.subtract(const Duration(days: 61));
      expect(
        HighRiskRules.isHighRisk(
          lastForgotAt: forgotAt,
          consecutivePackedCountAfterLastForgot: 0,
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('SessionRules Tests (Section 7.1, 7.4)', () {
    final now = DateTime.utc(2026, 10, 31, 12, 0);

    test('can resume session within 12 hours', () {
      final startedAt = now.subtract(const Duration(hours: 11));
      expect(SessionRules.canResumeSession(startedAt: startedAt, now: now), isTrue);
    });

    test('cannot resume session over 12 hours', () {
      final startedAt = now.subtract(const Duration(hours: 13));
      expect(SessionRules.canResumeSession(startedAt: startedAt, now: now), isFalse);
    });

    test('pack item sorting order: High-risk -> Unpacked -> Packed -> Skipped', () {
      // a: High-risk unpacked
      // b: Normal unpacked
      // c: Packed
      // d: Skipped
      final cmpAB = SessionRules.comparePackItems(
        aIsSkipped: false,
        aIsPacked: false,
        aIsHighRisk: true,
        aSortOrder: 0,
        bIsSkipped: false,
        bIsPacked: false,
        bIsHighRisk: false,
        bSortOrder: 1,
      );
      expect(cmpAB, lessThan(0)); // High risk comes before normal

      final cmpBC = SessionRules.comparePackItems(
        aIsSkipped: false,
        aIsPacked: false,
        aIsHighRisk: false,
        aSortOrder: 0,
        bIsSkipped: false,
        bIsPacked: true,
        bIsHighRisk: false,
        bSortOrder: 1,
      );
      expect(cmpBC, lessThan(0)); // Unpacked comes before packed

      final cmpCD = SessionRules.comparePackItems(
        aIsSkipped: false,
        aIsPacked: true,
        aIsHighRisk: false,
        aSortOrder: 0,
        bIsSkipped: true,
        bIsPacked: false,
        bIsHighRisk: false,
        bSortOrder: 1,
      );
      expect(cmpCD, lessThan(0)); // Packed comes before skipped
    });

    test('streak zero-forgot counting', () {
      // False means no forgot record (clean), True means forgot record occurred
      final list1 = [false, false, false];
      expect(SessionRules.calculateStreakZeroForgot(list1), equals(3));

      final list2 = [false, false, true, false, false];
      expect(SessionRules.calculateStreakZeroForgot(list2), equals(2));

      final list3 = [true, false, false];
      expect(SessionRules.calculateStreakZeroForgot(list3), equals(0));
    });
  });

  group('EmojiPresets Tests (Appendix A)', () {
    test('matches known keywords properly', () {
      expect(EmojiPresets.matchEmoji('身份证'), equals('🆔'));
      expect(EmojiPresets.matchEmoji('带了手机'), equals('📱'));
      expect(EmojiPresets.matchEmoji('钥匙包'), equals('🔑'));
      expect(EmojiPresets.matchEmoji('我的笔记本电脑'), equals('💻'));
    });

    test('returns fallback 📦 for unknown items', () {
      expect(EmojiPresets.matchEmoji('火柴盒'), equals('📦'));
    });
  });
}
