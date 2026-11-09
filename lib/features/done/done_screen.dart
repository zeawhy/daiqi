import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/services/audio_service.dart';
import '../../shared/services/haptic_service.dart';
import '../forgot/record_forgot_sheet.dart';
import '../pack/backpack_widget.dart';

class DoneScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String listId;

  const DoneScreen({
    super.key,
    required this.sessionId,
    required this.listId,
  });

  @override
  ConsumerState<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends ConsumerState<DoneScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _doorAnimController;
  late Animation<double> _doorAnimation;

  int _totalCount = 0;
  int _packedCount = 0;
  int _streakCount = 0;
  bool _isLoading = true;
  bool _isDeparting = false;

  @override
  void initState() {
    super.initState();
    _doorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _doorAnimation = CurvedAnimation(
      parent: _doorAnimController,
      curve: Curves.easeInOut,
    );

    _loadData();
  }

  Future<void> _loadData() async {
    final sessionRepo = ref.read(packSessionRepositoryProvider);
    final items = await sessionRepo.getPackItems(widget.sessionId, widget.listId);
    final streak = await sessionRepo.getStreakZeroForgot();

    final activeItems = items.where((i) => !i.isSkipped).toList();
    final packed = activeItems.where((i) => i.isPacked).length;

    if (mounted) {
      setState(() {
        _totalCount = activeItems.length;
        _packedCount = packed;
        _streakCount = streak;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _doorAnimController.dispose();
    super.dispose();
  }

  /// Section 5.3: Departure action
  Future<void> _handleDepart() async {
    if (_isDeparting) return;
    setState(() => _isDeparting = true);

    HapticService.lightImpact();
    AudioService.playDoor();

    // Play closing door animation
    await _doorAnimController.forward();

    // Mark session departed
    await ref.read(packSessionRepositoryProvider).updateSessionStatus(
          widget.sessionId,
          'departed',
          departedAt: DateTime.now().toUtc(),
        );

    if (mounted) {
      context.go('/');
    }
  }

  /// Section 5.3: "如果用户在完成页直接返回，不点'出门'，也视为已出门（会话状态写为 departed）"
  Future<void> _handleBackDeparture() async {
    if (_isDeparting) return;
    _isDeparting = true;

    await ref.read(packSessionRepositoryProvider).updateSessionStatus(
          widget.sessionId,
          'departed',
          departedAt: DateTime.now().toUtc(),
        );

    if (mounted) {
      context.go('/');
    }
  }

  void _openRecordForgotSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecordForgotSheet(
        sessionId: widget.sessionId,
        listId: widget.listId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = ref.watch(reducedMotionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackDeparture();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 520;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: compact ? 6 : 16,
                      ),
                      child: Column(
                        children: [
                          // Top back button (white capsule with soft shadow)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: _handleBackDeparture,
                              child: Container(
                                height: compact ? 32 : 38,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                alignment: Alignment.centerLeft,
                                width: 76,
                                child: const Center(
                                  child: Text(
                                    '‹ 返回',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),

                          // Editorial commemorative white card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 16 : 24,
                              vertical: compact ? 12 : 28,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(28, 25, 23, 0.05),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BackpackWidget(
                                  progress: 1.0,
                                  isDone: true,
                                  reducedMotion: reducedMotion,
                                  width: compact ? 110 : 185,
                                  height: compact ? 132 : 220,
                                ),
                                SizedBox(height: compact ? 10 : 24),

                                // Title: 全部带齐，出门吧！
                                Text(
                                  '全部带齐，出门吧！',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: compact ? 20 : 23,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    height: 1.28,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Subtitle: N / N 件已装包 (· 连续 X 次零遗漏 🔥 if streak >= 2)
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '$_packedCount / $_totalCount 件已装包',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (_streakCount >= 2)
                                      Text(
                                        '· 连续 $_streakCount 次零遗漏 🔥',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.done,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Departure Button: 出门 🚪 (Full capsule StadiumBorder, height: 54)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _isDeparting ? null : _handleDepart,
                              child: const Text(
                                '出门 🚪',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 14),

                          // Bottom link: 还是忘了东西？记一笔
                          GestureDetector(
                            onTap: _openRecordForgotSheet,
                            child: const Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Text.rich(
                                TextSpan(
                                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                  children: [
                                    TextSpan(text: '还是忘了东西？'),
                                    TextSpan(
                                      text: '记一笔',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 12),
                        ],
                      ),
                    );
                  },
                ),

              // Door closing transition overlay
              if (_isDeparting && !reducedMotion)
                AnimatedBuilder(
                  animation: _doorAnimation,
                  builder: (context, _) {
                    return Positioned.fill(
                      child: Row(
                        children: [
                          // Left door panel
                          Expanded(
                            child: Transform.translate(
                              offset: Offset(
                                -(1.0 - _doorAnimation.value) *
                                    MediaQuery.of(context).size.width /
                                    2,
                                0,
                              ),
                              child: Container(
                                color: AppColors.textPrimary,
                                child: const Center(
                                  child: Icon(
                                    Icons.door_front_door_outlined,
                                    color: Colors.white24,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Right door panel
                          Expanded(
                            child: Transform.translate(
                              offset: Offset(
                                (1.0 - _doorAnimation.value) *
                                    MediaQuery.of(context).size.width /
                                    2,
                                0,
                              ),
                              child: Container(
                                color: AppColors.textPrimary,
                                child: const Center(
                                  child: Icon(
                                    Icons.door_sliding_outlined,
                                    color: Colors.white24,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
