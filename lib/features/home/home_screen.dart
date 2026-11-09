import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/pack_models.dart';
import '../../shared/services/haptic_service.dart';
import '../../shared/widgets/dashed_border.dart';
import '../../shared/widgets/mini_backpack.dart';
import '../onboarding/onboarding_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  /// 动态主卡四级优先级选择：
  /// 1. 未完成的进行中会话 > 2. 提醒时间最近的清单 > 3. 上次用过的清单 > 4. 预设清单回退
  static ChecklistSummaryModel? selectHeroChecklist(
    List<ChecklistSummaryModel> checklists,
    DateTime now,
  ) {
    if (checklists.isEmpty) return null;

    // 1. 未完成的进行中会话
    final unfinished = checklists.where((c) => c.hasUnfinishedActiveSession).toList();
    if (unfinished.isNotEmpty) {
      unfinished.sort((a, b) => b.activeSessionStartedAt!.compareTo(a.activeSessionStartedAt!));
      return unfinished.first;
    }

    // 2. 提醒时间最近的清单（24 小时内有效提醒）
    final withReminder = <({ChecklistSummaryModel model, Duration delay})>[];
    for (final c in checklists) {
      final delay = c.nextReminderDelay(now);
      if (delay != null && delay <= const Duration(hours: 24)) {
        withReminder.add((model: c, delay: delay));
      }
    }
    if (withReminder.isNotEmpty) {
      withReminder.sort((a, b) => a.delay.compareTo(b.delay));
      return withReminder.first.model;
    }

    // 3. 上次用过的清单
    final used = checklists.where((c) => c.lastUsedAt != null).toList();
    if (used.isNotEmpty) {
      used.sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
      return used.first;
    }

    // 4. 预设清单回退
    return checklists.where((c) => c.isPreset).firstOrNull ?? checklists.first;
  }

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // Ensure preset checklist is initialized on startup
    ref.read(checklistRepositoryProvider).ensurePresetChecklist();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstLaunch() async {
    final completed = await OnboardingService.isCompleted();
    if (!completed && mounted) {
      context.push('/onboarding');
    }
  }

  String _formatWeekdaySubtitle() {
    final now = DateTime.now();
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekdayStr = weekdays[now.weekday - 1];
    final dateStr = DateFormat('M月d日').format(now);
    return '$dateStr $weekdayStr';
  }

  String _greetingBadgeText() {
    final hour = DateTime.now().hour;
    if (hour < 11) return '早安 · 出门前 30 秒确认带齐';
    if (hour < 18) return '午安 · 拖进背包再出发';
    return '晚安 · 随身物品别落下';
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(allChecklistsStreamProvider);
    final reducedMotion =
        ref.watch(reducedMotionProvider) || MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      if (_floatController.isAnimating) {
        _floatController.stop();
        _floatController.value = 0.0;
      }
    } else if (!_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: checklistsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e')),
          data: (checklists) {
            final now = DateTime.now();
            final heroList = HomeScreen.selectHeroChecklist(checklists, now);
            final otherLists =
                checklists.where((c) => c.id != heroList?.id).toList();
            final customLists = checklists.where((c) => !c.isPreset).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. Dynamic Header (带齐了 + 日期 + 纯白状态圆点问候胶囊)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(28, 25, 23, 0.05),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.doneAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _greetingBadgeText(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '带齐了',
                                style: TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  height: 1.18,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatWeekdaySubtitle(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.4,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Floating animated mini-backpack in header
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            final dy = reducedMotion
                                ? 0.0
                                : sin(_floatController.value * pi) * 4.0;
                            return Transform.translate(
                              offset: Offset(0, -dy),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(28, 25, 23, 0.05),
                                  blurRadius: 18,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: MiniBackpack(
                              progress: heroList?.progress ?? 0.0,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Dynamic Hero Shortcut Card
                if (heroList != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildHeroCard(heroList, now, reducedMotion),
                    ),
                  ),

                // 3. Subtitle "我的清单"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '我的清单',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${customLists.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (customLists.isNotEmpty)
                          const Row(
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 3),
                              Text(
                                '点 ⋯ 或长按管理',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Checklists List
                if (otherLists.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(28, 25, 23, 0.04),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Text('🎒', style: TextStyle(fontSize: 36)),
                            SizedBox(height: 10),
                            Text(
                              '还没有自建清单',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '创建通勤、健身或差旅清单，出门不再慌张',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = otherLists[index];
                          return _StaggeredCardWrapper(
                            index: index,
                            reducedMotion: reducedMotion,
                            child: _buildChecklistCard(item, reducedMotion, index: index),
                          );
                        },
                        childCount: otherLists.length,
                      ),
                    ),
                  ),

                // 5. Dashed "＋ 新建清单" button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: _buildNewChecklistButton(reducedMotion),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(ChecklistSummaryModel hero, DateTime now, bool reducedMotion) {
    final items = hero.itemNames.isNotEmpty
        ? hero.itemNames
        : const ['身份证', '手机', '钥匙', '钱包'];
    final percent = (hero.progress.clamp(0.0, 1.0) * 100).round();
    final reminderDelay = hero.nextReminderDelay(now);
    final String statusLabel;
    if (hero.hasUnfinishedActiveSession) {
      statusLabel = '进行中 · 已装 $percent%';
    } else if (reminderDelay != null && reminderDelay <= const Duration(hours: 24)) {
      statusLabel = '⏰ ${hero.reminderTime} 提醒';
    } else if (hero.lastUsedAt != null && !hero.isPreset) {
      statusLabel = '上次使用';
    } else {
      statusLabel = '经典口诀';
    }

    final String ctaText = hero.hasUnfinishedActiveSession
        ? '继续装包（还差 ${hero.remainingCount} 件）'
        : '开始装包';

    return _PressableScale(
      reducedMotion: reducedMotion,
      onTap: () => context.push('/pack/${hero.id}'),
      onLongPress: hero.isPreset ? null : () => _showCardMenu(hero),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(28, 25, 23, 0.06),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final offset = reducedMotion
                          ? 0.0
                          : sin(_floatController.value * pi * 2) * 2.5;
                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.pastelLavender,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hero.emoji,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                hero.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: hero.hasUnfinishedActiveSession
                                    ? AppColors.pastelAmber
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: hero.hasUnfinishedActiveSession
                                      ? AppColors.orange
                                      : AppColors.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: items.take(4).map((name) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  if (!hero.isPreset) ...[
                    const SizedBox(width: 4),
                    Semantics(
                      button: true,
                      label: '管理清单 ${hero.name}',
                      child: GestureDetector(
                        key: ValueKey('checklist_more_${hero.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showCardMenu(hero),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                color: AppColors.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () => context.push('/pack/${hero.id}'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ctaText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.4,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 17),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistCard(
    ChecklistSummaryModel item,
    bool reducedMotion, {
    int index = 0,
  }) {
    final reminderText = item.reminderEnabled && item.reminderTime != null
        ? ' · ⏰ ${item.reminderTime}'
        : '';
    final percent = (item.progress.clamp(0.0, 1.0) * 100).round();
    final isCompleted = item.progress >= 1.0;
    final pastelPillColor =
        AppColors.pastelPills[index % AppColors.pastelPills.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PressableScale(
        reducedMotion: reducedMotion,
        onTap: () => context.push('/pack/${item.id}'),
        onLongPress: item.isPreset ? null : () => _showCardMenu(item),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(28, 25, 23, 0.05),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Pastel circular pill icon container (Santorini Trip Plan style)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.doneLight : pastelPillColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '共 ${item.totalCount} 件$reminderText',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (percent > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.doneLight
                                      : AppColors.pastelAmber,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isCompleted ? '已带齐' : '已装 $percent%',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isCompleted
                                        ? AppColors.done
                                        : AppColors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // High risk badge if any
                  if (item.highRiskCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: AppColors.danger,
                          ),
                          Text(
                            '${item.highRiskCount} 高危',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  if (item.isPreset)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    )
                  else
                    Semantics(
                      button: true,
                      label: '管理清单 ${item.name}',
                      child: GestureDetector(
                        key: ValueKey('checklist_more_${item.id}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showCardMenu(item),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (item.progress > 0 && item.progress < 1.0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.secondaryBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewChecklistButton(bool reducedMotion) {
    return _PressableScale(
      reducedMotion: reducedMotion,
      onTap: () => context.push('/editor'),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.border,
          strokeWidth: 1.4,
          radius: 24.0,
        ),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 20),
              SizedBox(width: 6),
              Text(
                '新建专属清单',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardMenu(ChecklistSummaryModel item) {
    HapticService.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Text(item.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text('共 ${item.totalCount} 件物品'),
                ),
                const Divider(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    '立即开始装包',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/pack/${item.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('编辑'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/editor/${item.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('复制'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final repo = ref.read(checklistRepositoryProvider);
                    await repo.duplicateChecklist(item.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('删除', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDelete(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(ChecklistSummaryModel item) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('删除清单', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('确定要删除「${item.name}」吗？清单内物品和记录将被移除。'),
          actions: [
            TextButton(
              onPressed: () => dialogCtx.pop(),
              child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                dialogCtx.pop();
                final repo = ref.read(checklistRepositoryProvider);
                await repo.deleteChecklist(item.id);
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool reducedMotion;

  const _PressableScale({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.reducedMotion = false,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticService.lightImpact();
        widget.onTap?.call();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: (!widget.reducedMotion && _pressed) ? 0.97 : 1.0,
        duration: widget.reducedMotion ? Duration.zero : const Duration(milliseconds: 140),
        curve: widget.reducedMotion ? Curves.linear : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class _StaggeredCardWrapper extends StatelessWidget {
  final int index;
  final Widget child;
  final bool reducedMotion;

  const _StaggeredCardWrapper({
    required this.index,
    required this.child,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reducedMotion) return child;
    final durationMs = 260 + (index.clamp(0, 6) * 55);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
