import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../domain/models/pack_models.dart';
import '../../shared/widgets/brand_backpack_icon.dart';
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
          color: AppColors.borderStrong,
          strokeWidth: 1.5,
          radius: 20.0,
          dashLength: 6.0,
          dashGap: 4.0,
        ),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.north_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (isDragged) {
      // Warm editorial floating card during drag
      return Material(
        color: Colors.transparent,
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.12),
                offset: const Offset(0, 14),
                blurRadius: 28,
              ),
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                offset: const Offset(0, 4),
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

    // Packed slot representation with subtle completion badge
    if (item.isPacked) {
      return CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.done.withValues(alpha: 0.4),
          strokeWidth: 1.2,
          radius: 20.0,
        ),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.doneLight.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
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
      return CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.borderStrong,
          strokeWidth: 1.2,
          radius: 20.0,
        ),
        child: Container(
          height: 86,
          decoration: BoxDecoration(
            color: AppColors.cardPacked,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Center(
                child: _buildCardContent(
                  isPacked: false,
                  isSkipped: true,
                  isHighRisk: false,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '不带',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal unpacked editorial card with soft diffused shadow
    final isHighRisk = item.isHighRisk;
    final borderColor = isHighRisk
        ? AppColors.danger.withValues(alpha: 0.65)
        : AppColors.border;

    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isHighRisk ? 1.4 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighRisk
                ? AppColors.danger.withValues(alpha: 0.08)
                : AppColors.shadowSoft,
            offset: const Offset(0, 6),
            blurRadius: 18,
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
              top: 4,
              right: 4,
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
                    fontSize: 10.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
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
    final Color pillColor;
    if (isFloating) {
      pillColor = AppColors.primaryLight;
    } else if (isHighRisk) {
      pillColor = AppColors.dangerLight;
    } else if (isPacked) {
      pillColor = AppColors.doneLight;
    } else {
      final pastel =
          AppColors.pastelPills[item.sortOrder.abs() % AppColors.pastelPills.length];
      pillColor = Color.lerp(AppColors.background, pastel, 0.55)!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isPacked ? 0.45 : (isSkipped ? 0.55 : 1.0),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: pillColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ChecklistAvatar(
                emoji: item.emoji,
                size: 22,
                strokeWidth: 1.8,
                strokeColor: isPacked ? AppColors.done : AppColors.primary,
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
              fontWeight: isPacked ? FontWeight.w500 : FontWeight.w600,
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
