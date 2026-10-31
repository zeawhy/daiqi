import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/pack_models.dart';
import '../../domain/rules/high_risk_rules.dart';
import '../../domain/rules/name_normalizer.dart';
import '../../domain/rules/session_rules.dart';
import '../database.dart';

class ChecklistRepository {
  final AppDatabase db;
  static const _uuid = Uuid();

  ChecklistRepository(this.db);

  /// Ensure the preset checklist "伸手要钱" exists on first launch.
  Future<void> ensurePresetChecklist() async {
    final existingPreset = await (db.select(db.checklistLists)
          ..where((t) => t.isPreset.equals(true)))
        .getSingleOrNull();

    if (existingPreset != null) return;

    // Check if any checklist exists at all
    final count = await db.checklistLists.count().getSingle();
    if (count > 0) return;

    // Create preset "伸手要钱"
    final presetId = _uuid.v4();
    final now = DateTime.now().toUtc();

    await db.into(db.checklistLists).insert(
          ChecklistListsCompanion.insert(
            id: presetId,
            name: '伸手要钱',
            emoji: '🤚',
            isPreset: const Value(true),
            mnemonic: const Value('身手钥钱'),
            sortOrder: const Value(0),
            reminderEnabled: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final presetItems = [
      ('身份证', '🆔'),
      ('手机', '📱'),
      ('钥匙', '🔑'),
      ('钱包', '👛'),
    ];

    for (int i = 0; i < presetItems.length; i++) {
      final (name, emoji) = presetItems[i];
      final globalItem = await _findOrCreateGlobalItem(name, emoji);
      await db.into(db.listItems).insert(
            ListItemsCompanion.insert(
              id: _uuid.v4(),
              listId: presetId,
              globalItemId: globalItem.id,
              name: name,
              emoji: emoji,
              sortOrder: Value(i),
              createdAt: now,
            ),
          );
    }
  }

  /// Find or create GlobalItem with normalized name.
  Future<GlobalItem> _findOrCreateGlobalItem(String name, String emoji) async {
    final normalized = NameNormalizer.normalize(name);
    final existing = await (db.select(db.globalItems)
          ..where((t) => t.normalizedName.equals(normalized)))
        .getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    final newId = _uuid.v4();
    await db.into(db.globalItems).insert(
          GlobalItemsCompanion.insert(
            id: newId,
            normalizedName: normalized,
            displayName: name,
            emoji: emoji,
            forgotCount: const Value(0),
          ),
        );
    return (await (db.select(db.globalItems)..where((t) => t.id.equals(newId))).getSingle());
  }

  /// Watch all checklist summaries, ordered by sortOrder.
  Stream<List<ChecklistSummaryModel>> watchAllSummaries() {
    return (db.select(db.checklistLists)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch()
        .asyncMap((lists) async {
      final List<ChecklistSummaryModel> summaries = [];
      for (final list in lists) {
        final summary = await _getSummaryForChecklist(list);
        summaries.add(summary);
      }
      return summaries;
    });
  }

  Future<ChecklistSummaryModel> _getSummaryForChecklist(ChecklistList list) async {
    final items = await (db.select(db.listItems)
          ..where((t) => t.listId.equals(list.id))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    // Check active session for this checklist
    final activeSession = await _getActiveSession(list.id);

    int packedCount = 0;
    int highRiskCount = 0;

    for (final item in items) {
      final isHighRisk = await checkIfItemIsHighRisk(item.globalItemId);
      if (isHighRisk) {
        highRiskCount++;
      }

      if (activeSession != null) {
        final sessionItem = await (db.select(db.packSessionItems)
              ..where((t) =>
                  t.sessionId.equals(activeSession.id) &
                  t.listItemId.equals(item.id)))
            .getSingleOrNull();
        if (sessionItem != null && sessionItem.packedAt != null && !sessionItem.skipped) {
          packedCount++;
        }
      }
    }

    List<int> weekdays = [1, 2, 3, 4, 5];
    if (list.reminderWeekdays != null && list.reminderWeekdays!.isNotEmpty) {
      try {
        final decoded = jsonDecode(list.reminderWeekdays!) as List;
        weekdays = decoded.map((e) => e as int).toList();
      } catch (_) {}
    }

    return ChecklistSummaryModel(
      id: list.id,
      name: list.name,
      emoji: list.emoji,
      isPreset: list.isPreset,
      mnemonic: list.mnemonic,
      sortOrder: list.sortOrder,
      reminderEnabled: list.reminderEnabled,
      reminderTime: list.reminderTime,
      reminderWeekdays: weekdays,
      totalCount: items.length,
      packedCount: packedCount,
      highRiskCount: highRiskCount,
      itemNames: items.map((i) => i.name).toList(),
    );
  }

  /// Get active session (in_progress and within 12h)
  Future<PackSession?> _getActiveSession(String listId) async {
    final session = await (db.select(db.packSessions)
          ..where((t) => t.listId.equals(listId) & t.status.equals('in_progress'))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();

    if (session == null) return null;
    if (SessionRules.canResumeSession(startedAt: session.startedAt)) {
      return session;
    }
    return null;
  }

  /// Check whether a global item is high risk.
  Future<bool> checkIfItemIsHighRisk(String globalItemId) async {
    final recentForgot = await (db.select(db.forgotRecords)
          ..where((t) => t.globalItemId.equals(globalItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();

    if (recentForgot == null) return false;

    // Check consecutive packed count after last forgot in departed sessions
    final departedSessionsAfterForgot = await (db.select(db.packSessions)
          ..where((t) =>
              t.status.equals('departed') &
              t.departedAt.isBiggerThanValue(recentForgot.createdAt))
          ..orderBy([(t) => OrderingTerm.desc(t.departedAt)]))
        .get();

    int consecutivePacked = 0;
    for (final session in departedSessionsAfterForgot) {
      final sessionItem = await (db.select(db.packSessionItems)
            ..where((t) => t.sessionId.equals(session.id)))
          .get();

      // Check if this session contained this global item
      bool found = false;
      bool wasPacked = false;
      for (final sItem in sessionItem) {
        final listItem = await (db.select(db.listItems)
              ..where((t) => t.id.equals(sItem.listItemId)))
            .getSingleOrNull();
        if (listItem != null && listItem.globalItemId == globalItemId) {
          found = true;
          if (sItem.packedAt != null && !sItem.skipped) {
            wasPacked = true;
          }
          break;
        }
      }

      if (found) {
        if (wasPacked) {
          consecutivePacked++;
        } else {
          break;
        }
      }
    }

    return HighRiskRules.isHighRisk(
      lastForgotAt: recentForgot.createdAt,
      consecutivePackedCountAfterLastForgot: consecutivePacked,
    );
  }

  /// Get checklist by id
  Future<ChecklistList?> getChecklist(String id) async {
    return (db.select(db.checklistLists)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get items for a checklist
  Future<List<ListItem>> getItemsForChecklist(String listId) async {
    return (db.select(db.listItems)
          ..where((t) => t.listId.equals(listId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Create a new checklist with items
  Future<String> createChecklist({
    required String name,
    required String emoji,
    String? mnemonic,
    bool reminderEnabled = false,
    String? reminderTime,
    List<int>? reminderWeekdays,
    required List<({String name, String emoji})> items,
  }) async {
    final listId = _uuid.v4();
    final now = DateTime.now().toUtc();

    // Max sort order
    final maxSortExp = db.checklistLists.sortOrder.max();
    final query = db.selectOnly(db.checklistLists)..addColumns([maxSortExp]);
    final maxSort = await query.map((row) => row.read(maxSortExp)).getSingleOrNull();
    final sortOrder = (maxSort ?? -1) + 1;

    await db.into(db.checklistLists).insert(
          ChecklistListsCompanion.insert(
            id: listId,
            name: name,
            emoji: emoji,
            isPreset: const Value(false),
            mnemonic: Value(mnemonic),
            sortOrder: Value(sortOrder),
            reminderEnabled: Value(reminderEnabled),
            reminderTime: Value(reminderTime),
            reminderWeekdays: Value(reminderWeekdays == null ? null : jsonEncode(reminderWeekdays)),
            createdAt: now,
            updatedAt: now,
          ),
        );

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final globalItem = await _findOrCreateGlobalItem(item.name, item.emoji);
      await db.into(db.listItems).insert(
            ListItemsCompanion.insert(
              id: _uuid.v4(),
              listId: listId,
              globalItemId: globalItem.id,
              name: item.name,
              emoji: item.emoji,
              sortOrder: Value(i),
              createdAt: now,
            ),
          );
    }

    return listId;
  }

  /// Update an existing checklist and its items
  Future<void> updateChecklist({
    required String listId,
    required String name,
    required String emoji,
    String? mnemonic,
    bool? reminderEnabled,
    String? reminderTime,
    List<int>? reminderWeekdays,
    required List<({String name, String emoji})> items,
  }) async {
    final now = DateTime.now().toUtc();

    await (db.update(db.checklistLists)..where((t) => t.id.equals(listId))).write(
      ChecklistListsCompanion(
        name: Value(name),
        emoji: Value(emoji),
        mnemonic: Value(mnemonic),
        reminderEnabled: reminderEnabled == null ? const Value.absent() : Value(reminderEnabled),
        reminderTime: Value(reminderTime),
        reminderWeekdays: Value(reminderWeekdays == null ? null : jsonEncode(reminderWeekdays)),
        updatedAt: Value(now),
      ),
    );

    // Delete existing items
    await (db.delete(db.listItems)..where((t) => t.listId.equals(listId))).go();

    // Insert new items
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final globalItem = await _findOrCreateGlobalItem(item.name, item.emoji);
      await db.into(db.listItems).insert(
            ListItemsCompanion.insert(
              id: _uuid.v4(),
              listId: listId,
              globalItemId: globalItem.id,
              name: item.name,
              emoji: item.emoji,
              sortOrder: Value(i),
              createdAt: now,
            ),
          );
    }

    // Sync in-progress session if any
    final activeSession = await _getActiveSession(listId);
    if (activeSession != null) {
      // Remove obsolete session items
      final currentListItems = await getItemsForChecklist(listId);
      final currentIds = currentListItems.map((e) => e.id).toSet();

      final allSessionItems = await (db.select(db.packSessionItems)
            ..where((t) => t.sessionId.equals(activeSession.id)))
          .get();
      for (final sItem in allSessionItems) {
        if (!currentIds.contains(sItem.listItemId)) {
          await (db.delete(db.packSessionItems)
                ..where((t) =>
                    t.sessionId.equals(activeSession.id) &
                    t.listItemId.equals(sItem.listItemId)))
              .go();
        }
      }

      // Add missing session items
      for (final cItem in currentListItems) {
        final existingSessionItem = await (db.select(db.packSessionItems)
              ..where((t) =>
                  t.sessionId.equals(activeSession.id) &
                  t.listItemId.equals(cItem.id)))
            .getSingleOrNull();
        if (existingSessionItem == null) {
          await db.into(db.packSessionItems).insert(
                PackSessionItemsCompanion.insert(
                  sessionId: activeSession.id,
                  listItemId: cItem.id,
                  packedAt: const Value(null),
                  skipped: const Value(false),
                ),
              );
        }
      }
    }
  }

  /// Duplicate a checklist
  Future<String> duplicateChecklist(String id) async {
    final original = await getChecklist(id);
    if (original == null) throw Exception('Checklist not found: $id');
    final items = await getItemsForChecklist(id);

    final newName = '${original.name} (副本)';
    return createChecklist(
      name: newName.length > 12 ? newName.substring(0, 12) : newName,
      emoji: original.emoji,
      mnemonic: original.mnemonic,
      reminderEnabled: original.reminderEnabled,
      reminderTime: original.reminderTime,
      reminderWeekdays: original.reminderWeekdays != null
          ? (jsonDecode(original.reminderWeekdays!) as List).map((e) => e as int).toList()
          : null,
      items: items.map((i) => (name: i.name, emoji: i.emoji)).toList(),
    );
  }

  /// Delete a checklist
  /// Section 8: "删除清单时，同时删除它的物品和会话，但保留遗忘记录和 GlobalItem"
  Future<void> deleteChecklist(String id) async {
    final sessions = await (db.select(db.packSessions)..where((t) => t.listId.equals(id))).get();
    for (final s in sessions) {
      await (db.delete(db.packSessionItems)..where((t) => t.sessionId.equals(s.id))).go();
    }
    await (db.delete(db.packSessions)..where((t) => t.listId.equals(id))).go();
    await (db.delete(db.listItems)..where((t) => t.listId.equals(id))).go();
    await (db.delete(db.checklistLists)..where((t) => t.id.equals(id))).go();
  }

  /// Reorder checklists
  Future<void> reorderChecklists(List<String> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      await (db.update(db.checklistLists)..where((t) => t.id.equals(orderedIds[i]))).write(
        ChecklistListsCompanion(sortOrder: Value(i)),
      );
    }
  }
}
