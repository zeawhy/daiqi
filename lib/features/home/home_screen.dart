import 'package:flutter/material.dart';
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

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure preset checklist is initialized on startup
    ref.read(checklistRepositoryProvider).ensurePresetChecklist();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
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
            // Preset checklist
            final presetList = checklists.where((c) => c.isPreset).firstOrNull;
            // Other user checklists
            final customLists = checklists.where((c) => !c.isPreset).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // 1. Header (带齐了 + 日期)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '带齐了',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatWeekdaySubtitle(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Preset Shortcut Card (伸手要钱)
                if (presetList != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildPresetCard(presetList),
                    ),
                  ),

                // 3. Subtitle "我的清单"
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '我的清单',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (customLists.length > 1)
                          const Text(
                            '长按调整顺序',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Checklists List
                if (customLists.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        child: const Text(
                          '暂无自建清单，点击下方按钮新建',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                          final item = customLists[index];
                          return _buildChecklistCard(item);
                        },
                        childCount: customLists.length,
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

  Widget _buildPresetCard(ChecklistSummaryModel preset) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(preset.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preset.itemNames.isNotEmpty
                      ? preset.itemNames.join(' · ')
                      : '身份证 · 手机 · 钥匙 · 钱包',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => context.push('/pack/${preset.id}'),
            child: const Text(
              '开始装包',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(ChecklistSummaryModel item) {
    final reminderText = item.reminderEnabled && item.reminderTime != null
        ? ' · ${item.reminderTime} 提醒'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/pack/${item.id}'),
          onLongPress: () => _showCardMenu(item),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Mini Backpack icon (44pt) showing current session pack progress
                MiniBackpack(progress: item.progress, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.totalCount} 件$reminderText',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // High risk badge if any
                if (item.highRiskCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${item.highRiskCount} 件高危',
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewChecklistButton() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: AppColors.primary,
        strokeWidth: 1.5,
        radius: 14.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/editor'),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary, size: 20),
                SizedBox(width: 6),
                Text(
                  '新建清单',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCardMenu(ChecklistSummaryModel item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item.totalCount} 件物品'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑'),
                onTap: () {
                  context.pop();
                  context.push('/editor/${item.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('复制'),
                onTap: () async {
                  context.pop();
                  final repo = ref.read(checklistRepositoryProvider);
                  await repo.duplicateChecklist(item.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('删除', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  context.pop();
                  _confirmDelete(item);
                },
              ),
            ],
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
