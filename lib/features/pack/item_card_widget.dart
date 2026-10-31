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
          radius: 14.0,
          dashLength: 6.0,
          dashGap: 4.0,
        ),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }

    if (isDragged) {
      // Dragging appearance: 1.08 scale, blue 2pt border, shadow 0 12 28 rgba(0,0,0,0.18)
      return Material(
        color: Colors.transparent,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.18),
                offset: Offset(0, 12),
                blurRadius: 28,
              ),
            ],
          ),
          child: _buildCardContent(isPacked: false, isSkipped: false, isHighRisk: item.isHighRisk),
        ),
      );
    }

    // Normal slot representation
    if (item.isPacked) {
      return CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.border,
          strokeWidth: 1.5,
          radius: 14.0,
        ),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.cardPacked,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _buildCardContent(isPacked: true, isSkipped: false, isHighRisk: false),
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
            radius: 14.0,
          ),
          child: Container(
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.cardPacked,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildCardContent(isPacked: false, isSkipped: true, isHighRisk: false),
          ),
        ),
      );
    }

    // Normal unpacked card
    final isHighRisk = item.isHighRisk;
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighRisk ? AppColors.danger : AppColors.border,
          width: isHighRisk ? 2.0 : 1.0,
        ),
      ),
      child: Stack(
        children: [
          _buildCardContent(isPacked: false, isSkipped: false, isHighRisk: isHighRisk),
          if (isHighRisk)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isPacked ? 0.35 : 1.0,
            child: Text(
              item.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              decoration: isSkipped ? TextDecoration.lineThrough : null,
              color: isPacked || isSkipped ? AppColors.textSecondary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
