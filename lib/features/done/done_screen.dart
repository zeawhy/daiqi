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
  String? _checklistName;
  List<String> _packedItemNames = [];
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
    final checklistRepo = ref.read(checklistRepositoryProvider);
    final items = await sessionRepo.getPackItems(widget.sessionId, widget.listId);
    final streak = await sessionRepo.getStreakZeroForgot();
    final checklist = await checklistRepo.getChecklist(widget.listId);

    final activeItems = items.where((i) => !i.isSkipped).toList();
    final packedItems = activeItems.where((i) => i.isPacked).toList();

    if (mounted) {
      setState(() {
        _totalCount = activeItems.length;
        _packedCount = packedItems.length;
        _streakCount = streak;
        _checklistName = checklist?.name;
        _packedItemNames = packedItems.map((i) => i.name).toList();
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
    final reducedMotion =
        ref.read(reducedMotionProvider) || MediaQuery.disableAnimationsOf(context);
    setState(() => _isDeparting = true);

    HapticService.lightImpact();
    AudioService.playDoor();

    // Play closing door animation when reducedMotion is off
    if (!reducedMotion) {
      await _doorAnimController.forward();
    }

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
    final reducedMotion =
        ref.watch(reducedMotionProvider) || MediaQuery.disableAnimationsOf(context);

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
                    final tight = constraints.maxHeight < 680;
                    final backpackWidth = compact ? 110.0 : (tight ? 145.0 : 176.0);
                    final backpackHeight = compact ? 132.0 : (tight ? 174.0 : 210.0);
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: compact ? 4 : 12,
                      ),
                      child: Column(
                        children: [
                          // Top back button (white capsule with >=48dp accessible hit target)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Semantics(
                              button: true,
                              label: '返回',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticService.selection();
                                  _handleBackDeparture();
                                },
                                child: SizedBox(
                                  height: compact ? 38 : 48,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: compact ? 32 : 38,
                                      constraints: const BoxConstraints(minWidth: 76),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: AppColors.card,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: AppColors.shadowSoft,
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        widthFactor: 1.0,
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
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(vertical: compact ? 4 : 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 16 : 24,
                                    vertical: compact ? 12 : (tight ? 18 : 24),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.shadowSoft,
                                        blurRadius: 24,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!compact && _checklistName != null && _checklistName!.isNotEmpty) ...[
                                        Container(
                                          key: const ValueKey('done_checklist_pill'),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            _checklistName!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: tight ? 10 : 14),
                                      ],
                                      BackpackWidget(
                                        progress: 1.0,
                                        isDone: true,
                                        reducedMotion: reducedMotion,
                                        width: backpackWidth,
                                        height: backpackHeight,
                                      ),
                                      SizedBox(height: compact ? 10 : (tight ? 14 : 18)),

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

                                      // Subtitle: N / N 件已装包 + celebratory streak badge
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Text(
                                            '$_packedCount / $_totalCount 件已装包',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              fontFeatures: [FontFeature.tabularFigures()],
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          if (_streakCount >= 2)
                                            Container(
                                              key: const ValueKey('done_streak_badge'),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.doneLight,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '连续 $_streakCount 次零遗漏 🔥',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  fontFeatures: [FontFeature.tabularFigures()],
                                                  color: AppColors.done,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (!compact && _packedItemNames.isNotEmpty) ...[
                                        SizedBox(height: tight ? 10 : 14),
                                        Wrap(
                                          key: const ValueKey('done_packed_items_wrap'),
                                          alignment: WrapAlignment.center,
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            ..._packedItemNames.take(6).map((name) {
                                              return ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 112),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                    vertical: 3.5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.doneLight,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.check_rounded,
                                                        size: 12,
                                                        color: AppColors.done,
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Flexible(
                                                        child: Text(
                                                          name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.w500,
                                                            color: AppColors.done,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                            if (_packedItemNames.length > 6)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryLight,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '+${_packedItemNames.length - 6}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    fontFeatures: [FontFeature.tabularFigures()],
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Departure Button: 出门 🚪 (Full capsule StadiumBorder, height: 54)
                          SizedBox(
                            width: double.infinity,
                            height: compact ? 48 : 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onDark,
                                disabledBackgroundColor: AppColors.disabledBg,
                                disabledForegroundColor: AppColors.disabledFg,
                                shape: const StadiumBorder(),
                              ),
                              onPressed: _isDeparting ? null : _handleDepart,
                              child: const Text(
                                '出门 🚪',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 8),

                          // Bottom link: 还是忘了东西？记一笔 (>=48dp touch target in normal layout)
                          Semantics(
                            button: true,
                            label: '还是忘了东西？记一笔',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticService.selection();
                                _openRecordForgotSheet();
                              },
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: compact ? 34 : 48,
                                  minWidth: 160,
                                ),
                                child: const Center(
                                  widthFactor: 1.0,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 0 : 6),
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
                                    color: AppColors.onDarkSubtle,
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
                                    color: AppColors.onDarkSubtle,
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
