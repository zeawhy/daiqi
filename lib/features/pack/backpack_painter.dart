import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class BackpackPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final bool isOpen; // Dragging card hover over backpack
  final bool isDone; // All packed
  final double doneTransition; // 0.0 to 1.0 (blue to green)
  final double zipperProgress; // 0.0 (left) to 1.0 (right closed)
  final double smileOpacity; // 0.0 to 1.0
  final bool showGlow;
  final double wavePhase; // Continuous phase (0 to 2*pi) for dynamic wave sloshing

  BackpackPainter({
    required this.progress,
    this.isOpen = false,
    this.isDone = false,
    this.doneTransition = 0.0,
    this.zipperProgress = 1.0,
    this.smileOpacity = 0.0,
    this.showGlow = false,
    this.wavePhase = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Dimensions
    final double handleHeight = height * 0.16;
    final double handleWidth = width * 0.38;
    final double bodyTop = handleHeight * 0.75;
    final double bodyBottom = height;
    final double bodyHeight = bodyBottom - bodyTop;
    final double cornerRadius = width * 0.18;

    // Interpolated colors
    final Color strokeColor = Color.lerp(
      AppColors.primary,
      AppColors.doneAccent,
      doneTransition,
    )!;

    final Color bodyBgColor = Color.lerp(
      AppColors.primaryLight,
      AppColors.doneLight,
      doneTransition,
    )!;

    final Color waterColor = Color.lerp(
      AppColors.primary.withValues(alpha: 0.88),
      AppColors.doneAccent.withValues(alpha: 0.88),
      doneTransition,
    )!;

    final Color backWaveColor = Color.lerp(
      AppColors.primary.withValues(alpha: 0.42),
      AppColors.doneAccent.withValues(alpha: 0.42),
      doneTransition,
    )!;

    // 1. Draw Aura Glow if hovered, dragged over, or done
    if (showGlow || isOpen || doneTransition > 0.2) {
      final Color glowColor = doneTransition > 0.2
          ? AppColors.doneAccent.withValues(alpha: 0.28 * doneTransition)
          : AppColors.primary.withValues(alpha: 0.26);
      final Paint glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      final glowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, bodyTop + 4, width - 8, bodyHeight - 8),
        Radius.circular(cornerRadius + 4),
      );
      canvas.drawRRect(glowRect, glowPaint);
    }

    // 2. Draw Handle (提手)
    final handlePaint = Paint()
      ..color = AppColors.backpackHardware
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.5, width * 0.026)
      ..strokeCap = StrokeCap.round;

    final handleRect = Rect.fromCenter(
      center: Offset(width / 2, bodyTop + 2),
      width: handleWidth,
      height: handleHeight * 1.8,
    );
    canvas.drawArc(handleRect, pi, pi, false, handlePaint);

    // 3. Draw Body Path
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        width * 0.04,
        bodyTop,
        width * 0.92,
        bodyHeight - 2,
      ),
      Radius.circular(cornerRadius),
    );

    // If mouth is open, create slightly curved opening at top
    final bodyPath = Path();
    if (isOpen) {
      final rect = bodyRRect.outerRect;
      final r = cornerRadius;
      bodyPath.moveTo(rect.left + r, rect.top);
      // Top curve dipped slightly inward for "open mouth"
      bodyPath.quadraticBezierTo(
        rect.center.dx,
        rect.top + 14,
        rect.right - r,
        rect.top,
      );
      bodyPath.arcToPoint(Offset(rect.right, rect.top + r), radius: Radius.circular(r));
      bodyPath.lineTo(rect.right, rect.bottom - r);
      bodyPath.arcToPoint(Offset(rect.right - r, rect.bottom), radius: Radius.circular(r));
      bodyPath.lineTo(rect.left + r, rect.bottom);
      bodyPath.arcToPoint(Offset(rect.left, rect.bottom - r), radius: Radius.circular(r));
      bodyPath.lineTo(rect.left, rect.top + r);
      bodyPath.arcToPoint(Offset(rect.left + r, rect.top), radius: Radius.circular(r));
      bodyPath.close();
    } else {
      bodyPath.addRRect(bodyRRect);
    }

    // Draw body background
    final bgPaint = Paint()
      ..color = bodyBgColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bgPaint);

    // 4. Draw Water Level Fill: dynamic dual sine-wave liquid (填充水位)
    if (progress > 0.0) {
      canvas.save();
      canvas.clipPath(bodyPath);

      final double clampedProgress = progress.clamp(0.0, 1.0);
      final fillHeight = (bodyHeight - 2) * clampedProgress;
      final waterTop = bodyBottom - fillHeight;

      if (fillHeight > 0) {
        final double waveAmp = (clampedProgress > 0.02 && clampedProgress < 0.98)
            ? (height * 0.026)
            : (height * 0.006);

        // Back wave (secondary crest)
        final Path backWavePath = Path()..moveTo(0, bodyBottom);
        for (double x = 0; x <= width; x += 4) {
          final double y = waterTop +
              sin((x / width * 2 * pi) - wavePhase + 1.2) * (waveAmp * 1.15);
          backWavePath.lineTo(x, y);
        }
        backWavePath.lineTo(width, bodyBottom);
        backWavePath.close();
        canvas.drawPath(backWavePath, Paint()..color = backWaveColor);

        // Front wave (primary liquid)
        final Path frontWavePath = Path()..moveTo(0, bodyBottom);
        for (double x = 0; x <= width; x += 4) {
          final double y =
              waterTop + sin((x / width * 2 * pi) + wavePhase) * waveAmp;
          frontWavePath.lineTo(x, y);
        }
        frontWavePath.lineTo(width, bodyBottom);
        frontWavePath.close();
        canvas.drawPath(frontWavePath, Paint()..color = waterColor);

        // Rising effervescent bubbles inside liquid when width >= 80
        if (width >= 80 && clampedProgress > 0.15) {
          final Paint bubblePaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.28)
            ..style = PaintingStyle.fill;
          for (int i = 0; i < 4; i++) {
            final double bx = width * (0.22 + i * 0.19);
            final double cycle = ((wavePhase / (2 * pi)) + i * 0.27) % 1.0;
            final double by = bodyBottom - (fillHeight * 0.85 * cycle);
            if (by > waterTop + 6) {
              canvas.drawCircle(Offset(bx, by), 2.5 + (i % 2) * 1.5, bubblePaint);
            }
          }
        }
      }
      canvas.restore();
    }

    // Subtle 3D inner highlight along top-left edge
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(bodyRRect.left + 2, bodyTop + 6, cornerRadius * 1.4,
          cornerRadius * 1.4),
      pi,
      pi * 0.45,
      false,
      highlightPaint,
    );

    // Front lower pocket seam detail (only on full-size backpack)
    if (width >= 100) {
      final RRect pocketRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          width * 0.14,
          bodyTop + bodyHeight * 0.62,
          width * 0.72,
          bodyHeight * 0.28,
        ),
        Radius.circular(cornerRadius * 0.55),
      );
      canvas.drawRRect(
        pocketRRect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // 5. Draw Zipper (拉链)
    final double zipperY = bodyTop + bodyHeight * 0.22;
    final double zipperLeft = width * 0.12;
    final double zipperRight = width * 0.88;
    final double zipperSpan = zipperRight - zipperLeft;

    final zipperLinePaint = Paint()
      ..color = AppColors.backpackHardware.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, width * 0.016);

    // Dashed line for zipper track
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double currentX = zipperLeft;
    while (currentX < zipperRight) {
      final double endX = min(currentX + dashWidth, zipperRight);
      canvas.drawLine(Offset(currentX, zipperY), Offset(endX, zipperY), zipperLinePaint);
      currentX += dashWidth + dashSpace;
    }

    // Zipper Slider (拉链头)
    final double sliderX = isOpen
        ? zipperLeft + 4.0 // Pulled open to the side
        : zipperLeft + (zipperSpan * zipperProgress.clamp(0.0, 1.0));

    final sliderPaint = Paint()
      ..color = AppColors.backpackHardware
      ..style = PaintingStyle.fill;

    final sliderRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(sliderX, zipperY),
        width: max(8.0, width * 0.07),
        height: max(12.0, height * 0.07),
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(sliderRect, sliderPaint);

    // Zipper pull tab (拉片)
    final pullTabPath = Path()
      ..moveTo(sliderX - 2.5, zipperY + 4)
      ..lineTo(sliderX + 2.5, zipperY + 4)
      ..lineTo(sliderX + 2.0, zipperY + 14)
      ..lineTo(sliderX - 2.0, zipperY + 14)
      ..close();
    canvas.drawPath(pullTabPath, sliderPaint);

    // 6. Draw Smile Face (笑脸) when done
    if (smileOpacity > 0.0) {
      final faceColor = Colors.white.withValues(alpha: smileOpacity);
      final facePaint = Paint()
        ..color = faceColor
        ..style = PaintingStyle.fill;

      final double faceCenterY = bodyTop + bodyHeight * 0.58;
      final double eyeDistance = width * 0.15;
      final double eyeRadius = max(3.5, width * 0.035);

      if (width >= 80) {
        // Happy curved eyes (^ ^) on full-size backpack
        final Paint happyEyePaint = Paint()
          ..color = faceColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(3.0, width * 0.03)
          ..strokeCap = StrokeCap.round;
        final double happyEyeRadius = max(5.5, width * 0.035);
        canvas.drawArc(
          Rect.fromCircle(
              center: Offset(width / 2 - eyeDistance, faceCenterY - 2),
              radius: happyEyeRadius),
          pi * 1.1,
          pi * 0.8,
          false,
          happyEyePaint,
        );
        canvas.drawArc(
          Rect.fromCircle(
              center: Offset(width / 2 + eyeDistance, faceCenterY - 2),
              radius: happyEyeRadius),
          pi * 1.1,
          pi * 0.8,
          false,
          happyEyePaint,
        );

        // Rosy cheeks
        final Paint cheekPaint = Paint()
          ..color = AppColors.cheekPink.withValues(alpha: 0.65 * smileOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(width * 0.31, faceCenterY - 1),
            width: 11,
            height: 6.5,
          ),
          cheekPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(width * 0.69, faceCenterY - 1),
            width: 11,
            height: 6.5,
          ),
          cheekPaint,
        );
      } else {
        // Left eye & right eye
        canvas.drawCircle(Offset(width / 2 - eyeDistance, faceCenterY - 4), eyeRadius, facePaint);
        canvas.drawCircle(Offset(width / 2 + eyeDistance, faceCenterY - 4), eyeRadius, facePaint);
      }

      // Smile mouth arc
      final mouthPaint = Paint()
        ..color = faceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3.0, width * 0.03)
        ..strokeCap = StrokeCap.round;

      final mouthRect = Rect.fromCenter(
        center: Offset(width / 2, faceCenterY + 4),
        width: width * 0.24,
        height: height * 0.12,
      );
      canvas.drawArc(mouthRect, 0.2 * pi, 0.6 * pi, false, mouthPaint);
    } else if (isOpen && width >= 80) {
      // Expectant "Feed Me!" expression when dragging item over backpack
      final double faceCenterY = bodyTop + bodyHeight * 0.58;
      final Color exprColor = progress.clamp(0.0, 1.0) > 0.55
          ? Colors.white.withValues(alpha: 0.9)
          : strokeColor.withValues(alpha: 0.75);
      final Paint eyePaint = Paint()
        ..color = exprColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(width * 0.39, faceCenterY - 4), 4.2, eyePaint);
      canvas.drawCircle(Offset(width * 0.61, faceCenterY - 4), 4.2, eyePaint);

      // Cute surprised "O" mouth
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(width / 2, faceCenterY + 6),
          width: 11,
          height: 13,
        ),
        Paint()
          ..color = exprColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6,
      );
    }

    // 7. Draw Body Stroke (4pt)
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.5, width * 0.036);
    canvas.drawPath(bodyPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant BackpackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isOpen != isOpen ||
        oldDelegate.isDone != isDone ||
        oldDelegate.doneTransition != doneTransition ||
        oldDelegate.zipperProgress != zipperProgress ||
        oldDelegate.smileOpacity != smileOpacity ||
        oldDelegate.showGlow != showGlow ||
        oldDelegate.wavePhase != wavePhase;
  }
}
