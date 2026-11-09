import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Vector brand backpack icon replicating launcher icon v2 silhouette:
/// - Rounded arch top (圆拱形包身顶部)
/// - Top arched handle (顶部拱形提手)
/// - Dual outward-curving shoulder straps on both sides (两侧外扩弧形双肩带)
/// - Rounded front pocket with horizontal zipper line (圆弧前袋与横拉链)
/// - Optional center checkmark (居中粗对勾 ✓)
/// Stroke width defaults to `size * 0.075`.
class BrandBackpackIcon extends StatelessWidget {
  final double size;
  final double? strokeWidth;
  final Color? strokeColor;
  final Color? hardwareColor;
  final Color? checkColor;
  final Color? fillColor;
  final bool showCheck;

  const BrandBackpackIcon({
    super.key,
    this.size = 28,
    this.strokeWidth,
    this.strokeColor,
    this.hardwareColor,
    this.checkColor,
    this.fillColor,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandBackpackPainter(
          strokeWidth: strokeWidth ?? (size * 0.075),
          strokeColor: strokeColor ?? AppColors.primary,
          hardwareColor: hardwareColor ?? AppColors.backpackHardware,
          checkColor: checkColor ?? AppColors.done,
          fillColor: fillColor,
          showCheck: showCheck,
        ),
      ),
    );
  }
}

class _BrandBackpackPainter extends CustomPainter {
  final double strokeWidth;
  final Color strokeColor;
  final Color hardwareColor;
  final Color checkColor;
  final Color? fillColor;
  final bool showCheck;

  _BrandBackpackPainter({
    required this.strokeWidth,
    required this.strokeColor,
    required this.hardwareColor,
    required this.checkColor,
    this.fillColor,
    required this.showCheck,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double sw = strokeWidth;

    // 1. Top Handle (拱形提手)
    final handlePaint = Paint()
      ..color = hardwareColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.85
      ..strokeCap = StrokeCap.round;

    final double handleWidth = w * 0.28;
    final double handleHeight = h * 0.22;
    final double handleTop = h * 0.06;
    final handleRect = Rect.fromCenter(
      center: Offset(w / 2, handleTop + handleHeight / 2),
      width: handleWidth,
      height: handleHeight,
    );
    canvas.drawArc(handleRect, pi, pi, false, handlePaint);

    // Geometry of Main Body:
    // Left/Right margin leaves space for shoulder straps
    final double bodyLeft = w * 0.16;
    final double bodyRight = w * 0.84;
    final double bodyWidth = bodyRight - bodyLeft;
    final double archPeakY = h * 0.16;
    final double archBaseY = h * 0.36;
    final double bodyBottom = h * 0.92;
    final double bottomRadius = bodyWidth * 0.20;

    // 2. Dual Shoulder Straps (两侧外扩双肩带)
    final strapPaint = Paint()
      ..color = hardwareColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.85
      ..strokeCap = StrokeCap.round;

    // Left strap: curves outward from body shoulder down to lower side
    final Path leftStrapPath = Path()
      ..moveTo(bodyLeft + bodyWidth * 0.06, archBaseY)
      ..cubicTo(
        w * 0.03,
        h * 0.45,
        w * 0.03,
        h * 0.72,
        bodyLeft + bodyWidth * 0.04,
        bodyBottom - bottomRadius * 0.4,
      );
    canvas.drawPath(leftStrapPath, strapPaint);

    // Right strap
    final Path rightStrapPath = Path()
      ..moveTo(bodyRight - bodyWidth * 0.06, archBaseY)
      ..cubicTo(
        w * 0.97,
        h * 0.45,
        w * 0.97,
        h * 0.72,
        bodyRight - bodyWidth * 0.04,
        bodyBottom - bottomRadius * 0.4,
      );
    canvas.drawPath(rightStrapPath, strapPaint);

    // 3. Main Body Path (圆拱顶 + 直立侧边 + 圆角底)
    final Path bodyPath = Path();
    bodyPath.moveTo(bodyLeft, archBaseY);
    bodyPath.cubicTo(
      bodyLeft,
      archPeakY,
      bodyRight,
      archPeakY,
      bodyRight,
      archBaseY,
    );
    bodyPath.lineTo(bodyRight, bodyBottom - bottomRadius);
    bodyPath.arcToPoint(
      Offset(bodyRight - bottomRadius, bodyBottom),
      radius: Radius.circular(bottomRadius),
    );
    bodyPath.lineTo(bodyLeft + bottomRadius, bodyBottom);
    bodyPath.arcToPoint(
      Offset(bodyLeft, bodyBottom - bottomRadius),
      radius: Radius.circular(bottomRadius),
    );
    bodyPath.lineTo(bodyLeft, archBaseY);
    bodyPath.close();

    // Body Fill if specified
    if (fillColor != null && fillColor != Colors.transparent) {
      canvas.drawPath(
        bodyPath,
        Paint()
          ..color = fillColor!
          ..style = PaintingStyle.fill,
      );
    }

    // 4. Body Stroke
    final bodyStrokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(bodyPath, bodyStrokePaint);

    // 5. Front Pocket (圆弧前袋与横拉链)
    final double pocketLeft = bodyLeft + bodyWidth * 0.10;
    final double pocketRight = bodyRight - bodyWidth * 0.10;
    final double pocketWidth = pocketRight - pocketLeft;
    final double pocketTop = h * 0.58;
    final double pocketBottom = bodyBottom - sw * 0.5;
    final double pocketRadius = bottomRadius * 0.75;

    final pocketRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(pocketLeft, pocketTop, pocketRight, pocketBottom),
      topLeft: Radius.circular(pocketRadius),
      topRight: Radius.circular(pocketRadius),
      bottomLeft: Radius.circular(bottomRadius * 0.8),
      bottomRight: Radius.circular(bottomRadius * 0.8),
    );

    final pocketPaint = Paint()
      ..color = hardwareColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw * 0.85
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(pocketRect, pocketPaint);

    // Horizontal zipper line across pocket top
    final double zipperY = pocketTop + (pocketBottom - pocketTop) * 0.22;
    canvas.drawLine(
      Offset(pocketLeft + pocketWidth * 0.08, zipperY),
      Offset(pocketRight - pocketWidth * 0.08, zipperY),
      pocketPaint,
    );

    // Zipper pull tab hanging down (when size >= 20)
    if (w >= 20) {
      final double pullTabX = pocketLeft + pocketWidth * 0.28;
      canvas.drawLine(
        Offset(pullTabX, zipperY),
        Offset(pullTabX, zipperY + (pocketBottom - zipperY) * 0.45),
        pocketPaint,
      );
    }

    // 6. Optional Center Checkmark (居中对勾 ✓)
    if (showCheck) {
      final checkPaint = Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw * 1.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final Path checkPath = Path()
        ..moveTo(w * 0.42, h * 0.45)
        ..lineTo(w * 0.48, h * 0.51)
        ..lineTo(w * 0.59, h * 0.39);
      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrandBackpackPainter oldDelegate) {
    return oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.hardwareColor != hardwareColor ||
        oldDelegate.checkColor != checkColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.showCheck != showCheck;
  }
}

/// UI-level avatar that intercepts `'🎒'` emoji to render [BrandBackpackIcon] (v2 launcher style),
/// while preserving all other category emojis and item card emojis untouched.
/// Zero database migration required.
class ChecklistAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  final double? iconSize;
  final double? strokeWidth;
  final Color? strokeColor;
  final Color? hardwareColor;
  final Color? checkColor;
  final bool showCheck;

  const ChecklistAvatar({
    super.key,
    required this.emoji,
    this.size = 24,
    this.iconSize,
    this.strokeWidth,
    this.strokeColor,
    this.hardwareColor,
    this.checkColor,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    if (emoji == '🎒') {
      return BrandBackpackIcon(
        size: iconSize ?? size,
        strokeWidth: strokeWidth,
        strokeColor: strokeColor,
        hardwareColor: hardwareColor,
        checkColor: checkColor,
        showCheck: showCheck,
      );
    }
    return Text(
      emoji,
      style: TextStyle(
        fontSize: iconSize ?? size,
      ),
    );
  }
}
