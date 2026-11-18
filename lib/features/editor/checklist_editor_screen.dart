import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/constants/emoji_presets.dart';
import '../../shared/services/haptic_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/widgets/brand_backpack_icon.dart';

class ChecklistEditorScreen extends ConsumerStatefulWidget {
  static const int maxMnemonicLength = 8;

  final String? checklistId; // null if creating new checklist

  const ChecklistEditorScreen({super.key, this.checklistId});

  @override
  ConsumerState<ChecklistEditorScreen> createState() => _ChecklistEditorScreenState();
}

class _ChecklistEditorScreenState extends ConsumerState<ChecklistEditorScreen> {
  final _nameController = TextEditingController();
  final _itemInputController = TextEditingController();
  final _mnemonicController = TextEditingController();

  String _selectedEmoji = '🎒';
  bool _mnemonicEnabled = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 30);
  final List<int> _reminderWeekdays = [1, 2, 3, 4, 5]; // Mon to Fri

  List<({String name, String emoji})> _items = [];
  bool _isAutoMnemonic = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String _initialSnapshot = '';

  final List<String> _emojiPickerOptions = [
    '🎒', '💼', '👜', '🧳', '🤚', '🏃', '✈️', '🏕️', '💻', '🏋️', '🚴', '🚗',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    _itemInputController.addListener(_onTextChanged);
    _mnemonicController.addListener(_onTextChanged);
    _loadData();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  String _computeSnapshot() {
    final sortedDays = [..._reminderWeekdays]..sort();
    return jsonEncode({
      'name': _nameController.text.trim(),
      'pendingItem': _itemInputController.text.trim(),
      'emoji': _selectedEmoji,
      'mnemonicEnabled': _mnemonicEnabled,
      'mnemonic': _mnemonicEnabled ? _mnemonicController.text.trim() : '',
      'reminderEnabled': _reminderEnabled,
      'reminderTime': '${_reminderTime.hour}:${_reminderTime.minute}',
      'weekdays': sortedDays,
      'items': _items.map((e) => '${e.name}:${e.emoji}').toList(),
    });
  }

  bool get _hasUnsavedChanges =>
      !_isLoading && !_isSaving && _computeSnapshot() != _initialSnapshot;

  Future<void> _loadData() async {
    if (widget.checklistId != null) {
      final checklistRepo = ref.read(checklistRepositoryProvider);
      final checklist = await checklistRepo.getChecklist(widget.checklistId!);
      if (checklist != null) {
        final items = await checklistRepo.getItemsForChecklist(widget.checklistId!);

        _nameController.text = checklist.name;
        _selectedEmoji = checklist.emoji;
        _mnemonicEnabled = checklist.mnemonic != null && checklist.mnemonic!.isNotEmpty;
        if (_mnemonicEnabled) {
          _mnemonicController.text = checklist.mnemonic!;
          _isAutoMnemonic = false;
        }
        _reminderEnabled = checklist.reminderEnabled;
        if (checklist.reminderTime != null) {
          final parts = checklist.reminderTime!.split(':');
          if (parts.length == 2) {
            _reminderTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts[1]) ?? 30,
            );
          }
        }
        if (checklist.reminderWeekdays != null && checklist.reminderWeekdays!.isNotEmpty) {
          try {
            final decoded = jsonDecode(checklist.reminderWeekdays!) as List;
            final days = decoded.map((e) => e as int).where((d) => d >= 1 && d <= 7).toList()
              ..sort();
            if (days.isNotEmpty) {
              _reminderWeekdays
                ..clear()
                ..addAll(days);
            }
          } catch (_) {}
        }
        _items = items.map((i) => (name: i.name, emoji: i.emoji)).toList();
      }
    }
    _initialSnapshot = _computeSnapshot();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _itemInputController.removeListener(_onTextChanged);
    _mnemonicController.removeListener(_onTextChanged);
    _nameController.dispose();
    _itemInputController.dispose();
    _mnemonicController.dispose();
    super.dispose();
  }

  void _updateMnemonicIfAuto() {
    if (_mnemonicEnabled && _isAutoMnemonic) {
      final chars = _items
          .map((i) => i.name.trim().isNotEmpty ? i.name.trim().characters.first : '')
          .where((c) => c.isNotEmpty)
          .take(ChecklistEditorScreen.maxMnemonicLength)
          .join();
      _mnemonicController.text = chars;
    }
  }

  void _addItem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // Duplicate check
    final exists = _items.any((i) => i.name.trim() == trimmed);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('清单里已经有 $trimmed 了'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final matchedEmoji = EmojiPresets.matchEmoji(trimmed);
    HapticService.lightImpact();
    setState(() {
      _items.add((name: trimmed, emoji: matchedEmoji));
      _updateMnemonicIfAuto();
    });
    _itemInputController.clear();
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    final removed = _items[index];
    HapticService.lightImpact();
    setState(() {
      _items.removeAt(index);
      _updateMnemonicIfAuto();
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('已移除「${removed.name}」'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '撤销',
          textColor: AppColors.pastelAmber,
          onPressed: () {
            if (!mounted) return;
            if (_items.any((i) => i.name.trim() == removed.name.trim())) return;
            setState(() {
              final insertAt = index.clamp(0, _items.length);
              _items.insert(insertAt, removed);
              _updateMnemonicIfAuto();
            });
          },
        ),
      ),
    );
  }

  void _reorderItems(int oldIndex, int newIndex) {
    HapticService.selection();
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      _updateMnemonicIfAuto();
    });
  }

  Future<void> _handleBackAttempt() async {
    if (!_hasUnsavedChanges) {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            '放弃未保存的修改？',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          ),
          content: const Text(
            '当前清单的改动还未保存，返回后将不会保留。',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('继续编辑', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('放弃'),
            ),
          ],
        );
      },
    );

    if (discard == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    }
  }

  Future<void> _saveChecklist() async {
    if (_isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入清单名称')),
      );
      return;
    }

    // Auto-commit pending typed item if user forgot to press Enter / '+'
    final pendingItem = _itemInputController.text.trim();
    if (pendingItem.isNotEmpty) {
      final alreadyExists = _items.any((i) => i.name.trim() == pendingItem);
      if (!alreadyExists) {
        _items.add((name: pendingItem, emoji: EmojiPresets.matchEmoji(pendingItem)));
        _updateMnemonicIfAuto();
      }
      _itemInputController.clear();
    }

    if (_reminderEnabled && _reminderWeekdays.isEmpty) {
      _reminderWeekdays.addAll([1, 2, 3, 4, 5]);
    }

    setState(() => _isSaving = true);

    final mnemonic = _mnemonicEnabled ? _mnemonicController.text.trim() : null;
    final timeStr =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    final checklistRepo = ref.read(checklistRepositoryProvider);
    String targetId;

    if (widget.checklistId == null) {
      targetId = await checklistRepo.createChecklist(
        name: name,
        emoji: _selectedEmoji,
        mnemonic: mnemonic,
        reminderEnabled: _reminderEnabled,
        reminderTime: timeStr,
        reminderWeekdays: _reminderWeekdays,
        items: _items,
      );
    } else {
      targetId = widget.checklistId!;
      await checklistRepo.updateChecklist(
        listId: targetId,
        name: name,
        emoji: _selectedEmoji,
        mnemonic: mnemonic,
        reminderEnabled: _reminderEnabled,
        reminderTime: timeStr,
        reminderWeekdays: _reminderWeekdays,
        items: _items,
      );
    }

    if (_reminderEnabled) {
      await NotificationService.scheduleChecklistReminder(
        listId: targetId,
        listName: name,
        itemCount: _items.length,
        reminderTime: timeStr,
        reminderWeekdays: _reminderWeekdays,
      );
    } else {
      await NotificationService.cancelChecklistReminders(targetId);
    }

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final existingNames = _items.map((i) => i.name).toSet();
    final availableShortcuts = EmojiPresets.commonShortcuts
        .where((name) => !existingNames.contains(name))
        .toList();

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAttempt();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.checklistId == null ? '新建清单' : '编辑清单'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: _isSaving ? null : _saveChecklist,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Name & Icon Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: '更换清单图标',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showEmojiPicker,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border, width: 0.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(28, 25, 23, 0.05),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: ChecklistAvatar(
                            emoji: _selectedEmoji,
                            size: 26,
                            strokeWidth: 2.2,
                            strokeColor: AppColors.primary,
                            hardwareColor: AppColors.backpackHardware,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.card, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    maxLength: 12,
                    decoration: InputDecoration(
                      hintText: '清单名称（最多12字）',
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. Add Item Input
            const Text(
              '添加物品',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemInputController,
                    decoration: InputDecoration(
                      hintText: '输入物品名称，按回车添加',
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppColors.border, width: 0.8),
                      ),
                    ),
                    onSubmitted: (val) => _addItem(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: '添加物品',
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _addItem(_itemInputController.text),
                ),
              ],
            ),

            // 3. Common items shortcut tags
            if (availableShortcuts.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                '常用物品快捷标签',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableShortcuts.map((name) {
                  final emoji = EmojiPresets.matchEmoji(name);
                  return ActionChip(
                    avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
                    label: Text(name),
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.border, width: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _addItem(name),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // 4. Items List with drag reorder and delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '物品列表 (${_items.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    height: 1.35,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  '长按拖动排序 · 左滑移除',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(28, 25, 23, 0.04),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('清单还没有物品，在上方添加', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                // ignore: deprecated_member_use
                onReorder: _reorderItems,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Dismissible(
                    key: ValueKey('${item.name}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) => _removeItem(index),
                    child: Card(
                      key: ValueKey('card_${item.name}_$index'),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.border, width: 0.5),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.pastelPills[index % AppColors.pastelPills.length],
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: ChecklistAvatar(
                            emoji: item.emoji,
                            size: 18,
                            strokeWidth: 1.6,
                            strokeColor: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: '移除 ${item.name}',
                              icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                              onPressed: () => _removeItem(index),
                            ),
                            const Icon(Icons.drag_handle_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // 5. Mnemonic (口诀) Switch & Field
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '口诀条',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            height: 1.35,
                          ),
                        ),
                        Switch(
                          value: _mnemonicEnabled,
                          onChanged: (val) {
                            HapticService.selection();
                            setState(() {
                              _mnemonicEnabled = val;
                              if (val) _updateMnemonicIfAuto();
                            });
                          },
                        ),
                      ],
                    ),
                    if (_mnemonicEnabled) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mnemonicController,
                        maxLength: ChecklistEditorScreen.maxMnemonicLength,
                        onChanged: (val) {
                          _isAutoMnemonic = false;
                        },
                        decoration: InputDecoration(
                          hintText: '如：身手钥钱',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          helperText: '最多 8 个字，按顺序对应前 N 件物品',
                          helperMaxLines: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 6. Reminder Switch & Settings
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '定时提醒',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            height: 1.35,
                          ),
                        ),
                        Switch(
                          value: _reminderEnabled,
                          onChanged: (val) {
                            HapticService.selection();
                            setState(() {
                              _reminderEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_reminderEnabled) ...[
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('提醒时间'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _reminderTime.format(context),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _reminderTime = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text('重复日', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildWeekdayChip(1, '一'),
                          _buildWeekdayChip(2, '二'),
                          _buildWeekdayChip(3, '三'),
                          _buildWeekdayChip(4, '四'),
                          _buildWeekdayChip(5, '五'),
                          _buildWeekdayChip(6, '六'),
                          _buildWeekdayChip(7, '日'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildWeekdayChip(int day, String label) {
    final isSelected = _reminderWeekdays.contains(day);
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '周$label',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.selection();
            if (isSelected && _reminderWeekdays.length <= 1) {
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('定时提醒至少保留一天'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            setState(() {
              if (isSelected) {
                _reminderWeekdays.remove(day);
              } else {
                _reminderWeekdays.add(day);
                _reminderWeekdays.sort();
              }
            });
          },
          child: SizedBox(
            height: 48,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    HapticService.selection();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  '选择清单图标',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _emojiPickerOptions.map((e) {
                    return GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        setState(() {
                          _selectedEmoji = e;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedEmoji == e ? AppColors.primaryLight : AppColors.secondaryBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedEmoji == e ? AppColors.primary : AppColors.border,
                            width: _selectedEmoji == e ? 2 : 1,
                          ),
                        ),
                        child: ChecklistAvatar(
                          emoji: e,
                          size: 24,
                          strokeWidth: 2.0,
                          strokeColor: AppColors.primary,
                          hardwareColor: AppColors.backpackHardware,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
