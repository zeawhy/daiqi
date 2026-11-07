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

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    _isFinishing = true;

    // Request notification permission (Section 5.8: 可以跳过)
    await NotificationService.requestPermission();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Header title
              const SizedBox(height: 12),
              const Text(
                '带齐了',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isDone ? '就是这样！出门前把东西都装进包里' : '试试把钥匙拖进包里',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _isDone ? AppColors.done : AppColors.primary,
                ),
              ),
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
                    child: SizedBox(
                      width: 110,
                      height: 86,
                      child: const ItemCardWidget(item: _keyItem),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Animated finger guide
                if (!reducedMotion)
                  AnimatedBuilder(
                    animation: _fingerYAnimation,
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(0, _fingerYAnimation.value),
                        child: const Icon(
                          Icons.touch_app,
                          size: 34,
                          color: AppColors.primary,
                        ),
                      );
                    },
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
                    width: 200,
                    height: 240,
                  );
                },
              ),
              const Spacer(),

              // "开始使用" button (appears when packed & done)
              if (_isDone) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.done,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _finishOnboarding,
                    child: const Text(
                      '开始使用',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
