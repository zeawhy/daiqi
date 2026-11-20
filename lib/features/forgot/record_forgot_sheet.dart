import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/database.dart';
import '../../shared/constants/emoji_presets.dart';
import '../../shared/services/haptic_service.dart';
import '../../shared/widgets/brand_backpack_icon.dart';

class RecordForgotSheet extends ConsumerStatefulWidget {
  final String? sessionId;
  final String? listId;
  final VoidCallback? onRecorded;

  const RecordForgotSheet({
    super.key,
    this.sessionId,
    this.listId,
    this.onRecorded,
  });

  @override
  ConsumerState<RecordForgotSheet> createState() => _RecordForgotSheetState();
}

class _RecordForgotSheetState extends ConsumerState<RecordForgotSheet> {
  String? _sessionId;
  String? _listId;
  String? _listName;
  DateTime? _departedTime;

  List<ListItem> _checklistItems = [];
  final Set<String> _selectedItems = {};
  final List<String> _customItems = [];
  final TextEditingController _customController = TextEditingController();

  bool _addToChecklist = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    _listId = widget.listId;
    _customController.addListener(_onCustomTextChanged);
    _initData();
  }

  void _onCustomTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _customController.removeListener(_onCustomTextChanged);
    _customController.dispose();
    super.dispose();
  }

  bool get _hasPendingCustomText => _customController.text.trim().isNotEmpty;

  bool get _hasOutsideItems {
    if (_customItems.isNotEmpty) return true;
    final pending = _customController.text.trim();
    if (pending.isEmpty) return false;
    return !_checklistItems.any((i) => i.name.trim() == pending);
  }

  bool get _canSubmit =>
      !_isSaving && (_selectedItems.isNotEmpty || _hasPendingCustomText);

  Future<void> _initData() async {
    final checklistRepo = ref.read(checklistRepositoryProvider);
    final sessionRepo = ref.read(packSessionRepositoryProvider);

    // If session/list was not provided, look for recent departed session within 24h
    if (_sessionId == null || _listId == null) {
      final recent = await checklistRepo.getRecentDepartedSession();
      if (recent != null) {
        _sessionId = recent.session.id;
        _listId = recent.list.id;
        _listName = recent.list.name;
        _departedTime = recent.session.departedAt ?? recent.session.startedAt;
      }
    } else {
      final checklist = await checklistRepo.getChecklist(_listId!);
      final session = await sessionRepo.getSessionById(_sessionId!);
      _listName = checklist?.name;
      _departedTime = session?.departedAt ?? session?.startedAt;
    }

    if (_listId != null) {
      if (_listName == null) {
        final checklist = await checklistRepo.getChecklist(_listId!);
        _listName = checklist?.name;
      }
      _checklistItems = await checklistRepo.getItemsForChecklist(_listId!);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildSubtitle() {
    if (_listName != null && _departedTime != null) {
      final localTime = _departedTime!.toLocal();
      final now = DateTime.now();
      final isToday = localTime.year == now.year &&
          localTime.month == now.month &&
          localTime.day == now.day;
      final timeStr = DateFormat('HH:mm').format(localTime);
      final dateStr = isToday ? '今天' : DateFormat('M月d日').format(localTime);
      return '$_listName · $dateStr $timeStr 出门';
    }
    return '不关联某次出门';
  }

  void _addCustomItem() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    HapticService.lightImpact();
    if (_checklistItems.any((i) => i.name == text) || _customItems.contains(text)) {
      _selectedItems.add(text);
      _customController.clear();
      setState(() {});
      return;
    }
    setState(() {
      _customItems.add(text);
      _selectedItems.add(text);
      _customController.clear();
    });
  }

  Widget _buildChipLabel(String emoji, String name, bool isSelected) {
    if (emoji == '🎒') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChecklistAvatar(
            emoji: emoji,
            size: 16,
            strokeWidth: 1.5,
            strokeColor: isSelected ? Colors.white : AppColors.primary,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(
      '$emoji $name',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;

    // Auto-commit pending typed outside item if user didn't tap '+'
    final pending = _customController.text.trim();
    if (pending.isNotEmpty) {
      if (!_checklistItems.any((i) => i.name.trim() == pending) &&
          !_customItems.contains(pending)) {
        _customItems.add(pending);
      }
      _selectedItems.add(pending);
      _customController.clear();
    }

    if (_selectedItems.isEmpty) return;
    HapticService.mediumImpact();
    setState(() => _isSaving = true);

    final checklistRepo = ref.read(checklistRepositoryProvider);
    final recorded = await checklistRepo.recordForgotItems(
      sessionId: _sessionId,
      listId: _listId,
      itemNames: _selectedItems.toList(),
      addOutsideToChecklist: _addToChecklist,
    );

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      widget.onRecorded?.call();

      final summary = recorded.length <= 4
          ? recorded.join('、')
          : '${recorded.take(4).join('、')} 等';
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('已记下，下次 $summary 会排在最前面'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 22,
          right: 22,
          top: 12,
        ),
        child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '这次忘了什么？',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          height: 1.28,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  // Subtitle
                  Text(
                    _buildSubtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item Chips or empty prompt
                  if (_checklistItems.isNotEmpty || _customItems.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._checklistItems.map((item) {
                          final isSelected = _selectedItems.contains(item.name);
                          return FilterChip(
                            label: _buildChipLabel(item.emoji, item.name, isSelected),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.background,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.borderStrong,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (val) {
                              HapticService.selection();
                              setState(() {
                                if (val) {
                                  _selectedItems.add(item.name);
                                } else {
                                  _selectedItems.remove(item.name);
                                }
                              });
                            },
                          );
                        }),
                        ..._customItems.map((name) {
                          final isSelected = _selectedItems.contains(name);
                          final matchedEmoji = EmojiPresets.matchEmoji(name);
                          return FilterChip(
                            label: _buildChipLabel(matchedEmoji, name, isSelected),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.background,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.borderStrong,
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (val) {
                              HapticService.selection();
                              setState(() {
                                if (val) {
                                  _selectedItems.add(name);
                                } else {
                                  _selectedItems.remove(name);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    )
                  else
                    const Text(
                      '输入这次忘带的物品，下次会自动置顶提醒',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // "+ 清单外的" item input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: '＋ 清单外的物品',
                            hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: AppColors.borderStrong, width: 0.9),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(color: AppColors.borderStrong, width: 0.9),
                            ),
                          ),
                          onSubmitted: (_) => _addCustomItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: '添加物品',
                        style: IconButton.styleFrom(
                          backgroundColor: _hasPendingCustomText
                              ? AppColors.primary
                              : AppColors.primaryLight,
                          foregroundColor: _hasPendingCustomText
                              ? Colors.white
                              : AppColors.textSecondary,
                          minimumSize: const Size(48, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _addCustomItem,
                      ),
                    ],
                  ),

                  // Option to add outside items to checklist
                  if (_listId != null && _hasOutsideItems)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          '将清单外的物品加入「${_listName ?? '当前清单'}」',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                        activeColor: AppColors.primary,
                        value: _addToChecklist,
                        onChanged: (val) {
                          HapticService.selection();
                          setState(() {
                            _addToChecklist = val ?? false;
                          });
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Main Button: "记下来，下次提醒我"
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.disabledBg,
                        disabledForegroundColor: AppColors.disabledFg,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _canSubmit ? _save : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '记下来，下次提醒我',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
