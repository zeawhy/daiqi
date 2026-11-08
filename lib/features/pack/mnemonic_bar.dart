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
    // Display when character count is valid (up to items.length, e.g. 8-char cap for 10 items)
    if (chars.isEmpty || items.isEmpty || chars.length > items.length) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 0.6),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(28, 25, 23, 0.05),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
                index: index,
                isPacked: isPacked,
                reducedMotion: reducedMotion,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _MnemonicCharWidget extends StatefulWidget {
  final String char;
  final int index;
  final bool isPacked;
  final bool reducedMotion;

  const _MnemonicCharWidget({
    required this.char,
    required this.index,
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
    final pastelBg =
        AppColors.pastelPills[widget.index % AppColors.pastelPills.length];

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
              color: widget.isPacked ? AppColors.primary : pastelBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isPacked
                  ? [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.char,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: widget.isPacked
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}
