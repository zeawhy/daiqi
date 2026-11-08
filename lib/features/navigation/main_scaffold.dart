import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/services/haptic_service.dart';

class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  static const List<_NavTabConfig> _tabs = [
    _NavTabConfig(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: '清单',
    ),
    _NavTabConfig(
      icon: Icons.history_toggle_off_rounded,
      selectedIcon: Icons.manage_history_rounded,
      label: '遗忘记录',
    ),
    _NavTabConfig(
      icon: Icons.tune_rounded,
      selectedIcon: Icons.settings_rounded,
      label: '设置',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final reducedMotion =
        ref.watch(reducedMotionProvider) || MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border, width: 0.5),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(28, 25, 23, 0.06),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color.fromRGBO(28, 25, 23, 0.03),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final tab = _tabs[index];
                final isSelected = index == currentIndex;
                return Expanded(
                  child: _AnimatedNavTab(
                    config: tab,
                    isSelected: isSelected,
                    reducedMotion: reducedMotion,
                    onTap: () {
                      HapticService.selection();
                      navigationShell.goBranch(
                        index,
                        initialLocation: index == navigationShell.currentIndex,
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabConfig {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavTabConfig({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _AnimatedNavTab extends StatelessWidget {
  final _NavTabConfig config;
  final bool isSelected;
  final VoidCallback onTap;
  final bool reducedMotion;

  const _AnimatedNavTab({
    required this.config,
    required this.isSelected,
    required this.onTap,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 280),
        curve: reducedMotion ? Curves.linear : Curves.easeOutBack,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey<bool>(isSelected),
              tween: Tween<double>(
                begin: (!reducedMotion && isSelected) ? 0.75 : 1.0,
                end: 1.0,
              ),
              duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 360),
              curve: reducedMotion ? Curves.linear : Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: reducedMotion ? 1.0 : scale,
                  child: child,
                );
              },
              child: Icon(
                isSelected ? config.selectedIcon : config.icon,
                size: 21,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (reducedMotion)
              isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        config.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()
            else
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          config.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
