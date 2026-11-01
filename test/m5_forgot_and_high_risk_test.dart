import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/data/repositories/pack_session_repository.dart';
import 'package:daiqi/features/forgot/forgot_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M5 Domain & Repository Tests - Record Forgot & High Risk', () {
    late AppDatabase db;
    late ChecklistRepository chkRepo;
    late PackSessionRepository sessionRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      chkRepo = ChecklistRepository(db);
      sessionRepo = PackSessionRepository(db, chkRepo);
      await chkRepo.ensurePresetChecklist();
    });

    tearDown(() async {
      await db.close();
    });

    test('Recording forgot item updates forgotCount and makes item high-risk', () async {
      final summaries = await chkRepo.watchAllSummaries().first;
      final listId = summaries.first.id;

      // Initial state: not high risk
      final items = await chkRepo.getItemsForChecklist(listId);
      final phone = items.firstWhere((i) => i.name == '手机');
      expect(await chkRepo.checkIfItemIsHighRisk(phone.globalItemId), isFalse);

      // Record forgot item
      final recorded = await chkRepo.recordForgotItems(
        listId: listId,
        itemNames: ['手机'],
      );
      expect(recorded, ['手机']);

      // Now it is high-risk!
      expect(await chkRepo.checkIfItemIsHighRisk(phone.globalItemId), isTrue);

      // Check stats
      final stats = await chkRepo.getForgotStats();
      expect(stats.forgotCount, 1);
    });

    test('High risk item is cleared after 3 consecutive successful departures', () async {
      final summaries = await chkRepo.watchAllSummaries().first;
      final listId = summaries.first.id;
      final items = await chkRepo.getItemsForChecklist(listId);
      final phone = items.firstWhere((i) => i.name == '手机');

      // Record forgot item
      await chkRepo.recordForgotItems(
        listId: listId,
        itemNames: ['手机'],
      );
      expect(await chkRepo.checkIfItemIsHighRisk(phone.globalItemId), isTrue);

      // Simulate 3 consecutive departed sessions where phone was packed
      for (int i = 0; i < 3; i++) {
        final session = await sessionRepo.getOrCreateSession(listId);
        await sessionRepo.packItem(session.id, phone.id);
        await sessionRepo.updateSessionStatus(
          session.id,
          'departed',
          departedAt: DateTime.now().toUtc().add(Duration(minutes: i + 1)),
        );
      }

      // After 3 consecutive packed departures, high risk is cleared!
      expect(await chkRepo.checkIfItemIsHighRisk(phone.globalItemId), isFalse);
    });

    test('Deleting checklist preserves global forgot statistics (Section 8)', () async {
      final listId = await chkRepo.createChecklist(
        name: '临时出游',
        emoji: '🏖️',
        items: [(name: '防晒霜', emoji: '🧴')],
      );

      await chkRepo.recordForgotItems(
        listId: listId,
        itemNames: ['防晒霜'],
      );

      final statsBefore = await chkRepo.getForgotStats();
      expect(statsBefore.forgotCount, 1);

      // Delete the checklist
      await chkRepo.deleteChecklist(listId);

      // Statistics and ranking still preserved!
      final statsAfter = await chkRepo.getForgotStats();
      expect(statsAfter.forgotCount, 1);

      final ranking = await chkRepo.getTopForgottenItems();
      expect(ranking.any((r) => r.item.displayName == '防晒霜'), isTrue);
    });
  });

  group('M5 ForgotScreen Widget Tests', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;
    late ChecklistRepository chkRepo;

    setUp(() async {
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      chkRepo = ChecklistRepository(inMemoryDb);
      await chkRepo.ensurePresetChecklist();

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await inMemoryDb.close();
    });

    testWidgets('Empty state displays smiling green backpack and placeholder text',
        (tester) async {
      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ForgotScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('遗忘记录'), findsOneWidget);
      expect(find.text('记一笔'), findsOneWidget);
      expect(find.text('出门次数'), findsOneWidget);
      expect(find.text('遗忘次数'), findsOneWidget);
      expect(find.text('连续零遗漏'), findsOneWidget);
      expect(find.text('还没有忘过东西，继续保持 👍'), findsOneWidget);
    });

    testWidgets('Displays ranking and timeline when forgot items recorded', (tester) async {
      // Prepopulate forgot record
      final summaries = await chkRepo.watchAllSummaries().first;
      final listId = summaries.first.id;

      await chkRepo.recordForgotItems(
        listId: listId,
        itemNames: ['钥匙', '钱包'],
      );

      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ForgotScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('最常忘的东西'), findsOneWidget);
      expect(find.text('最近记录'), findsOneWidget);
      expect(find.text('忘了 钥匙'), findsOneWidget);
      expect(find.text('忘了 钱包'), findsOneWidget);
    });
  });
}
