import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/pack_models.dart';
import '../../shared/services/audio_service.dart';
import '../../shared/services/haptic_service.dart';
import '../../shared/services/notification_service.dart';
import '../pack/backpack_widget.dart';
import '../pack/item_card_widget.dart';

class OnboardingService {
  static const String _flagName = 'onboarding_completed.flag';
  static bool _completedMemory = false;

  static Future<bool> isCompleted() async {
    if (_completedMemory) return true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_flagName');
      final exists = await file.exists();
      if (exists) _completedMemory = true;
      return exists;
    } catch (_) {
      return _completedMemory;
    }
  }

  static Future<void> markCompleted() async {
    if (_completedMemory) return;
    _completedMemory = true;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_flagName');
      await file.writeAsString('1');
    } catch (_) {}
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final GlobalKey<BackpackWidgetState> _backpackKey = GlobalKey();
  final GlobalKey _backpackContainerKey = GlobalKey();

  late AnimationController _fingerController;
  late Animation<double> _fingerYAnimation;

  bool _isPacked = false;
  bool _isDone = false;
  bool _isFinishing = false;

  static const _keyItem = PackItemModel(
    listItemId: 'onboarding_key',
    globalItemId: 'g_key',
    name: '钥匙',
    emoji: '🔑',
    sortOrder: 0,
    isPacked: false,
    isHighRisk: false,
    isSkipped: false,
  );

  @override
  void initState() {
    super.initState();

    // Finger guide animation: moves vertically down to show drag path
    _fingerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _fingerYAnimation = Tween<double>(begin: 0.0, end: 160.0).animate(
      CurvedAnimation(parent: _fingerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fingerController.dispose();
    super.dispose();
  }

  void _onPackItem() {
    if (_isPacked) return;
    setState(() {
      _isPacked = true;
    });

    _fingerController.stop();

    HapticService.mediumImpact();
    AudioService.playRandomPop();
    _backpackKey.currentState?.triggerSquishBounce();

    // Trigger all-packed celebration after 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _backpackKey.currentState?.playAllPackedSequence(
        onZipperStart: () {
          AudioService.playZip();
          HapticService.success();
        },
        onCompleted: () {
          if (mounted) {
            setState(() {
              _isDone = true;
            });
          }
        },
      );
    });
  }

  Future<void> _finishOnboarding({bool skipPermission = false}) async {
    if (_isFinishing) return;
    _isFinishing = true;

    final wasCompleted = await OnboardingService.isCompleted();
    // Request notification permission only on initial completion (Section 5.8: 可以跳过)
    if (!skipPermission && !wasCompleted) {
      await NotificationService.requestPermission();
    }
    await OnboardingService.markCompleted();

    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion =
        ref.watch(reducedMotionProvider) || MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      if (_fingerController.isAnimating) {
        _fingerController.stop();
      }
    } else if (!_isPacked && !_fingerController.isAnimating) {
      _fingerController.repeat();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 620;
            final fingerScale = compact ? 0.35 : 1.0;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: compact ? 8 : 16,
              ),
              child: Column(
                children: [
                  // Top action bar: Skip button
                  SizedBox(
                    height: compact ? 36 : 44,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: !_isDone
                          ? Semantics(
                              button: true,
                              label: '跳过引导',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticService.selection();
                                  _finishOnboarding(skipPermission: true);
                                },
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 64,
                                    minHeight: 36,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color.fromRGBO(28, 25, 23, 0.05),
                                        blurRadius: 12,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '跳过',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // Header title (Santorini L1: 28sp w700 tracking 1.0)
                  SizedBox(height: compact ? 2 : 6),
                  const Text(
                    '带齐了',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      height: 1.20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isDone ? '就是这样！出门前把东西都装进包里' : '试试把钥匙拖进包里',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: _isDone ? AppColors.done : AppColors.primary,
                    ),
                  ),
                  if (!_isPacked) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '也可以直接轻点卡片装包',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),

                  // Item card & Finger drag path
                  if (!_isPacked) ...[
                    Draggable<String>(
                      data: 'key',
                      feedback: Material(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: 110,
                          height: 86,
                          child: ItemCardWidget(
                            item: _keyItem,
                            isDragged: true,
                          ),
                        ),
                      ),
                      childWhenDragging: const SizedBox(
                        width: 110,
                        height: 86,
                        child: ItemCardWidget(
                          item: _keyItem,
                          isPlaceholder: true,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: _onPackItem,
                        child: const SizedBox(
                          width: 110,
                          height: 86,
                          child: ItemCardWidget(item: _keyItem),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 12),

                    // Animated finger guide (or static arrow in reducedMotion)
                    if (!reducedMotion)
                      AnimatedBuilder(
                        animation: _fingerYAnimation,
                        builder: (context, _) {
                          return Transform.translate(
                            offset: Offset(0, _fingerYAnimation.value * fingerScale),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 34,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      )
                    else
                      const Icon(
                        Icons.south_rounded,
                        size: 28,
                        color: AppColors.textSecondary,
                      ),
                  ],

                  const Spacer(),

                  // Backpack area (Drag Target)
                  DragTarget<String>(
                    key: _backpackContainerKey,
                    onAcceptWithDetails: (_) => _onPackItem(),
                    builder: (context, candidateData, rejectedData) {
                      return BackpackWidget(
                        key: _backpackKey,
                        progress: _isPacked ? 1.0 : 0.0,
                        isOpen: candidateData.isNotEmpty,
                        isDone: _isDone,
                        reducedMotion: reducedMotion,
                        width: compact ? 130 : 200,
                        height: compact ? 156 : 240,
                      );
                    },
                  ),
                  const Spacer(),

                  // "开始使用" button (appears when packed & done)
                  if (_isDone) ...[
                    SizedBox(
                      width: double.infinity,
                      height: compact ? 48 : 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.done,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _finishOnboarding,
                        child: const Text(
                          '开始使用',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 12),
                  ] else
                    SizedBox(height: compact ? 16 : 62),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
