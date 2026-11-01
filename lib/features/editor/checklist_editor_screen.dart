import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/constants/emoji_presets.dart';
import '../../shared/services/notification_service.dart';

class ChecklistEditorScreen extends ConsumerStatefulWidget {
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

  final List<String> _emojiPickerOptions = [
    '🎒', '💼', '👜', '🧳', '🤚', '🏃', '✈️', '🏕️', '💻', '🏋️', '🚴', '🚗',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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
        _items = items.map((i) => (name: i.name, emoji: i.emoji)).toList();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _itemInputController.dispose();
    _mnemonicController.dispose();
    super.dispose();
  }

  void _updateMnemonicIfAuto() {
    if (_mnemonicEnabled && _isAutoMnemonic) {
      final chars = _items.map((i) => i.name.trim().isNotEmpty ? i.name.trim()[0] : '').join();
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
    setState(() {
      _items.add((name: trimmed, emoji: matchedEmoji));
      _updateMnemonicIfAuto();
    });
    _itemInputController.clear();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _updateMnemonicIfAuto();
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      _updateMnemonicIfAuto();
    });
  }

  Future<void> _saveChecklist() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入清单名称')),
      );
      return;
    }

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.checklistId == null ? '新建清单' : '编辑清单'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saveChecklist,
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
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 26)),
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
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onSubmitted: (val) => _addItem(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Text(
                  '长按拖动排序',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => _removeItem(index),
                    child: Card(
                      key: ValueKey('card_${item.name}_$index'),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                              onPressed: () => _removeItem(index),
                            ),
                            const Icon(Icons.drag_handle, color: AppColors.textSecondary),
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
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '口诀条',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _mnemonicEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
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
                        onChanged: (val) {
                          _isAutoMnemonic = false;
                        },
                        decoration: const InputDecoration(
                          hintText: '如：身手钥钱',
                          border: OutlineInputBorder(),
                          helperText: '口诀字数必须与物品数量一致才能显示',
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
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '定时提醒',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: _reminderEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
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
                        trailing: Text(
                          _reminderTime.format(context),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }

  Widget _buildWeekdayChip(int day, String label) {
    final isSelected = _reminderWeekdays.contains(day);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _reminderWeekdays.remove(day);
          } else {
            _reminderWeekdays.add(day);
            _reminderWeekdays.sort();
          }
        });
      },
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secondaryBg,
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择清单图标',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _emojiPickerOptions.map((e) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmoji = e;
                        });
                        context.pop();
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedEmoji == e ? AppColors.primaryLight : AppColors.secondaryBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedEmoji == e ? AppColors.primary : AppColors.border,
                            width: _selectedEmoji == e ? 2 : 1,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
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
