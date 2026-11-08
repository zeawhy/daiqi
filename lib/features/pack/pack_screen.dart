import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../domain/models/pack_models.dart';
import '../../shared/constants/emoji_presets.dart';
import '../../shared/services/audio_service.dart';
import '../../shared/services/haptic_service.dart';
import 'backpack_widget.dart';
import 'item_card_widget.dart';
import 'mnemonic_bar.dart';

class PackScreen extends ConsumerStatefulWidget {
  final String checklistId;

  const PackScreen({super.key, required this.checklistId});

  @override
  ConsumerState<PackScreen> createState() => _PackScreenState();
}

class _PackScreenState extends ConsumerState<PackScreen>
    with TickerProviderStateMixin {
  final GlobalKey<BackpackWidgetState> _backpackKey = GlobalKey<BackpackWidgetState>();
  final GlobalKey _backpackAreaKey = GlobalKey();

  ChecklistList? _checklist;
  PackSession? _session;
  bool _isLoading = true;

  final GlobalKey _overlayKey = GlobalKey();

  // Pointer drag state
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridAreaKey = GlobalKey();
  PackItemModel? _draggingItem;
  int? _activePointerId;
  // Set when GestureDetector's long press wins for the current pointer, so that
  // the Listener's raw pointer-up is not mistaken for a tap.
  bool _longPressFired = false;
  // Latched to true as soon as the pointer moves > 8pt from _dragStartPointer,
  // even for packed items (which return early in _onPointerMove and never set
  // _draggingItem), preventing scroll gestures from triggering unpack on release.
  bool _pointerMovedBeyondTapSlop = false;
  Offset? _dragStartPointer;
  Offset? _currentPointer;
  Offset? _cardSlotCenter;
  Size? _cardSlotSize;
  double _tiltAngle = 0.0;
  bool _isHoveringDropZone = false;
  final Map<String, GlobalKey> _itemKeys = {};
  bool _highRiskBannerExpanded = false;

  // Flight animations
  AnimationController? _flightController;
  Animation<double>? _flightProgress;
  Offset _flightFromGlobal = Offset.zero;
  Offset Function() _flightToGlobal = _zeroOffset;
  Size _flightCardSize = const Size(110, 86);
  Animation<double>? _flightScaleAnimation;
  Animation<double>? _flightOpacityAnimation;
  PackItemModel? _flyingItem;

  static Offset _zeroOffset() => Offset.zero;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final checklistRepo = ref.read(checklistRepositoryProvider);
    final sessionRepo = ref.read(packSessionRepositoryProvider);

    final cl = await checklistRepo.getChecklist(widget.checklistId);
    if (cl == null) {
      if (mounted) context.pop();
      return;
    }

    final session = await sessionRepo.getOrCreateSession(widget.checklistId);

    if (mounted) {
      setState(() {
        _checklist = cl;
        _session = session;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flightController?.dispose();
    super.dispose();
  }

  /// Calculates the backpack drop zone in global coordinates.
  Rect? _getBackpackDropZone() {
    final renderBox = _backpackAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final globalPos = renderBox.localToGlobal(Offset.zero);
    final rect = Rect.fromLTWH(
      globalPos.dx,
      globalPos.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
    // Section 6.1: Drop zone is backpack bounding box expanded by 24pt
    return rect.inflate(24.0);
  }

  /// Center top of the backpack opening in global coordinates.
  Offset? _getBackpackMouthGlobalPosition() {
    final renderBox = _backpackAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final globalPos = renderBox.localToGlobal(Offset.zero);
    // Mouth is near top center of backpack
    return Offset(
      globalPos.dx + renderBox.size.width / 2,
      globalPos.dy + renderBox.size.height * 0.22,
    );
  }

  /// Center of an item's slot in GLOBAL coordinates (same semantics as the
  /// backpack mouth and the pointer position: a center point).
  Offset? _getItemGlobalCenter(String listItemId) {
    final box = _itemKeys[listItemId]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  Size? _getItemSize(String listItemId) {
    final key = _itemKeys[listItemId];
    final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.size;
  }

  /// GLOBAL -> local coordinates of the overlay Stack. Handles status bar,
  /// display cutout, gesture bar and landscape insets uniformly.
  Offset _toOverlayLocal(Offset global) {
    final box = _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global; // first frame only
    return box.globalToLocal(global);
  }

  /// Resolver used as flight target: tracks the slot every frame (scroll /
  /// re-sort safe) and falls back to the last known center.
  Offset Function() _slotCenterResolver(String listItemId, Offset fallback) {
    var last = fallback;
    return () => last = _getItemGlobalCenter(listItemId) ?? last;
  }

  // --- Pointer Drag Implementation (> 8pt start drag, tilt ±10°) ---

  void _onPointerDown(PointerDownEvent event, PackItemModel item) {
    if (item.isSkipped || _flyingItem != null) return;
    if (_activePointerId != null) return; // Ignore second finger (Section 11)
    _activePointerId = event.pointer;
    _longPressFired = false;
    _pointerMovedBeyondTapSlop = false;
    _dragStartPointer = event.position;
    _currentPointer = event.position;
    _cardSlotCenter = _getItemGlobalCenter(item.listItemId);
    _cardSlotSize = _getItemSize(item.listItemId);
  }

  void _onPointerMove(PointerMoveEvent event, PackItemModel item) {
    if (!mounted) return;
    if (event.pointer != _activePointerId) return;
    if (_dragStartPointer == null) return;

    final distance = (event.position - _dragStartPointer!).distance;
    if (distance > 8.0) {
      _pointerMovedBeyondTapSlop = true;
    }
    if (item.isPacked) return; // Packed items cannot be dragged

    // Start dragging after moving > 8pt (Section 6.1)
    if (_draggingItem == null && distance > 8.0) {
      _draggingItem = item;
      HapticService.selection();
    }

    if (_draggingItem != null) {
      final dx = event.delta.dx;
      // Tilt card according to horizontal velocity / movement within ±10° (Section 6.1)
      final targetTilt = (dx * 2.5 * pi / 180).clamp(-10 * pi / 180, 10 * pi / 180);
      _tiltAngle = targetTilt;

      _currentPointer = event.position;

      // Check drop zone
      final dropZone = _getBackpackDropZone();
      final inDropZone = dropZone?.contains(event.position) ?? false;

      if (inDropZone != _isHoveringDropZone) {
        _isHoveringDropZone = inDropZone;
        if (inDropZone) {
          HapticService.selection();
        }
      }

      // Auto-scroll when dragging near grid edges (Section 11)
      _checkAutoScroll(event.position);

      if (mounted) setState(() {});
    }
  }

  /// Pure helper for auto-scroll step calculation (exposed for unit/widget tests).
  /// Returns negative delta when near top edge, positive when near bottom edge, 0 outside.
  static double computeAutoScrollDelta({
    required double pointerY,
    required double gridTop,
    required double gridBottom,
    double edgeThreshold = 60.0,
    double minStep = 2.0,
    double maxStep = 18.0,
  }) {
    if (gridBottom <= gridTop) return 0.0;
    if (pointerY >= gridTop && pointerY < gridTop + edgeThreshold) {
      final t = ((gridTop + edgeThreshold - pointerY) / edgeThreshold).clamp(0.0, 1.0);
      return -(minStep + (maxStep - minStep) * t);
    }
    if (pointerY <= gridBottom && pointerY > gridBottom - edgeThreshold) {
      final t = ((pointerY - (gridBottom - edgeThreshold)) / edgeThreshold).clamp(0.0, 1.0);
      return minStep + (maxStep - minStep) * t;
    }
    return 0.0;
  }

  void _checkAutoScroll(Offset globalPointer) {
    if (!_scrollController.hasClients) return;
    final RenderBox? gridBox = _gridAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null || !gridBox.hasSize) return;
    final gridPos = gridBox.localToGlobal(Offset.zero);
    final gridHeight = gridBox.size.height;

    final delta = computeAutoScrollDelta(
      pointerY: globalPointer.dy,
      gridTop: gridPos.dy,
      gridBottom: gridPos.dy + gridHeight,
    );
    if (delta == 0.0) return;

    final target = (_scrollController.offset + delta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    if (target != _scrollController.offset) {
      _scrollController.jumpTo(target);
    }
  }

  void _onPointerUp(PointerUpEvent event, PackItemModel item) {
    if (event.pointer != _activePointerId) return;
    final movedBeyondSlop = _pointerMovedBeyondTapSlop ||
        (_dragStartPointer != null &&
            (event.position - _dragStartPointer!).distance > 8.0);
    if (mounted) {
      if (_draggingItem != null) {
        _handleDragEnd(item);
      } else if (!_longPressFired && !movedBeyondSlop) {
        // It was a simple tap without moving > 8pt!
        _handleCardTap(item);
      }
    }
    _resetDragState();
  }

  void _onPointerCancel(PointerCancelEvent event, PackItemModel item) {
    if (event.pointer != _activePointerId) return;
    if (mounted && _draggingItem != null) {
      _handleFlyBack(_draggingItem!);
    }
    _resetDragState();
  }

  void _resetDragState() {
    _activePointerId = null;
    _longPressFired = false;
    _pointerMovedBeyondTapSlop = false;
    _dragStartPointer = null;
    _currentPointer = null;
    _cardSlotCenter = null;
    _cardSlotSize = null;
    _tiltAngle = 0.0;
    _isHoveringDropZone = false;
    _draggingItem = null;
    if (mounted) setState(() {});
  }

  void _handleDragEnd(PackItemModel item) {
    if (!mounted) return;
    final dropZone = _getBackpackDropZone();
    final droppedInBackpack = _currentPointer != null &&
        (dropZone?.contains(_currentPointer!) ?? false);

    if (droppedInBackpack) {
      _executeDropIntoBackpack(item, _currentPointer!);
    } else {
      _handleFlyBack(item);
    }
  }

  void _startFlight({
    required PackItemModel item,
    required Offset fromGlobal,
    required Offset Function() toGlobal,
    required Size size,
    required Duration duration,
    required Curve positionCurve,
    required double scaleBegin,
    required double scaleEnd,
    Curve scaleCurve = Curves.easeIn,
    double opacityBegin = 1.0,
    double opacityEnd = 1.0,
    Future<void> Function()? onCompleted,
  }) {
    if (!mounted) return;
    _flightController?.dispose();
    final controller = AnimationController(vsync: this, duration: duration);
    _flightController = controller;

    _flyingItem = item;
    _flightCardSize = size;
    _flightFromGlobal = fromGlobal;
    _flightToGlobal = toGlobal;
    _flightProgress = CurvedAnimation(parent: controller, curve: positionCurve);
    _flightScaleAnimation = Tween<double>(begin: scaleBegin, end: scaleEnd)
        .animate(CurvedAnimation(parent: controller, curve: scaleCurve));
    _flightOpacityAnimation = Tween<double>(begin: opacityBegin, end: opacityEnd)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));

    controller.forward().then((_) async {
      if (!mounted) return;
      setState(() => _flyingItem = null);
      await onCompleted?.call();
    });
    if (mounted) setState(() {});
  }

  Size _flightSizeFor(PackItemModel item) =>
      _getItemSize(item.listItemId) ?? _cardSlotSize ?? const Size(110, 86);

  /// Drop into backpack (Section 6.2)
  void _executeDropIntoBackpack(PackItemModel item, Offset currentPos) {
    final mouthPos = _getBackpackMouthGlobalPosition() ?? currentPos;
    final reducedMotion = ref.read(reducedMotionProvider);

    _startFlight(
      item: item,
      fromGlobal: currentPos,
      toGlobal: () => mouthPos,
      size: _flightSizeFor(item),
      duration: Duration(milliseconds: reducedMotion ? 150 : 220),
      positionCurve: Curves.easeIn,
      scaleBegin: 1.08,
      scaleEnd: 0.2,
      scaleCurve: Curves.easeIn,
      opacityBegin: 1.0,
      opacityEnd: 0.0,
      onCompleted: () => _commitPackItem(item),
    );
  }

  /// Drop outside drop zone -> Spring fly back (Section 6.1)
  void _handleFlyBack(PackItemModel item) {
    final from = _currentPointer ?? Offset.zero;
    final fallback = _cardSlotCenter ?? from;
    final reducedMotion = ref.read(reducedMotionProvider);

    _startFlight(
      item: item,
      fromGlobal: from,
      toGlobal: _slotCenterResolver(item.listItemId, fallback),
      size: _flightSizeFor(item),
      duration: Duration(milliseconds: reducedMotion ? 150 : 280),
      positionCurve: Curves.easeOutBack,
      scaleBegin: 1.08,
      scaleEnd: 1.0,
      scaleCurve: Curves.easeOut,
      opacityBegin: 1.0,
      opacityEnd: 1.0,
    );
  }

  // --- Click to Pack & Unpack (Section 6.3) ---

  void _handleCardTap(PackItemModel item) {
    if (!mounted || _flyingItem != null) return;

    if (item.isPacked) {
      // Click packed -> Unpack (pop out from backpack, fly back to slot)
      _executeUnpack(item);
    } else if (!item.isSkipped) {
      // Click unpacked -> Fly into backpack along arc (400ms)
      _executeClickPack(item);
    }
  }

  /// Click unpacked card flies into backpack (Section 6.3)
  void _executeClickPack(PackItemModel item) {
    final slotPos = _getItemGlobalCenter(item.listItemId);
    final mouthPos = _getBackpackMouthGlobalPosition();
    if (slotPos == null || mouthPos == null) {
      _commitPackItem(item);
      return;
    }

    final reducedMotion = ref.read(reducedMotionProvider);
    _startFlight(
      item: item,
      fromGlobal: slotPos,
      toGlobal: () => mouthPos,
      size: _flightSizeFor(item),
      duration: Duration(milliseconds: reducedMotion ? 150 : 400),
      positionCurve: Curves.easeInOut,
      scaleBegin: 1.0,
      scaleEnd: 0.2,
      scaleCurve: Curves.easeIn,
      opacityBegin: 1.0,
      opacityEnd: 0.0,
      onCompleted: () => _commitPackItem(item),
    );
  }

  /// Commit pack item to database & trigger backpack effects (Section 6.2)
  Future<void> _commitPackItem(PackItemModel item) async {
    if (_session == null) return;
    final sessionRepo = ref.read(packSessionRepositoryProvider);

    // 1. Medium haptic
    HapticService.mediumImpact();

    // 2. Random pop sound
    AudioService.playRandomPop();

    // 3. Squish bounce backpack
    _backpackKey.currentState?.triggerSquishBounce();

    // 4. Update database
    await sessionRepo.packItem(_session!.id, item.listItemId);

    // Check if all packed
    final items = await sessionRepo.getPackItems(_session!.id, widget.checklistId);

    final activeItems = items.where((i) => !i.isSkipped).toList();
    final allPacked = activeItems.isNotEmpty && activeItems.every((i) => i.isPacked);

    if (allPacked) {
      _triggerAllPackedCelebration();
    }
  }

  /// Unpack item (Section 6.3)
  Future<void> _executeUnpack(PackItemModel item) async {
    if (_session == null) return;
    final sessionRepo = ref.read(packSessionRepositoryProvider);

    // 1. Light haptic
    HapticService.lightImpact();

    // 2. Play unpack sound
    AudioService.playUnpack();

    final mouthPos = _getBackpackMouthGlobalPosition() ?? Offset.zero;
    final size = _flightSizeFor(item);

    // 3. Update database
    await sessionRepo.unpackItem(_session!.id, item.listItemId);
    if (!mounted) return;

    // 4. Flight animation: pops out from backpack mouth to slot
    final reducedMotion = ref.read(reducedMotionProvider);
    _startFlight(
      item: item,
      fromGlobal: mouthPos,
      toGlobal: _slotCenterResolver(item.listItemId, mouthPos),
      size: size,
      duration: Duration(milliseconds: reducedMotion ? 150 : 320),
      positionCurve: Curves.easeOutBack,
      scaleBegin: 0.4,
      scaleEnd: 1.0,
      scaleCurve: Curves.easeOut,
      opacityBegin: 0.2,
      opacityEnd: 1.0,
    );
  }

  /// Section 6.4: All packed celebration
  void _triggerAllPackedCelebration() {
    _backpackKey.currentState?.playAllPackedSequence(
      onZipperStart: () {
        AudioService.playZip();
        HapticService.success();
      },
      onCompleted: () async {
        if (_session != null) {
          await ref.read(packSessionRepositoryProvider).updateSessionStatus(
                _session!.id,
                'completed',
                completedAt: DateTime.now().toUtc(),
              );
          if (mounted) {
            context.pushReplacement(
              '/done/${_session!.id}?listId=${widget.checklistId}',
            );
          }
        }
      },
    );
  }

  /// Long press card -> modal menu (Section 6.3)
  void _handleCardLongPress(PackItemModel item) {
    // Drag has priority: once the card is being dragged (or pointer moved beyond
    // 8pt tap slop), a long press must not open the menu.
    if (_draggingItem != null || _flyingItem != null || _pointerMovedBeyondTapSlop) return;
    _longPressFired = true;
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
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  item.isSkipped ? Icons.replay : Icons.block,
                  color: AppColors.primary,
                ),
                title: Text(item.isSkipped ? '恢复带上' : '今天不带'),
                subtitle: Text(
                  item.isSkipped ? '恢复计入本次装包清单' : '本次出门跳过此物品，不计入总数',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  context.pop();
                  if (_session != null) {
                    await ref
                        .read(packSessionRepositoryProvider)
                        .toggleSkipped(_session!.id, item.listItemId);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑清单'),
                onTap: () {
                  context.pop();
                  _openEditor();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('从清单删除', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  context.pop();
                  _deleteItemFromChecklist(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteItemFromChecklist(PackItemModel item) async {
    final checklistRepo = ref.read(checklistRepositoryProvider);
    final items = await checklistRepo.getItemsForChecklist(widget.checklistId);
    final remaining = items.where((i) => i.id != item.listItemId).toList();

    await checklistRepo.updateChecklist(
      listId: widget.checklistId,
      name: _checklist!.name,
      emoji: _checklist!.emoji,
      mnemonic: _checklist!.mnemonic,
      reminderEnabled: _checklist!.reminderEnabled,
      reminderTime: _checklist!.reminderTime,
      items: remaining.map((i) => (name: i.name, emoji: i.emoji)).toList(),
    );
  }

  void _openEditor() {
    context.push('/editor/${widget.checklistId}').then((_) {
      _initSession();
    });
  }

  /// Section 6.5: Leave before finishing check
  Future<void> _handleBackPress(List<PackItemModel> items) async {
    final activeItems = items.where((i) => !i.isSkipped).toList();
    final unpackedItems = activeItems.where((i) => !i.isPacked).toList();
    final packedCount = activeItems.where((i) => i.isPacked).length;

    void exitScreen() {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    }

    // If 0 items packed or all items packed, exit directly
    if (packedCount == 0 || unpackedItems.isEmpty) {
      exitScreen();
      return;
    }

    // Unpacked items exist: show departure dialog
    final names = unpackedItems.map((i) => i.name).join('、');
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(
            '还有 ${unpackedItems.length} 件没装：$names',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text('确定就这样出门吗？'),
          actions: [
            TextButton(
              onPressed: () => dialogCtx.pop(),
              child: const Text('再看看', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                dialogCtx.pop();
                if (_session != null) {
                  await ref.read(packSessionRepositoryProvider).updateSessionStatus(
                        _session!.id,
                        'departed_incomplete',
                        departedAt: DateTime.now().toUtc(),
                      );
                }
                exitScreen();
              },
              child: const Text('就这样出门', style: TextStyle(color: AppColors.danger)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                dialogCtx.pop();
                exitScreen();
              },
              child: const Text('稍后再装'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _checklist == null || _session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final itemsAsync = ref.watch(
      sessionItemsStreamProvider((sessionId: _session!.id, listId: widget.checklistId)),
    );
    final reducedMotion = ref.watch(reducedMotionProvider);

    return itemsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (items) {
        final activeItems = items.where((i) => !i.isSkipped).toList();
        final allSkipped = items.isNotEmpty && activeItems.isEmpty;
        final totalCount = activeItems.length;
        final packedCount = activeItems.where((i) => i.isPacked).length;
        final remainingCount = totalCount - packedCount;
        final progress = totalCount == 0 ? 0.0 : packedCount / totalCount;
        final isAllPacked = totalCount > 0 && remainingCount == 0;

        // Unpacked high risk items for banner
        final unpackedHighRisk =
            activeItems.where((i) => i.isHighRisk && !i.isPacked).toList();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackPress(items);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availH = constraints.maxHeight;
                  final compactMode = availH < 420;

                  return Stack(
                    key: _overlayKey,
                    clipBehavior: Clip.none,
                children: [
                  Column(
                    children: [
                      // 1. Top Header (‹ 返回, 编辑, 标题, 副标题)
                      _buildHeader(remainingCount, isAllPacked, allSkipped, items, compactMode: compactMode),

                      // Section 11: All skipped banner and "直接出门" button
                      if (allSkipped)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '今天什么都不带吗？',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.done,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () async {
                                  AudioService.playDoor();
                                  if (_session != null) {
                                    await ref
                                        .read(packSessionRepositoryProvider)
                                        .updateSessionStatus(
                                          _session!.id,
                                          'departed',
                                          departedAt: DateTime.now().toUtc(),
                                        );
                                  }
                                  if (context.mounted) {
                                    context.go('/');
                                  }
                                },
                                child: const Text(
                                  '直接出门',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 2. Mnemonic Bar (if present and character count matches items count)
                      if (!compactMode && _checklist!.mnemonic != null && _checklist!.mnemonic!.isNotEmpty)
                        MnemonicBar(
                          mnemonic: _checklist!.mnemonic!,
                          items: items,
                          reducedMotion: reducedMotion,
                        ),

                      // High-Risk Banner (placed below Header / MnemonicBar, above Grid)
                      if (!compactMode && unpackedHighRisk.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                          child: _buildHighRiskBanner(unpackedHighRisk),
                        ),

                      // 3. Grid of Cards + High-Risk Banner or Empty State
                      Expanded(
                        child: items.isEmpty
                            ? _buildEmptyState()
                            : _buildItemsList(
                                items,
                                unpackedHighRisk,
                                compactMode: compactMode,
                                reducedMotion: reducedMotion,
                              ),
                      ),

                      // 4. Backpack & Progress Area (fixed at bottom, adaptive height)
                      _buildBackpackArea(progress, isAllPacked, packedCount, totalCount, reducedMotion, availH, items.length),
                    ],
                  ),

                  // Floating dragged card (Section 6.1)
                  if (_draggingItem != null && _currentPointer != null)
                    Builder(builder: (_) {
                      final size = _cardSlotSize ?? const Size(110, 86);
                      final c = _toOverlayLocal(_currentPointer!);
                      return Positioned(
                        left: c.dx - size.width / 2,
                        top: c.dy - size.height / 2,
                        width: size.width,
                        height: size.height,
                        child: IgnorePointer(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                              reducedMotion ? 1.0 : 1.08,
                              reducedMotion ? 1.0 : 1.08,
                              1.0,
                            )..rotateZ(reducedMotion ? 0.0 : _tiltAngle),
                            child: ItemCardWidget(
                              item: _draggingItem!,
                              isDragged: true,
                            ),
                          ),
                        ),
                      );
                    }),

                  // Flying card during animation (Click pack, Drop in, Fly back, Unpack)
                  if (_flyingItem != null &&
                      _flightProgress != null &&
                      _flightScaleAnimation != null &&
                      _flightOpacityAnimation != null)
                    AnimatedBuilder(
                      animation: _flightController!,
                      builder: (context, _) {
                        // Offset.lerp extrapolates for t > 1, so easeOutBack overshoot still works.
                        final g = Offset.lerp(_flightFromGlobal, _flightToGlobal(), _flightProgress!.value)!;
                        final c = _toOverlayLocal(g);
                        final size = _flightCardSize;

                        return Positioned(
                          left: c.dx - size.width / 2,
                          top: c.dy - size.height / 2,
                          width: size.width,
                          height: size.height,
                          child: IgnorePointer(
                            child: Transform.scale(
                              scale: _flightScaleAnimation!.value,
                              child: Opacity(
                                opacity: _flightOpacityAnimation!.value.clamp(0.0, 1.0),
                                child: ItemCardWidget(
                                  item: _flyingItem!,
                                  isDragged: true,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildHeader(
    int remainingCount,
    bool isAllPacked,
    bool allSkipped,
    List<PackItemModel> items, {
    bool compactMode = false,
  }) {
    final pillHeight = compactMode ? 28.0 : 36.0;
    const pillShadow = [
      BoxShadow(
        color: Color.fromRGBO(28, 25, 23, 0.05),
        blurRadius: 12,
        offset: Offset(0, 3),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: compactMode ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _handleBackPress(items),
                child: Container(
                  height: pillHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: pillShadow,
                  ),
                  child: const Text(
                    '‹ 返回',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openEditor,
                child: Container(
                  height: pillHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: pillShadow,
                  ),
                  child: const Text(
                    '编辑',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _checklist!.name,
            style: TextStyle(
              fontSize: compactMode ? 20 : 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          if (isAllPacked)
            const Text(
              '全部装好了',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.done,
              ),
            )
          else if (!allSkipped)
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                children: [
                  const TextSpan(text: '还差 '),
                  TextSpan(
                    text: '$remainingCount 件',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' · 把东西拖进包里'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHighRiskBanner(List<PackItemModel> unpackedHighRisk) {
    final canCollapse = unpackedHighRisk.length > 2;
    final isExpanded = canCollapse && _highRiskBannerExpanded;
    final String text = (!canCollapse || isExpanded)
        ? '🔴 ${unpackedHighRisk.map((e) => e.name).join('、')} 你以前忘过，先装它们'
        : '🔴 ${unpackedHighRisk.take(2).map((e) => e.name).join('、')} 等 ${unpackedHighRisk.length} 件你以前忘过，先装它们';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canCollapse
          ? () => setState(() => _highRiskBannerExpanded = !_highRiskBannerExpanded)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.22),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: isExpanded ? null : 1,
                overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (canCollapse) ...[
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 18,
                color: AppColors.danger,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(
    List<PackItemModel> items,
    List<PackItemModel> unpackedHighRisk, {
    bool compactMode = false,
    bool reducedMotion = false,
  }) {
    final hasMnemonic = _checklist?.mnemonic != null && _checklist!.mnemonic!.isNotEmpty;

    return SingleChildScrollView(
      key: _gridAreaKey,
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (compactMode && unpackedHighRisk.isNotEmpty) ...[
            _buildHighRiskBanner(unpackedHighRisk),
            const SizedBox(height: 8),
          ],
          if (compactMode && hasMnemonic)
            MnemonicBar(
              mnemonic: _checklist!.mnemonic!,
              items: items,
              reducedMotion: reducedMotion,
            ),
          // 3-columns Grid of item cards (Section 5.2)
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 10.0;
              final double cardWidth = (constraints.maxWidth - spacing * 2) / 3;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items.map((item) {
                  final isHiddenSlot = _draggingItem?.listItemId == item.listItemId ||
                      _flyingItem?.listItemId == item.listItemId;
                  final itemKey = _itemKeys.putIfAbsent(item.listItemId, () => GlobalKey());

                  return SizedBox(
                    key: itemKey,
                    width: cardWidth,
                    height: 86,
                    child: Listener(
                      onPointerDown: (e) => _onPointerDown(e, item),
                      onPointerMove: (e) => _onPointerMove(e, item),
                      onPointerUp: (e) => _onPointerUp(e, item),
                      onPointerCancel: (e) => _onPointerCancel(e, item),
                      child: GestureDetector(
                        onLongPress: () => _handleCardLongPress(item),
                        child: ItemCardWidget(
                          item: item,
                          isPlaceholder: isHiddenSlot,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '先往清单里加点东西',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: EmojiPresets.commonShortcuts.take(6).map((name) {
                return ActionChip(
                  label: Text('$name ${EmojiPresets.matchEmoji(name)}'),
                  onPressed: () async {
                    final checklistRepo = ref.read(checklistRepositoryProvider);
                    await checklistRepo.createChecklist(
                      name: _checklist!.name,
                      emoji: _checklist!.emoji,
                      items: [(name: name, emoji: EmojiPresets.matchEmoji(name))],
                    );
                    _initSession();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackpackArea(
    double progress,
    bool isAllPacked,
    int packedCount,
    int totalCount,
    bool reducedMotion,
    double availH,
    int itemCount,
  ) {
    final double backpackH;
    final EdgeInsets padding;
    final double gap;
    final double textSize;

    if (availH < 420) {
      backpackH = (availH * 0.22).clamp(64.0, 96.0);
      padding = const EdgeInsets.only(top: 2, bottom: 4);
      gap = 2.0;
      textSize = 12.0;
    } else if (itemCount > 6) {
      backpackH = (availH * 0.22).clamp(140.0, 165.0);
      padding = const EdgeInsets.only(top: 4, bottom: 8);
      gap = 4.0;
      textSize = 15.0;
    } else {
      backpackH = (availH * 0.30).clamp(140.0, 220.0);
      padding = const EdgeInsets.only(top: 8, bottom: 12);
      gap = 8.0;
      textSize = 15.0;
    }
    final double backpackW = backpackH * 200.0 / 220.0;

    return Container(
      key: _backpackAreaKey,
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Backpack Widget
          BackpackWidget(
            key: _backpackKey,
            progress: progress,
            isOpen: _isHoveringDropZone,
            isDone: isAllPacked,
            reducedMotion: reducedMotion,
            width: backpackW,
            height: backpackH,
          ),
          SizedBox(height: gap),
          // Progress text / Drop zone hint (Section 6.1)
          Text(
            _isHoveringDropZone
                ? '松手放进包里'
                : (isAllPacked ? '全部装好了 🎉' : '$packedCount / $totalCount'),
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: _isHoveringDropZone
                  ? AppColors.primary
                  : (isAllPacked ? AppColors.done : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
