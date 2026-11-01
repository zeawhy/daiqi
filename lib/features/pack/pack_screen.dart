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

  // Pointer drag state
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridAreaKey = GlobalKey();
  PackItemModel? _draggingItem;
  int? _activePointerId;
  Offset? _dragStartPointer;
  Offset? _currentPointer;
  Offset? _cardSlotOffset;
  Size? _cardSlotSize;
  double _tiltAngle = 0.0;
  bool _isHoveringDropZone = false;
  final Map<String, GlobalKey> _itemKeys = {};

  // Flight animations (for click pack, click unpack, and drop fly-in/fly-back)
  AnimationController? _flightController;
  Animation<Offset>? _flightPositionAnimation;
  Animation<double>? _flightScaleAnimation;
  Animation<double>? _flightOpacityAnimation;
  PackItemModel? _flyingItem;

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

  /// Slot position of an item in global coordinates
  Offset? _getItemGlobalPosition(String listItemId) {
    final key = _itemKeys[listItemId];
    final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.localToGlobal(Offset.zero);
  }

  Size? _getItemSize(String listItemId) {
    final key = _itemKeys[listItemId];
    final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox.size;
  }

  // --- Pointer Drag Implementation (> 8pt start drag, tilt ±10°) ---

  void _onPointerDown(PointerDownEvent event, PackItemModel item) {
    if (item.isSkipped || _flyingItem != null) return;
    if (_activePointerId != null) return; // Ignore second finger (Section 11)
    _activePointerId = event.pointer;
    _dragStartPointer = event.position;
    _currentPointer = event.position;
    _cardSlotOffset = _getItemGlobalPosition(item.listItemId);
    _cardSlotSize = _getItemSize(item.listItemId);
  }

  void _onPointerMove(PointerMoveEvent event, PackItemModel item) {
    if (event.pointer != _activePointerId) return;
    if (_dragStartPointer == null) return;
    if (item.isPacked) return; // Packed items cannot be dragged

    final distance = (event.position - _dragStartPointer!).distance;

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

      setState(() {});
    }
  }

  void _checkAutoScroll(Offset globalPointer) {
    if (!_scrollController.hasClients) return;
    final RenderBox? gridBox = _gridAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;
    final gridPos = gridBox.localToGlobal(Offset.zero);
    final gridHeight = gridBox.size.height;

    const edgeThreshold = 60.0;
    final pointerY = globalPointer.dy;

    if (pointerY >= gridPos.dy && pointerY <= gridPos.dy + edgeThreshold) {
      // Near top edge: scroll up
      final target = (_scrollController.offset - 15.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      if (target != _scrollController.offset) {
        _scrollController.jumpTo(target);
      }
    } else if (pointerY <= gridPos.dy + gridHeight && pointerY >= gridPos.dy + gridHeight - edgeThreshold) {
      // Near bottom edge: scroll down
      final target = (_scrollController.offset + 15.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      if (target != _scrollController.offset) {
        _scrollController.jumpTo(target);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event, PackItemModel item) {
    if (event.pointer != _activePointerId) return;
    if (_draggingItem != null) {
      _handleDragEnd(item);
    } else {
      // It was a simple tap without moving > 8pt!
      _handleCardTap(item);
    }
    _resetDragState();
  }

  void _onPointerCancel(PointerCancelEvent event, PackItemModel item) {
    if (event.pointer != _activePointerId) return;
    if (_draggingItem != null) {
      _handleFlyBack(_draggingItem!);
    }
    _resetDragState();
  }

  void _resetDragState() {
    _activePointerId = null;
    _dragStartPointer = null;
    _currentPointer = null;
    _cardSlotOffset = null;
    _cardSlotSize = null;
    _tiltAngle = 0.0;
    _isHoveringDropZone = false;
    _draggingItem = null;
    setState(() {});
  }

  void _handleDragEnd(PackItemModel item) {
    final dropZone = _getBackpackDropZone();
    final droppedInBackpack = _currentPointer != null &&
        (dropZone?.contains(_currentPointer!) ?? false);

    if (droppedInBackpack) {
      _executeDropIntoBackpack(item, _currentPointer!);
    } else {
      _handleFlyBack(item);
    }
  }

  /// Drop into backpack (Section 6.2)
  void _executeDropIntoBackpack(PackItemModel item, Offset currentPos) {
    final mouthPos = _getBackpackMouthGlobalPosition() ?? currentPos;
    final reducedMotion = ref.read(reducedMotionProvider);

    _flightController?.dispose();
    _flightController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reducedMotion ? 150 : 220),
    );

    _flyingItem = item;
    _flightPositionAnimation = Tween<Offset>(
      begin: currentPos,
      end: mouthPos,
    ).animate(CurvedAnimation(parent: _flightController!, curve: Curves.easeIn));

    _flightScaleAnimation = Tween<double>(begin: 1.08, end: 0.2).animate(
      CurvedAnimation(parent: _flightController!, curve: Curves.easeIn),
    );

    _flightOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _flightController!, curve: Curves.easeIn),
    );

    _flightController!.forward().then((_) async {
      _flyingItem = null;
      setState(() {});
      await _commitPackItem(item);
    });
    setState(() {});
  }

  /// Drop outside drop zone -> Spring fly back (Section 6.1)
  void _handleFlyBack(PackItemModel item) {
    final startPos = _currentPointer ?? Offset.zero;
    final targetPos = _cardSlotOffset ?? startPos;
    final reducedMotion = ref.read(reducedMotionProvider);

    _flightController?.dispose();
    _flightController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reducedMotion ? 150 : 280),
    );

    _flyingItem = item;
    _flightPositionAnimation = Tween<Offset>(
      begin: startPos,
      end: targetPos,
    ).animate(CurvedAnimation(parent: _flightController!, curve: Curves.easeOutBack));

    _flightScaleAnimation = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _flightController!, curve: Curves.easeOut),
    );

    _flightOpacityAnimation = const AlwaysStoppedAnimation(1.0);

    _flightController!.forward().then((_) {
      _flyingItem = null;
      setState(() {});
    });
    setState(() {});
  }

  // --- Click to Pack & Unpack (Section 6.3) ---

  void _handleCardTap(PackItemModel item) {
    if (_flyingItem != null) return;

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
    final slotPos = _getItemGlobalPosition(item.listItemId);
    final mouthPos = _getBackpackMouthGlobalPosition();
    if (slotPos == null || mouthPos == null) {
      _commitPackItem(item);
      return;
    }

    final reducedMotion = ref.read(reducedMotionProvider);
    _flightController?.dispose();
    _flightController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reducedMotion ? 150 : 400),
    );

    _flyingItem = item;
    _flightPositionAnimation = Tween<Offset>(
      begin: slotPos,
      end: mouthPos,
    ).animate(CurvedAnimation(parent: _flightController!, curve: Curves.easeInOut));

    _flightScaleAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _flightController!, curve: Curves.easeIn),
    );

    _flightOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _flightController!, curve: Curves.easeIn),
    );

    _flightController!.forward().then((_) async {
      _flyingItem = null;
      setState(() {});
      await _commitPackItem(item);
    });
    setState(() {});
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

    final slotPos = _getItemGlobalPosition(item.listItemId);
    final mouthPos = _getBackpackMouthGlobalPosition();

    // 1. Light haptic
    HapticService.lightImpact();

    // 2. Play unpack sound
    AudioService.playUnpack();

    // 3. Update database
    await sessionRepo.unpackItem(_session!.id, item.listItemId);

    // 4. Flight animation: pops out from backpack mouth to slot
    if (slotPos != null && mouthPos != null) {
      final reducedMotion = ref.read(reducedMotionProvider);
      _flightController?.dispose();
      _flightController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: reducedMotion ? 150 : 320),
      );

      _flyingItem = item;
      _flightPositionAnimation = Tween<Offset>(
        begin: mouthPos,
        end: slotPos,
      ).animate(CurvedAnimation(parent: _flightController!, curve: Curves.easeOutBack));

      _flightScaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _flightController!, curve: Curves.easeOut),
      );

      _flightOpacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _flightController!, curve: Curves.easeIn),
      );

      _flightController!.forward().then((_) {
        _flyingItem = null;
        setState(() {});
      });
      setState(() {});
    }
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
              child: Stack(
                children: [
                  Column(
                    children: [
                      // 1. Top Header (‹ 返回, 编辑, 标题, 副标题)
                      _buildHeader(remainingCount, isAllPacked, allSkipped, items),

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
                      if (_checklist!.mnemonic != null && _checklist!.mnemonic!.isNotEmpty)
                        MnemonicBar(
                          mnemonic: _checklist!.mnemonic!,
                          items: items,
                          reducedMotion: reducedMotion,
                        ),

                      // 3. Grid of Cards + High-Risk Banner or Empty State
                      Expanded(
                        child: items.isEmpty
                            ? _buildEmptyState()
                            : _buildItemsList(items, unpackedHighRisk),
                      ),

                      // 4. Backpack & Progress Area (fixed at bottom, height ~230pt)
                      _buildBackpackArea(progress, isAllPacked, packedCount, totalCount, reducedMotion),
                    ],
                  ),

                  // Floating dragged card (Section 6.1)
                  if (_draggingItem != null && _currentPointer != null)
                    Positioned(
                      left: _currentPointer!.dx - (_cardSlotSize?.width ?? 100) / 2,
                      top: _currentPointer!.dy - (_cardSlotSize?.height ?? 86) / 2,
                      width: _cardSlotSize?.width ?? 110,
                      height: _cardSlotSize?.height ?? 86,
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
                    ),

                  // Flying card during animation (Click pack, Drop in, Unpack)
                  if (_flyingItem != null &&
                      _flightPositionAnimation != null &&
                      _flightScaleAnimation != null &&
                      _flightOpacityAnimation != null)
                    AnimatedBuilder(
                      animation: _flightController!,
                      builder: (context, child) {
                        final pos = _flightPositionAnimation!.value;
                        final scale = _flightScaleAnimation!.value;
                        final opacity = _flightOpacityAnimation!.value;

                        final cardWidth = _cardSlotSize?.width ?? 110;
                        final cardHeight = _cardSlotSize?.height ?? 86;

                        return Positioned(
                          left: pos.dx - cardWidth / 2,
                          top: pos.dy - cardHeight / 2,
                          width: cardWidth,
                          height: cardHeight,
                          child: IgnorePointer(
                            child: Transform.scale(
                              scale: scale,
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
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
    List<PackItemModel> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _handleBackPress(items),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '‹ 返回',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openEditor,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '编辑',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primary,
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
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
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
                      fontWeight: FontWeight.bold,
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

  Widget _buildItemsList(List<PackItemModel> items, List<PackItemModel> unpackedHighRisk) {
    return SingleChildScrollView(
      key: _gridAreaKey,
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 3-columns Grid of item cards (Section 5.2)
          LayoutBuilder(
            builder: (context, constraints) {
              const double spacing = 10.0;
              final double cardWidth = (constraints.maxWidth - spacing * 2) / 3;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items.map((item) {
                  final isCurrentlyDragged = _draggingItem?.listItemId == item.listItemId;
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
                          isPlaceholder: isCurrentlyDragged,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // High-Risk Banner (Section 5.2: 🔴 身份证、充电器 你以前忘过，先装它们)
          if (unpackedHighRisk.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '🔴 ${unpackedHighRisk.map((e) => e.name).join('、')} 你以前忘过，先装它们',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
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
    );
  }

  Widget _buildBackpackArea(
    double progress,
    bool isAllPacked,
    int packedCount,
    int totalCount,
    bool reducedMotion,
  ) {
    return Container(
      key: _backpackAreaKey,
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Backpack Widget (approx 230pt height)
          BackpackWidget(
            key: _backpackKey,
            progress: progress,
            isOpen: _isHoveringDropZone,
            isDone: isAllPacked,
            reducedMotion: reducedMotion,
            width: 200,
            height: 220,
          ),
          const SizedBox(height: 8),
          // Progress text / Drop zone hint (Section 6.1)
          Text(
            _isHoveringDropZone
                ? '松手放进包里'
                : (isAllPacked ? '全部装好了 🎉' : '$packedCount / $totalCount'),
            style: TextStyle(
              fontSize: 15,
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
