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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(chars.length, (index) {
          final char = chars[index];
          // Check if item at index is packed
          // We find the item by sortOrder == index
          final item = items.firstWhere(
            (i) => i.sortOrder == index,
            orElse: () => items[index],
          );
          final isPacked = item.isPacked;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
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
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
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
          child: Text(
            widget.char,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: widget.isPacked ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
        );
      },
    );
  }
}
