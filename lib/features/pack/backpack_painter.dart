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

    // Dimensions for v2 rounded arch dual-strap silhouette
    final double handleHeight = height * 0.16;
    final double handleWidth = width * 0.32;
    final double bodyTop = handleHeight * 0.72;
    final double bodyBottom = height - 2;
    final double bodyHeight = bodyBottom - bodyTop;
    final double archHeight = bodyHeight * 0.22;

    // Body margins to leave room for dual shoulder straps
    final double bodyLeft = width * 0.12;
    final double bodyRight = width * 0.88;
    final double bodyWidth = bodyRight - bodyLeft;
    final double cornerRadius = bodyWidth * 0.20;

    // Interpolated colors (Charcoal / Warm Stone -> Forest Green)
    final Color strokeColor = Color.lerp(
      AppColors.primary,
      AppColors.done,
      doneTransition,
    )!;

    final Color bodyBgColor = Color.lerp(
      AppColors.primaryLight,
      AppColors.doneLight,
      doneTransition,
    )!;

    final Color waterColor = Color.lerp(
      AppColors.primary.withValues(alpha: 0.85),
      AppColors.done.withValues(alpha: 0.88),
      doneTransition,
    )!;

    final Color backWaveColor = Color.lerp(
      AppColors.backpackHardware.withValues(alpha: 0.35),
      AppColors.doneAccent.withValues(alpha: 0.42),
      doneTransition,
    )!;

    // 1. Construct v2 Body Path (拱顶 + 竖身 + 圆弧底)
    final bodyPath = Path();
    bodyPath.moveTo(bodyLeft, bodyTop + archHeight);
    if (isOpen) {
      bodyPath.quadraticBezierTo(
        width / 2,
        bodyTop + archHeight + min(16.0, height * 0.08),
        bodyRight,
        bodyTop + archHeight,
      );
    } else {
      bodyPath.cubicTo(
        bodyLeft,
        bodyTop,
        bodyRight,
        bodyTop,
        bodyRight,
        bodyTop + archHeight,
      );
    }
    bodyPath.lineTo(bodyRight, bodyBottom - cornerRadius);
    bodyPath.arcToPoint(
      Offset(bodyRight - cornerRadius, bodyBottom),
      radius: Radius.circular(cornerRadius),
    );
    bodyPath.lineTo(bodyLeft + cornerRadius, bodyBottom);
    bodyPath.arcToPoint(
      Offset(bodyLeft, bodyBottom - cornerRadius),
      radius: Radius.circular(cornerRadius),
    );
    bodyPath.lineTo(bodyLeft, bodyTop + archHeight);
    bodyPath.close();

    // 2. Draw Soft Diffused Glow if hovered, dragged over, or done
    if (showGlow || isOpen || doneTransition > 0.2) {
      final Color glowColor = doneTransition > 0.2
          ? AppColors.done.withValues(alpha: 0.18 * doneTransition)
          : AppColors.textPrimary.withValues(alpha: 0.10);
      final Paint glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
      canvas.drawPath(bodyPath, glowPaint);
    }

    // 3. Draw Shoulder Straps (两侧双肩带弧线，位于包身后方)
    final strapPaint = Paint()
      ..color = Color.lerp(
        AppColors.backpackHardware,
        AppColors.doneAccent,
        doneTransition,
      )!
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, width * 0.026)
      ..strokeCap = StrokeCap.round;

    final Path leftStrapPath = Path()
      ..moveTo(bodyLeft + bodyWidth * 0.06, bodyTop + archHeight * 0.6)
      ..cubicTo(
        width * 0.02,
        height * 0.45,
        width * 0.02,
        height * 0.72,
        bodyLeft + bodyWidth * 0.04,
        bodyBottom - cornerRadius * 0.5,
      );
    canvas.drawPath(leftStrapPath, strapPaint);

    final Path rightStrapPath = Path()
      ..moveTo(bodyRight - bodyWidth * 0.06, bodyTop + archHeight * 0.6)
      ..cubicTo(
        width * 0.98,
        height * 0.45,
        width * 0.98,
        height * 0.72,
        bodyRight - bodyWidth * 0.04,
        bodyBottom - cornerRadius * 0.5,
      );
    canvas.drawPath(rightStrapPath, strapPaint);

    // 4. Draw Handle (提手)
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

    // Draw body background
    final bgPaint = Paint()
      ..color = bodyBgColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bgPaint);

    // 5. Draw Water Level Fill: dynamic dual sine-wave liquid (填充水位)
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

    // Subtle 3D inner highlight along top-left dome edge
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, width * 0.018)
      ..strokeCap = StrokeCap.round;
    final Path highlightPath = Path()
      ..moveTo(bodyLeft + 3, bodyTop + archHeight)
      ..cubicTo(
        bodyLeft + 3,
        bodyTop + 3,
        width * 0.35,
        bodyTop + 2,
        width * 0.42,
        bodyTop + 4,
      );
    canvas.drawPath(highlightPath, highlightPaint);

    // 6. Front lower curved pocket (圆弧前袋与缝线)
    final double pocketTop = bodyTop + bodyHeight * 0.58;
    final double pocketBottom = bodyBottom - 2;
    final double pocketLeft = bodyLeft + bodyWidth * 0.08;
    final double pocketRight = bodyRight - bodyWidth * 0.08;
    final double pocketRadius = cornerRadius * 0.7;

    final RRect pocketRRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(pocketLeft, pocketTop, pocketRight, pocketBottom),
      topLeft: Radius.circular(pocketRadius),
      topRight: Radius.circular(pocketRadius),
      bottomLeft: Radius.circular(cornerRadius * 0.8),
      bottomRight: Radius.circular(cornerRadius * 0.8),
    );

    final Color pocketStrokeColor = Color.lerp(
      AppColors.backpackHardware.withValues(alpha: width >= 60 ? 0.35 : 0.60),
      AppColors.doneAccent.withValues(alpha: 0.60),
      doneTransition,
    )!;

    canvas.drawRRect(
      pocketRRect,
      Paint()
        ..color = pocketStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, width * 0.016),
    );

    // 7. Draw Zipper (拉链与按比例缩放拉链头，修复 40dp 黑块)
    final double zipperY = bodyTop + archHeight * 0.88;
    final double zipperLeft = bodyLeft + bodyWidth * 0.10;
    final double zipperRight = bodyRight - bodyWidth * 0.10;
    final double zipperSpan = zipperRight - zipperLeft;

    final zipperLinePaint = Paint()
      ..color = AppColors.backpackHardware.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.2, width * 0.014);

    final isSmallSize = width < 60;
    final double dashWidth = isSmallSize ? 3.0 : 4.0;
    final double dashSpace = isSmallSize ? 2.0 : 3.0;
    double currentX = zipperLeft;
    while (currentX < zipperRight) {
      final double endX = min(currentX + dashWidth, zipperRight);
      canvas.drawLine(Offset(currentX, zipperY), Offset(endX, zipperY), zipperLinePaint);
      currentX += dashWidth + dashSpace;
    }

    // Zipper Slider (拉链头): size < 60 时按 size * 0.06 缩放，不设大下限
    final double sliderWidth = isSmallSize ? width * 0.06 : max(8.0, width * 0.07);
    final double sliderHeight = isSmallSize ? height * 0.08 : max(12.0, height * 0.07);

    final double targetSliderX = isOpen
        ? zipperLeft + 2.0
        : zipperLeft + (zipperSpan * zipperProgress.clamp(0.0, 1.0));
    final double sliderX = targetSliderX.clamp(
      zipperLeft + sliderWidth / 2,
      zipperRight - sliderWidth / 2,
    );

    final sliderPaint = Paint()
      ..color = AppColors.backpackHardware
      ..style = PaintingStyle.fill;

    final sliderRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(sliderX, zipperY),
        width: sliderWidth,
        height: sliderHeight,
      ),
      Radius.circular(isSmallSize ? 1.5 : 3.0),
    );
    canvas.drawRRect(sliderRect, sliderPaint);

    // Zipper pull tab (拉片): size < 60 时隐藏长拉片，彻底消除 40dp 黑块
    if (!isSmallSize) {
      final pullTabPath = Path()
        ..moveTo(sliderX - 2.5, zipperY + 4)
        ..lineTo(sliderX + 2.5, zipperY + 4)
        ..lineTo(sliderX + 2.0, zipperY + 14)
        ..lineTo(sliderX - 2.0, zipperY + 14)
        ..close();
      canvas.drawPath(pullTabPath, sliderPaint);
    }

    // 8. Draw Minimalist Completion Check Badge when done (居中对勾)
    if (smileOpacity > 0.0) {
      final Offset badgeCenter = Offset(width / 2, bodyTop + bodyHeight * 0.44);
      final double badgeRadius = max(7.0, width * 0.13);

      final Paint badgeBgPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22 * smileOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(badgeCenter, badgeRadius, badgeBgPaint);

      final Paint badgeRingPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55 * smileOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.0, width * 0.012);
      canvas.drawCircle(badgeCenter, badgeRadius, badgeRingPaint);

      final Path checkPath = Path()
        ..moveTo(badgeCenter.dx - badgeRadius * 0.38, badgeCenter.dy + badgeRadius * 0.02)
        ..lineTo(badgeCenter.dx - badgeRadius * 0.08, badgeCenter.dy + badgeRadius * 0.32)
        ..lineTo(badgeCenter.dx + badgeRadius * 0.42, badgeCenter.dy - badgeRadius * 0.26);

      final Paint checkPaint = Paint()
        ..color = Colors.white.withValues(alpha: smileOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.8, width * 0.026)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(checkPath, checkPaint);
    }

    // 9. Draw Body Stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, width * 0.028)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
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
