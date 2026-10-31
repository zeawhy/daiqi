import 'package:flutter/material.dart';
import '../../features/pack/backpack_painter.dart';

class MiniBackpack extends StatelessWidget {
  final double progress;
  final double size;

  const MiniBackpack({
    super.key,
    required this.progress,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = progress >= 1.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BackpackPainter(
          progress: progress,
          isOpen: false,
          isDone: isDone,
          doneTransition: isDone ? 1.0 : 0.0,
          zipperProgress: 1.0,
          smileOpacity: isDone ? 1.0 : 0.0,
          showGlow: false,
        ),
      ),
    );
  }
}
