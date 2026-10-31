import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/repositories/checklist_repository.dart';
import '../data/repositories/pack_session_repository.dart';
import '../domain/models/pack_models.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ChecklistRepository(db);
});

final packSessionRepositoryProvider = Provider<PackSessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final checklistRepo = ref.watch(checklistRepositoryProvider);
  return PackSessionRepository(db, checklistRepo);
});

final allChecklistsStreamProvider = StreamProvider<List<ChecklistSummaryModel>>((ref) {
  final repo = ref.watch(checklistRepositoryProvider);
  return repo.watchAllSummaries();
});

final sessionItemsStreamProvider =
    StreamProvider.family<List<PackItemModel>, ({String sessionId, String listId})>(
  (ref, args) {
    final repo = ref.watch(packSessionRepositoryProvider);
    return repo.watchPackItems(args.sessionId, args.listId);
  },
);

/// Reduced motion setting provider (Section 6.6)
class ReducedMotionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setReducedMotion(bool value) {
    state = value;
  }
}

final reducedMotionProvider =
    NotifierProvider<ReducedMotionNotifier, bool>(ReducedMotionNotifier.new);
