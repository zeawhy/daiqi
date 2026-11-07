import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/pack_models.dart';
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
    if (hour < 11) return '☀️ 早安 · 出门前 30 秒确认带齐';
    if (hour < 18) return '🌤️ 午安 · 拖进背包再出发';
    return '🌙 晚安 · 随身物品别落下';
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(allChecklistsStreamProvider);

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
                // 1. Dynamic Header (带齐了 + 日期 + 活力问候胶囊)
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
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _greetingBadgeText(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '带齐了',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatWeekdaySubtitle(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Floating animated mini-backpack mascot in header
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            final dy = sin(_floatController.value * pi) * 4.0;
                            return Transform.translate(
                              offset: Offset(0, -dy),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
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
                      child: _buildHeroCard(heroList, now),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
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
                                color: AppColors.secondaryBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${customLists.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
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
                                fontWeight: FontWeight.w700,
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
                            child: _buildChecklistCard(item),
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
                    child: _buildNewChecklistButton(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(ChecklistSummaryModel hero, DateTime now) {
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
      onTap: () => context.push('/pack/${hero.id}'),
      onLongPress: hero.isPreset ? null : () => _showCardMenu(hero),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              right: -20,
              top: -24,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              right: 55,
              bottom: -28,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          final offset = sin(_floatController.value * pi * 2) * 3.0;
                          return Transform.translate(
                            offset: Offset(0, offset),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hero.emoji,
                            style: const TextStyle(fontSize: 32),
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
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
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
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.more_horiz_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
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
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(ChecklistSummaryModel item) {
    final reminderText = item.reminderEnabled && item.reminderTime != null
        ? ' · ⏰ ${item.reminderTime}'
        : '';
    final percent = (item.progress.clamp(0.0, 1.0) * 100).round();
    final isCompleted = item.progress >= 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PressableScale(
        onTap: () => context.push('/pack/${item.id}'),
        onLongPress: item.isPreset ? null : () => _showCardMenu(item),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCompleted
                  ? AppColors.done.withValues(alpha: 0.45)
                  : AppColors.border,
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Mini Backpack icon (46pt) showing current session pack progress
                  MiniBackpack(progress: item.progress, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
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
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (percent > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.doneLight
                                      : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isCompleted ? '已带齐' : '已装 $percent%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? AppColors.done
                                        : AppColors.primary,
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 6),
                  if (item.isPreset)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryBg,
                        borderRadius: BorderRadius.circular(10),
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
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

  Widget _buildNewChecklistButton() {
    return _PressableScale(
      onTap: () => context.push('/editor'),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.primary,
          strokeWidth: 1.6,
          radius: 18.0,
        ),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                '新建专属清单',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardMenu(ChecklistSummaryModel item) {
    HapticFeedback.mediumImpact();
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

  const _PressableScale({
    required this.child,
    this.onTap,
    this.onLongPress,
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
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class _StaggeredCardWrapper extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredCardWrapper({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
