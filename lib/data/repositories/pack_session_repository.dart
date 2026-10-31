import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/pack_models.dart';
import '../../domain/rules/session_rules.dart';
import '../database.dart';
import 'checklist_repository.dart';

class PackSessionRepository {
  final AppDatabase db;
  final ChecklistRepository checklistRepo;
  static const _uuid = Uuid();

  PackSessionRepository(this.db, this.checklistRepo);

  /// Get or create an active in_progress session for this checklist.
  /// Section 7.1:
  /// - If latest session is in_progress and within 12 hours, continue it.
  /// - Otherwise create a new session, old in_progress sessions are marked abandoned.
  Future<PackSession> getOrCreateSession(String listId) async {
    final now = DateTime.now().toUtc();

    final latestSession = await (db.select(db.packSessions)
          ..where((t) => t.listId.equals(listId) & t.status.equals('in_progress'))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();

    if (latestSession != null &&
        SessionRules.canResumeSession(startedAt: latestSession.startedAt, now: now)) {
      // Ensure all current checklist items exist in session items
      await _syncSessionItems(latestSession.id, listId);
      return latestSession;
    }

    // Mark previous in_progress sessions as abandoned
    await (db.update(db.packSessions)
          ..where((t) => t.listId.equals(listId) & t.status.equals('in_progress')))
        .write(const PackSessionsCompanion(status: Value('abandoned')));

    // Create new session
    final sessionId = _uuid.v4();
    await db.into(db.packSessions).insert(
          PackSessionsCompanion.insert(
            id: sessionId,
            listId: listId,
            status: 'in_progress',
            startedAt: now,
          ),
        );

    // Initialize session items for all items in the checklist
    final items = await checklistRepo.getItemsForChecklist(listId);
    for (final item in items) {
      await db.into(db.packSessionItems).insert(
            PackSessionItemsCompanion.insert(
              sessionId: sessionId,
              listItemId: item.id,
              packedAt: const Value(null),
              skipped: const Value(false),
            ),
          );
    }

    return (await (db.select(db.packSessions)..where((t) => t.id.equals(sessionId))).getSingle());
  }

  Future<void> _syncSessionItems(String sessionId, String listId) async {
    final items = await checklistRepo.getItemsForChecklist(listId);
    for (final item in items) {
      final existing = await (db.select(db.packSessionItems)
            ..where((t) => t.sessionId.equals(sessionId) & t.listItemId.equals(item.id)))
          .getSingleOrNull();
      if (existing == null) {
        await db.into(db.packSessionItems).insert(
              PackSessionItemsCompanion.insert(
                sessionId: sessionId,
                listItemId: item.id,
                packedAt: const Value(null),
                skipped: const Value(false),
              ),
            );
      }
    }
  }

  /// Get current pack items directly from database.
  Future<List<PackItemModel>> getPackItems(String sessionId, String listId) async {
    final sessionItems = await (db.select(db.packSessionItems)..where((t) => t.sessionId.equals(sessionId))).get();
    final listItems = await checklistRepo.getItemsForChecklist(listId);
    final itemMap = {for (var i in listItems) i.id: i};

    final List<PackItemModel> models = [];

    for (final sItem in sessionItems) {
      final listItem = itemMap[sItem.listItemId];
      if (listItem == null) continue;

      final isHighRisk = await checklistRepo.checkIfItemIsHighRisk(listItem.globalItemId);

      models.add(
        PackItemModel(
          listItemId: listItem.id,
          globalItemId: listItem.globalItemId,
          name: listItem.name,
          emoji: listItem.emoji,
          sortOrder: listItem.sortOrder,
          isPacked: sItem.packedAt != null,
          isHighRisk: isHighRisk,
          isSkipped: sItem.skipped,
          packedAt: sItem.packedAt,
        ),
      );
    }

    models.sort((a, b) {
      return SessionRules.comparePackItems(
        aIsSkipped: a.isSkipped,
        aIsPacked: a.isPacked,
        aIsHighRisk: a.isHighRisk,
        aSortOrder: a.sortOrder,
        bIsSkipped: b.isSkipped,
        bIsPacked: b.isPacked,
        bIsHighRisk: b.isHighRisk,
        bSortOrder: b.sortOrder,
      );
    });

    return models;
  }

  /// Watch pack items for a session, sorted according to Section 5.2/6.3 rules:
  /// High-risk unpacked -> Other unpacked -> Packed -> Skipped.
  Stream<List<PackItemModel>> watchPackItems(String sessionId, String listId) {
    return (db.select(db.packSessionItems)..where((t) => t.sessionId.equals(sessionId)))
        .watch()
        .asyncMap((sessionItems) async {
      final listItems = await checklistRepo.getItemsForChecklist(listId);
      final itemMap = {for (var i in listItems) i.id: i};

      final List<PackItemModel> models = [];

      for (final sItem in sessionItems) {
        final listItem = itemMap[sItem.listItemId];
        if (listItem == null) continue;

        final isHighRisk = await checklistRepo.checkIfItemIsHighRisk(listItem.globalItemId);

        models.add(
          PackItemModel(
            listItemId: listItem.id,
            globalItemId: listItem.globalItemId,
            name: listItem.name,
            emoji: listItem.emoji,
            sortOrder: listItem.sortOrder,
            isPacked: sItem.packedAt != null,
            isHighRisk: isHighRisk,
            isSkipped: sItem.skipped,
            packedAt: sItem.packedAt,
          ),
        );
      }

      // Sort items
      models.sort((a, b) {
        return SessionRules.comparePackItems(
          aIsSkipped: a.isSkipped,
          aIsPacked: a.isPacked,
          aIsHighRisk: a.isHighRisk,
          aSortOrder: a.sortOrder,
          bIsSkipped: b.isSkipped,
          bIsPacked: b.isPacked,
          bIsHighRisk: b.isHighRisk,
          bSortOrder: b.sortOrder,
        );
      });

      return models;
    });
  }

  /// Pack an item
  Future<void> packItem(String sessionId, String listItemId) async {
    final now = DateTime.now().toUtc();
    await (db.update(db.packSessionItems)
          ..where((t) => t.sessionId.equals(sessionId) & t.listItemId.equals(listItemId)))
        .write(PackSessionItemsCompanion(packedAt: Value(now)));
  }

  /// Unpack an item
  Future<void> unpackItem(String sessionId, String listItemId) async {
    await (db.update(db.packSessionItems)
          ..where((t) => t.sessionId.equals(sessionId) & t.listItemId.equals(listItemId)))
        .write(const PackSessionItemsCompanion(packedAt: Value(null)));
  }

  /// Toggle item skipped ("今天不带")
  Future<void> toggleSkipped(String sessionId, String listItemId) async {
    final current = await (db.select(db.packSessionItems)
          ..where((t) => t.sessionId.equals(sessionId) & t.listItemId.equals(listItemId)))
        .getSingleOrNull();

    if (current == null) return;

    final newSkipped = !current.skipped;
    await (db.update(db.packSessionItems)
          ..where((t) => t.sessionId.equals(sessionId) & t.listItemId.equals(listItemId)))
        .write(PackSessionItemsCompanion(
          skipped: Value(newSkipped),
          // If skipped, un-pack it
          packedAt: newSkipped ? const Value(null) : Value(current.packedAt),
        ));
  }

  /// Update session status
  Future<void> updateSessionStatus(
    String sessionId,
    String status, {
    DateTime? completedAt,
    DateTime? departedAt,
  }) async {
    await (db.update(db.packSessions)..where((t) => t.id.equals(sessionId))).write(
      PackSessionsCompanion(
        status: Value(status),
        completedAt: completedAt == null ? const Value.absent() : Value(completedAt),
        departedAt: departedAt == null ? const Value.absent() : Value(departedAt),
      ),
    );
  }
}
