import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../shared/widgets/mini_backpack.dart';
import 'record_forgot_sheet.dart';

class ForgotScreen extends ConsumerStatefulWidget {
  const ForgotScreen({super.key});

  @override
  ConsumerState<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends ConsumerState<ForgotScreen> {
  bool _isLoading = true;
  int _departedCount = 0;
  int _forgotCount = 0;
  int _streakCount = 0;
  List<({GlobalItem item, bool isHighRisk})> _ranking = [];
  List<({ForgotRecord record, String itemName, String itemEmoji, String? listName})> _timeline =
      [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final checklistRepo = ref.read(checklistRepositoryProvider);
    final sessionRepo = ref.read(packSessionRepositoryProvider);

    final stats = await checklistRepo.getForgotStats();
    final streak = await sessionRepo.getStreakZeroForgot();
    final ranking = await checklistRepo.getTopForgottenItems();
    final timeline = await checklistRepo.getRecentForgotRecords();

    if (mounted) {
      setState(() {
        _departedCount = stats.departedCount;
        _forgotCount = stats.forgotCount;
        _streakCount = streak;
        _ranking = ranking;
        _timeline = timeline;
        _isLoading = false;
      });
    }
  }

  void _openRecordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordForgotSheet(
        onRecorded: _loadData,
      ),
    );
  }

  Future<void> _deleteRecord(String recordId) async {
    final checklistRepo = ref.read(checklistRepositoryProvider);
    await checklistRepo.deleteForgotRecord(recordId);
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已删除该遗忘记录'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatRecordTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    final timeStr = DateFormat('HH:mm').format(local);
    if (isToday) {
      return '今天 $timeStr';
    }
    return '${DateFormat('M月d日').format(local)} $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // 1. Header (Title, Subtitle, "记一笔" button)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    '遗忘记录',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '忘过的东西会被标成高危，下次排在最前面',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onPressed: _openRecordSheet,
                              icon: const Icon(Icons.edit_note, size: 20),
                              label: const Text(
                                '记一笔',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Statistics Card (出门次数, 遗忘次数, 连续零遗漏)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          elevation: 0,
                          color: AppColors.card,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                _buildStatItem('出门次数', '$_departedCount', AppColors.textPrimary),
                                Container(width: 1, height: 32, color: AppColors.border),
                                _buildStatItem('遗忘次数', '$_forgotCount', AppColors.danger),
                                Container(width: 1, height: 32, color: AppColors.border),
                                _buildStatItem('连续零遗漏', '$_streakCount', AppColors.done),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Empty State or Data Sections
                    if (_timeline.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                MiniBackpack(progress: 1.0, size: 84),
                                SizedBox(height: 20),
                                Text(
                                  '还没有忘过东西，继续保持 👍',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '出门前带齐物品，漏带时点右上角记一笔',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else ...[
                      // 3. "最常忘的东西" Ranking
                      if (_ranking.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: const Text(
                              '最常忘的东西',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              color: AppColors.card,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < _ranking.length; i++)
                                      _buildRankingItem(i + 1, _ranking[i]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // 4. "最近记录" Timeline
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: const Text(
                            '最近记录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _timeline[index];
                            final listName = item.listName ?? '未关联清单';
                            final timeStr = _formatRecordTime(item.record.createdAt);

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Dismissible(
                                key: Key(item.record.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteRecord(item.record.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        item.itemEmoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '忘了 ${item.itemName}',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$timeStr · $listName',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _timeline.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(int rank, ({GlobalItem item, bool isHighRisk}) data) {
    final maxCount = _ranking.first.item.forgotCount;
    final ratio = maxCount > 0 ? (data.item.forgotCount / maxCount).clamp(0.05, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Rank index
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? AppColors.danger : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            data.item.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          // Name + High risk indicator
          SizedBox(
            width: 72,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    data.item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (data.isHighRisk) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Bar Chart
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth * ratio;
                return Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: data.isHighRisk ? AppColors.danger : AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Count
          Text(
            '${data.item.forgotCount} 次',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
