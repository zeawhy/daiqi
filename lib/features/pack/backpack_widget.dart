import 'package:flutter/material.dart';
import 'backpack_painter.dart';

class BackpackWidget extends StatefulWidget {
  final double progress;
  final bool isOpen;
  final bool isDone;
  final bool reducedMotion;
  final double width;
  final double height;

  const BackpackWidget({
    super.key,
    required this.progress,
    this.isOpen = false,
    this.isDone = false,
    this.reducedMotion = false,
    this.width = 190,
    this.height = 230,
  });

  @override
  State<BackpackWidget> createState() => BackpackWidgetState();
}

class BackpackWidgetState extends State<BackpackWidget>
    with TickerProviderStateMixin {
  // Squish-bounce animation controllers
  late AnimationController _squishController;
  late Animation<double> _squishYAnimation;
  late Animation<double> _squishXAnimation;

  // Water level animation
  late AnimationController _waterController;
  late Animation<double> _waterAnimation;
  double _lastProgress = 0.0;

  // Hover open animation
  late AnimationController _hoverController;
  late Animation<double> _hoverScaleAnimation;

  // All packed animation controllers
  late AnimationController _zipperController;
  late AnimationController _colorController;
  late AnimationController _smileController;
  bool _isPlayingSequence = false;

  @override
  void initState() {
    super.initState();
    _lastProgress = widget.progress;

    // Hover scale (1.0 -> 1.06)
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _hoverScaleAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutBack),
    );

    // Squish-bounce (1 -> 0.92 -> 1.04 -> 1, horizontal inverse)
    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _squishYAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.92), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.92, end: 1.04), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.04, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _squishController, curve: Curves.easeInOut));

    _squishXAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.08), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 0.96), weight: 35),
      TweenSequenceItem(tween: Tween<double>(begin: 0.96, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _squishController, curve: Curves.easeInOut));

    // Water level (300ms easeOut)
    _waterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _waterAnimation = Tween<double>(begin: widget.progress, end: widget.progress)
        .animate(CurvedAnimation(parent: _waterController, curve: Curves.easeOut));

    // All packed animations
    _zipperController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: widget.isDone ? 1.0 : 1.0,
    );

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isDone ? 1.0 : 0.0,
    );

    _smileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.isDone ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant BackpackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }

    if (widget.progress != oldWidget.progress) {
      _animateWaterLevel(widget.progress);
    }

    if (widget.isDone && !oldWidget.isDone) {
      if (!_isPlayingSequence && _smileController.value < 1.0) {
        playAllPackedSequence();
      }
    } else if (!widget.isDone && oldWidget.isDone) {
      _colorController.value = 0.0;
      _smileController.value = 0.0;
      _zipperController.value = 1.0;
    }
  }

  void _animateWaterLevel(double target) {
    if (widget.reducedMotion) {
      _waterAnimation = AlwaysStoppedAnimation(target);
      setState(() {});
      return;
    }
    _waterAnimation = Tween<double>(begin: _lastProgress, end: target).animate(
      CurvedAnimation(parent: _waterController, curve: Curves.easeOut),
    );
    _lastProgress = target;
    _waterController.forward(from: 0.0);
  }

  /// Triggers the 350ms squish-bounce animation when item drops in
  void triggerSquishBounce() {
    if (widget.reducedMotion) return;
    _squishController.forward(from: 0.0);
  }

  /// Plays all packed sequence:
  /// wait 300ms -> zipper slide left to right (600ms) -> color green (300ms) -> smile fade in
  Future<void> playAllPackedSequence({VoidCallback? onZipperStart, VoidCallback? onCompleted}) async {
    if (_isPlayingSequence) return;
    _isPlayingSequence = true;

    try {
      if (widget.reducedMotion) {
        _colorController.value = 1.0;
        _smileController.value = 1.0;
        _zipperController.value = 1.0;
        onCompleted?.call();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      onZipperStart?.call();
      _zipperController.reset();
      await _zipperController.forward();
      if (!mounted) return;

      await _colorController.forward();
      if (!mounted) return;

      await _smileController.forward();
      if (!mounted) return;

      onCompleted?.call();
    } finally {
      _isPlayingSequence = false;
    }
  }

  @override
  void dispose() {
    _squishController.dispose();
    _waterController.dispose();
    _hoverController.dispose();
    _zipperController.dispose();
    _colorController.dispose();
    _smileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Width bulging factor based on progress: 1 + 0.06 * progress
    final double bulgeFactor = 1.0 + (0.06 * widget.progress.clamp(0.0, 1.0));

    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverScaleAnimation,
        _squishYAnimation,
        _squishXAnimation,
        _waterAnimation,
        _zipperController,
        _colorController,
        _smileController,
      ]),
      builder: (context, child) {
        final double scaleY = widget.reducedMotion
            ? 1.0
            : _hoverScaleAnimation.value * _squishYAnimation.value;
        final double scaleX = widget.reducedMotion
            ? 1.0
            : _hoverScaleAnimation.value * _squishXAnimation.value * bulgeFactor;

        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()..scale(scaleX, scaleY),
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: BackpackPainter(
              progress: _waterAnimation.value,
              isOpen: widget.isOpen,
              isDone: widget.isDone,
              doneTransition: _colorController.value,
              zipperProgress: _zipperController.value,
              smileOpacity: _smileController.value,
              showGlow: widget.isOpen,
            ),
          ),
        );
      },
    );
  }
}
