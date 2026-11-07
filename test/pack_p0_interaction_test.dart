import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/app/theme.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/features/pack/backpack_widget.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/l10n/app_localizations.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';
import 'package:go_router/go_router.dart';

Finder get draggedCard =>
    find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);

void setView(WidgetTester t, {Size size = const Size(400, 850),
    double top = 0, double bottom = 0, double left = 0, double right = 0}) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  final p = FakeViewPadding(top: top, bottom: bottom, left: left, right: right);
  t.view.padding = p;
  t.view.viewPadding = p;
  addTearDown(() { t.view.resetPhysicalSize(); t.view.resetPadding(); t.view.resetViewPadding(); });
}

Rect slotRect(WidgetTester t, String name) =>
    t.getRect(find.ancestor(of: find.text(name), matching: find.byType(SizedBox)).first);

void main() {
  group('P0 #1: Long press and tap gesture tests', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;
    late String testListId;
    bool dbClosed = false;

    setUp(() async {
      AudioService.enabled = false;
      HapticService.enabled = false;
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      dbClosed = false;

      final repo = ChecklistRepository(inMemoryDb);
      await repo.ensurePresetChecklist();
      final summaries = await repo.watchAllSummaries().first;
      testListId = summaries.first.id;

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
      );
    });

    tearDown(() async {
      if (!dbClosed) {
        try {
          container.dispose();
        } catch (_) {}
        try {
          await inMemoryDb.close();
        } catch (_) {}
        dbClosed = true;
      }
    });

    Widget createTestApp() {
      final router = GoRouter(
        initialLocation: '/pack',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
          GoRoute(path: '/pack', builder: (_, _) => PackScreen(checklistId: testListId)),
        ],
      );
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    Future<void> pumpFrames(
      WidgetTester tester, {
      Duration total = const Duration(milliseconds: 500),
      Duration step = const Duration(milliseconds: 50),
    }) async {
      var elapsed = Duration.zero;
      while (elapsed < total) {
        await tester.pump(step);
        elapsed += step;
      }
    }

    testWidgets('T1a: Long press unpacked card shows menu and does not pack', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      expect(find.text('0 / 4'), findsOneWidget);
      await tester.longPress(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));

      expect(find.text('今天不带'), findsOneWidget);
      expect(find.text('0 / 4'), findsOneWidget);
      expect(find.text('1 / 4'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1b: Long press packed card shows menu and does not unpack', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      // Tap to pack
      await tester.tap(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('1 / 4'), findsOneWidget);

      // Long press packed card
      await tester.longPress(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));

      expect(find.text('今天不带'), findsOneWidget);
      expect(find.text('1 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1c: Long press skipped card can restore without packing', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      // Long press to skip
      await tester.longPress(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('今天不带'), findsOneWidget);

      await tester.tap(find.text('今天不带'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('0 / 3'), findsOneWidget);

      // Long press the skipped card again to restore
      await tester.longPress(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('恢复带上'), findsOneWidget);

      await tester.tap(find.text('恢复带上'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('0 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1d: Drag 12pt then hold 700ms does NOT open menu', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      final gesture = await tester.startGesture(tester.getCenter(find.text('钥匙')));
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // Menu should NOT show up
      expect(find.text('今天不带'), findsNothing);

      // Floating card should be present
      final draggedCard = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);
      expect(draggedCard, findsOneWidget);

      // Release outside dropzone -> card flies back
      await gesture.up();
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('0 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1e: After closing long press menu, subsequent tap works normally', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      // Long press
      await tester.longPress(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('今天不带'), findsOneWidget);

      // Tap modal barrier to dismiss
      await tester.tapAt(const Offset(10, 10));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('今天不带'), findsNothing);

      // Tap the card now -> should pack normally
      await tester.tap(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 800));
      expect(find.text('1 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('P0 #2: Drag overlay and flight animation coordinates', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;
    late String testListId;
    bool dbClosed = false;

    setUp(() async {
      AudioService.enabled = false;
      HapticService.enabled = false;
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      dbClosed = false;

      final repo = ChecklistRepository(inMemoryDb);
      await repo.ensurePresetChecklist();
      final summaries = await repo.watchAllSummaries().first;
      testListId = summaries.first.id;

      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
      );
    });

    tearDown(() async {
      if (!dbClosed) {
        try {
          container.dispose();
        } catch (_) {}
        try {
          await inMemoryDb.close();
        } catch (_) {}
        dbClosed = true;
      }
    });

    Widget createTestApp() {
      final router = GoRouter(
        initialLocation: '/pack',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Home'))),
          GoRoute(path: '/pack', builder: (_, _) => PackScreen(checklistId: testListId)),
        ],
      );
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
    }

    Future<void> pumpFrames(
      WidgetTester tester, {
      Duration total = const Duration(milliseconds: 500),
      Duration step = const Duration(milliseconds: 50),
    }) async {
      var elapsed = Duration.zero;
      while (elapsed < total) {
        await tester.pump(step);
        elapsed += step;
      }
    }

    testWidgets('T2a: Drag card center equals pointer with status bar top=40', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      setView(tester, size: const Size(400, 850), top: 40);

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      final cardCenter = tester.getCenter(find.text('钥匙'));
      final gesture = await tester.startGesture(cardCenter);
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump();
      await gesture.moveBy(const Offset(-40, 70));
      await tester.pump();

      final expectedPointer = cardCenter + const Offset(-40, 85);
      final rect = tester.getRect(draggedCard);
      expect((rect.center - expectedPointer).distance, lessThan(1.0));

      await gesture.up();
      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2b: Drag card center equals pointer with left and bottom insets', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      setView(tester, size: const Size(400, 850), left: 44, bottom: 34);

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      final cardCenter = tester.getCenter(find.text('钥匙'));
      final gesture = await tester.startGesture(cardCenter);
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 50));
      await tester.pump();

      final expectedPointer = cardCenter + const Offset(-30, 65);
      final rect = tester.getRect(draggedCard);
      expect((rect.center - expectedPointer).distance, lessThan(1.0));

      await gesture.up();
      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2c: Fly back end position matches slot center and size', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      setView(tester, size: const Size(400, 850), top: 40);

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      final initialSlot = slotRect(tester, '钱包');
      final startCenter = tester.getCenter(find.text('钱包'));
      final gesture = await tester.startGesture(startCenter);
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump();
      await gesture.moveBy(const Offset(-100, 60));
      await tester.pump();

      final dropPoint = startCenter + const Offset(-100, 75);
      await gesture.up();
      await tester.pump();

      // First frame of flight: center matches release point
      final firstFrameRect = tester.getRect(draggedCard);
      expect((firstFrameRect.center - dropPoint).distance, lessThan(2.0));

      // Near end of flyback (270ms)
      await tester.pump(const Duration(milliseconds: 270));
      final nearEndRect = tester.getRect(draggedCard);
      expect((nearEndRect.center - initialSlot.center).distance, lessThan(3.0));
      expect((nearEndRect.size.width - initialSlot.size.width).abs(), lessThan(0.5));
      expect((nearEndRect.size.height - initialSlot.size.height).abs(), lessThan(0.5));

      // Flight completed
      await pumpFrames(tester, total: const Duration(milliseconds: 200));
      expect(draggedCard, findsNothing);
      expect(find.text('0 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2d: Click pack flight start position matches slot and has correct size', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      setView(tester, size: const Size(400, 850), top: 40);

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      final slot = slotRect(tester, '钥匙');
      await tester.tap(find.text('钥匙'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      // First frame overlay: rect matches slot exactly
      final firstFrameRect = tester.getRect(draggedCard);
      expect((firstFrameRect.center - slot.center).distance, lessThan(1.0));
      expect((firstFrameRect.size.width - slot.size.width).abs(), lessThan(0.5));
      expect((firstFrameRect.size.height - slot.size.height).abs(), lessThan(0.5));

      // End of flight
      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      expect(find.text('1 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2e: Drop into backpack flies into backpack mouth and commits pack', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      setView(tester, size: const Size(400, 850), top: 40);

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      final backpackContainer = find.ancestor(of: find.byType(BackpackWidget), matching: find.byType(Container)).first;
      final backpackRect = tester.getRect(backpackContainer);
      final dropTarget = Offset(backpackRect.center.dx, backpackRect.top + backpackRect.height * 0.22);

      final gesture = await tester.startGesture(tester.getCenter(find.text('钥匙')));
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump();
      await gesture.moveTo(dropTarget);
      await tester.pump();

      await gesture.up();
      await tester.pump();

      // First frame overlay center matches drop point
      final firstFrameRect = tester.getRect(draggedCard);
      expect((firstFrameRect.center - dropTarget).distance, lessThan(2.0));

      await pumpFrames(tester, total: const Duration(milliseconds: 500));
      expect(find.text('1 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2f: Unpack flight ends at re-sorted slot position', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      setView(tester, size: const Size(400, 850), top: 40);

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      // Pack '钥匙'
      await tester.tap(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      expect(find.text('1 / 4'), findsOneWidget);

      // Tap packed card to unpack
      await tester.tap(find.text('钥匙'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 319));

      final nearEndRect = tester.getRect(draggedCard);
      // Wait for flight to finish and check new slot
      await pumpFrames(tester, total: const Duration(milliseconds: 300));
      final newSlot = slotRect(tester, '钥匙');

      expect((nearEndRect.center - newSlot.center).distance, lessThan(3.0));
      expect((nearEndRect.size.width - newSlot.size.width).abs(), lessThan(0.5));
      expect((nearEndRect.size.height - newSlot.size.height).abs(), lessThan(0.5));
      expect(find.text('0 / 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2g: Original slot displays dashed placeholder during flight', (tester) async {
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      setView(tester, size: const Size(400, 850), top: 40);

      await tester.pumpWidget(createTestApp());
      await pumpFrames(tester);

      // Tap to pack
      await tester.tap(find.text('钥匙'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // During flight, the slot widget has isPlaceholder: true
      final placeholderCards = find.byWidgetPredicate((w) => w is ItemCardWidget && w.isPlaceholder);
      expect(placeholderCards, findsOneWidget);

      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      // After flight finishes, no placeholder
      expect(find.byWidgetPredicate((w) => w is ItemCardWidget && w.isPlaceholder), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
