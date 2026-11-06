import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../domain/models/pack_models.dart';

class MnemonicBar extends StatelessWidget {
  final String mnemonic;
  final List<PackItemModel> items;
  final bool reducedMotion;

  const MnemonicBar({
    super.key,
    required this.mnemonic,
    required this.items,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final chars = mnemonic.characters.toList();
    // Only display when character count matches items count
    if (chars.length != items.length || items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(chars.length, (index) {
          final char = chars[index];
          // Check if item at index is packed
          final item = items.firstWhere(
            (i) => i.sortOrder == index,
            orElse: () => items[index],
          );
          final isPacked = item.isPacked;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _MnemonicCharWidget(
              char: char,
              isPacked: isPacked,
              reducedMotion: reducedMotion,
            ),
          );
        }),
      ),
    );
  }
}

class _MnemonicCharWidget extends StatefulWidget {
  final String char;
  final bool isPacked;
  final bool reducedMotion;

  const _MnemonicCharWidget({
    required this.char,
    required this.isPacked,
    required this.reducedMotion,
  });

  @override
  State<_MnemonicCharWidget> createState() => _MnemonicCharWidgetState();
}

class _MnemonicCharWidgetState extends State<_MnemonicCharWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.32), weight: 45),
      TweenSequenceItem(tween: Tween<double>(begin: 1.32, end: 0.94), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 0.94, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _MnemonicCharWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPacked && !oldWidget.isPacked && !widget.reducedMotion) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.reducedMotion ? 1.0 : _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: widget.isPacked ? AppColors.primaryGradient : null,
              color: widget.isPacked ? null : AppColors.secondaryBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: widget.isPacked
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.char,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: widget.isPacked
                    ? Colors.white
                    : AppColors.textSecondary.withValues(alpha: 0.65),
              ),
            ),
          ),
        );
      },
    );
  }
}
