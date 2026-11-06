import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../domain/models/pack_models.dart';
import '../../shared/widgets/dashed_border.dart';

class ItemCardWidget extends StatelessWidget {
  final PackItemModel item;
  final bool isPlaceholder;
  final bool isDragged;

  const ItemCardWidget({
    super.key,
    required this.item,
    this.isPlaceholder = false,
    this.isDragged = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPlaceholder) {
      // Placeholder box at original position during drag
      return CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.primary,
          strokeWidth: 2.0,
          radius: 16.0,
          dashLength: 6.0,
          dashGap: 4.0,
        ),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.north_rounded,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.45),
          ),
        ),
      );
    }

    if (isDragged) {
      // Playful floating 3D card during drag
      return Material(
        color: Colors.transparent,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                offset: const Offset(0, 12),
                blurRadius: 24,
              ),
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                offset: Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: _buildCardContent(
            isPacked: false,
            isSkipped: false,
            isHighRisk: item.isHighRisk,
            isFloating: true,
          ),
        ),
      );
    }

    // Packed slot representation with cheerful green completion badge
    if (item.isPacked) {
      return CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.done.withValues(alpha: 0.45),
          strokeWidth: 1.5,
          radius: 16.0,
        ),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.doneLight.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Center(
                child: _buildCardContent(
                  isPacked: true,
                  isSkipped: false,
                  isHighRisk: false,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.done,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (item.isSkipped) {
      return Opacity(
        opacity: 0.55,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: AppColors.border,
            strokeWidth: 1.5,
            radius: 16.0,
          ),
          child: Container(
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.cardPacked,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildCardContent(
              isPacked: false,
              isSkipped: true,
              isHighRisk: false,
            ),
          ),
        ),
      );
    }

    // Normal unpacked tactile card with 3D bottom lip
    final isHighRisk = item.isHighRisk;
    final borderColor = isHighRisk ? AppColors.danger : AppColors.border;

    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isHighRisk ? 2.0 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighRisk
                ? AppColors.danger.withValues(alpha: 0.16)
                : AppColors.border.withValues(alpha: 0.85),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: _buildCardContent(
              isPacked: false,
              isSkipped: false,
              isHighRisk: isHighRisk,
            ),
          ),
          if (isHighRisk)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '必带',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardContent({
    required bool isPacked,
    required bool isSkipped,
    required bool isHighRisk,
    bool isFloating = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isPacked ? 0.45 : 1.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isFloating
                    ? AppColors.primaryLight
                    : (isHighRisk
                        ? AppColors.dangerLight.withValues(alpha: 0.6)
                        : AppColors.background),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                item.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.15,
              fontWeight: isPacked ? FontWeight.w500 : FontWeight.w700,
              decoration: isSkipped ? TextDecoration.lineThrough : null,
              color: isPacked
                  ? AppColors.done
                  : (isSkipped ? AppColors.textSecondary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
