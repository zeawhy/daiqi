import 'package:flutter/services.dart';

class HapticService {
  static bool enabled = true;

  static void selection() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  static void mediumImpact() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void lightImpact() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  static void success() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }
}
