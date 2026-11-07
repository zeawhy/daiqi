import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/app/theme.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/l10n/app_localizations.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';
import 'package:go_router/go_router.dart';

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
}
