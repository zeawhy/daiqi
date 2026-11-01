import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/data/repositories/pack_session_repository.dart';
import 'package:daiqi/domain/rules/session_rules.dart';
import 'package:daiqi/features/done/done_screen.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M4 Domain Tests - Session Rules', () {
    test('calculateStreak interrupts streak when session was departed_incomplete', () {
      final sessions = [
        (status: 'departed', hadForgot: false),
        (status: 'departed_incomplete', hadForgot: false),
        (status: 'departed', hadForgot: false),
      ];

      final streak = SessionRules.calculateStreak(sessionsDescending: sessions);
      expect(streak, 1);
    });

    test('calculateStreak interrupts streak when session had forgot record', () {
      final sessions = [
        (status: 'departed', hadForgot: false),
        (status: 'departed', hadForgot: false),
        (status: 'departed', hadForgot: true),
        (status: 'departed', hadForgot: false),
      ];

      final streak = SessionRules.calculateStreak(sessionsDescending: sessions);
      expect(streak, 2);
    });

    test('calculateStreak counts multiple consecutive zero-forgot departures', () {
      final sessions = [
        (status: 'departed', hadForgot: false),
        (status: 'departed', hadForgot: false),
        (status: 'departed', hadForgot: false),
      ];

      final streak = SessionRules.calculateStreak(sessionsDescending: sessions);
      expect(streak, 3);
    });

    test('comparePackItems sorts skipped items into group 4 at the very end', () {
      final comp1 = SessionRules.comparePackItems(
        aIsSkipped: true,
        aIsPacked: false,
        aIsHighRisk: false,
        aSortOrder: 0,
        bIsSkipped: false,
        bIsPacked: false,
        bIsHighRisk: false,
        bSortOrder: 1,
      );
      expect(comp1 > 0, isTrue);

      final comp2 = SessionRules.comparePackItems(
        aIsSkipped: true,
        aIsPacked: false,
        aIsHighRisk: false,
        aSortOrder: 0,
        bIsSkipped: false,
        bIsPacked: true,
        bIsHighRisk: false,
        bSortOrder: 1,
      );
      expect(comp2 > 0, isTrue);
    });
  });

  group('M4 DoneScreen Widget Tests', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;
    late String testListId;
    late String testSessionId;

    setUp(() async {
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      final chkRepo = ChecklistRepository(inMemoryDb);
      await chkRepo.ensurePresetChecklist();
      final summaries = await chkRepo.watchAllSummaries().first;
      testListId = summaries.first.id;

      final sessionRepo = PackSessionRepository(inMemoryDb, chkRepo);
      final session = await sessionRepo.getOrCreateSession(testListId);
      testSessionId = session.id;

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

    Widget createTestApp(Widget homeWidget) {
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Home'))),
          GoRoute(path: '/test', builder: (_, __) => homeWidget),
        ],
      );
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('renders completion UI with title, subtitle, exit button and forgot link',
        (tester) async {
      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        createTestApp(
          DoneScreen(
            sessionId: testSessionId,
            listId: testListId,
          ),
        ),
      );

      // Wait for _loadData to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('全部带齐，出门吧！'), findsOneWidget);
      expect(find.text('出门 🚪'), findsOneWidget);
      expect(find.textContaining('还是忘了东西？记一笔'), findsOneWidget);
      expect(find.text('‹ 返回'), findsOneWidget);
    });

    testWidgets('Tapping 出门 🚪 marks session as departed', (tester) async {
      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        createTestApp(
          DoneScreen(
            sessionId: testSessionId,
            listId: testListId,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final departButton = find.text('出门 🚪');
      expect(departButton, findsOneWidget);

      await tester.tap(departButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final sessionRepo = PackSessionRepository(inMemoryDb, ChecklistRepository(inMemoryDb));
      final updated = await sessionRepo.getSessionById(testSessionId);
      expect(updated?.status, 'departed');
      expect(updated?.departedAt, isNotNull);
    });

    testWidgets('PopScope / back navigation on DoneScreen marks session as departed', (tester) async {
      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        createTestApp(
          DoneScreen(
            sessionId: testSessionId,
            listId: testListId,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final backButton = find.text('‹ 返回');
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final sessionRepo = PackSessionRepository(inMemoryDb, ChecklistRepository(inMemoryDb));
      final updated = await sessionRepo.getSessionById(testSessionId);
      expect(updated?.status, 'departed');
      expect(updated?.departedAt, isNotNull);
    });
  });

  group('M4 PackScreen Incomplete Departure & Skipped Tests', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;
    late String testListId;
    late String testSessionId;

    setUp(() async {
      AudioService.enabled = false;
      HapticService.enabled = false;
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      final chkRepo = ChecklistRepository(inMemoryDb);
      await chkRepo.ensurePresetChecklist();
      final summaries = await chkRepo.watchAllSummaries().first;
      testListId = summaries.first.id;

      final sessionRepo = PackSessionRepository(inMemoryDb, chkRepo);
      final session = await sessionRepo.getOrCreateSession(testListId);
      testSessionId = session.id;

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

    Widget createTestApp(Widget homeWidget) {
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('Home'))),
          GoRoute(path: '/test', builder: (_, __) => homeWidget),
        ],
      );
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('When all items are skipped, displays allSkipped banner and 直接出门 button',
        (tester) async {
      final sessionRepo = PackSessionRepository(inMemoryDb, ChecklistRepository(inMemoryDb));
      final items = await sessionRepo.getPackItems(testSessionId, testListId);

      // Skip all items
      for (final it in items) {
        await sessionRepo.toggleSkipped(testSessionId, it.listItemId);
      }

      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        createTestApp(
          PackScreen(checklistId: testListId),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('今天什么都不带吗？'), findsWidgets);
      expect(find.text('直接出门'), findsOneWidget);

      await tester.tap(find.text('直接出门'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final updated = await sessionRepo.getSessionById(testSessionId);
      expect(updated?.status, 'departed');
    });

    testWidgets('Leave with partially packed items shows departure dialog and 就这样出门 marks departed_incomplete',
        (tester) async {
      final sessionRepo = PackSessionRepository(inMemoryDb, ChecklistRepository(inMemoryDb));
      final items = await sessionRepo.getPackItems(testSessionId, testListId);

      // Pack 1 item
      await sessionRepo.packItem(testSessionId, items.first.listItemId);

      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        createTestApp(
          PackScreen(checklistId: testListId),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap back button
      await tester.tap(find.text('‹ 返回'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog is shown
      expect(find.text('确定就这样出门吗？'), findsOneWidget);
      expect(find.text('再看看'), findsOneWidget);
      expect(find.text('稍后再装'), findsOneWidget);
      expect(find.text('就这样出门'), findsOneWidget);

      // Tap '就这样出门'
      await tester.tap(find.text('就这样出门'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final updated = await sessionRepo.getSessionById(testSessionId);
      expect(updated?.status, 'departed_incomplete');
      expect(updated?.departedAt, isNotNull);
    });

    testWidgets('Leave with partially packed items and selecting 稍后再装 preserves in_progress',
        (tester) async {
      final sessionRepo = PackSessionRepository(inMemoryDb, ChecklistRepository(inMemoryDb));
      final items = await sessionRepo.getPackItems(testSessionId, testListId);

      // Pack 1 item
      await sessionRepo.packItem(testSessionId, items.first.listItemId);

      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        createTestApp(
          PackScreen(checklistId: testListId),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap back button
      await tester.tap(find.text('‹ 返回'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('稍后再装'), findsOneWidget);

      // Tap '稍后再装'
      await tester.tap(find.text('稍后再装'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final updated = await sessionRepo.getSessionById(testSessionId);
      expect(updated?.status, 'in_progress');
    });
  });
}
