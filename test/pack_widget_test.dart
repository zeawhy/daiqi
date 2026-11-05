import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/app/theme.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/domain/models/pack_models.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';
import 'package:daiqi/features/pack/backpack_widget.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';
import 'package:daiqi/features/pack/mnemonic_bar.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/l10n/app_localizations.dart';

void main() {
  group('ItemCardWidget Tests', () {
    testWidgets('renders unpacked item card', (tester) async {
      const item = PackItemModel(
        listItemId: 'item-1',
        globalItemId: 'g-1',
        name: '钥匙',
        emoji: '🔑',
        sortOrder: 0,
        isPacked: false,
        isHighRisk: false,
        isSkipped: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ItemCardWidget(item: item),
          ),
        ),
      );

      expect(find.text('钥匙'), findsOneWidget);
      expect(find.text('🔑'), findsOneWidget);
      expect(find.text('必带'), findsNothing);
    });

    testWidgets('renders high-risk item card with 必带 badge', (tester) async {
      const item = PackItemModel(
        listItemId: 'item-2',
        globalItemId: 'g-2',
        name: '身份证',
        emoji: '🆔',
        sortOrder: 0,
        isPacked: false,
        isHighRisk: true,
        isSkipped: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ItemCardWidget(item: item),
          ),
        ),
      );

      expect(find.text('身份证'), findsOneWidget);
      expect(find.text('必带'), findsOneWidget);
    });

    testWidgets('renders packed card with dimmed style', (tester) async {
      const item = PackItemModel(
        listItemId: 'item-3',
        globalItemId: 'g-3',
        name: '手机',
        emoji: '📱',
        sortOrder: 0,
        isPacked: true,
        isHighRisk: false,
        isSkipped: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ItemCardWidget(item: item),
          ),
        ),
      );

      expect(find.text('手机'), findsOneWidget);
      // Finding the opacity widget for packed emoji
      final opacityFinder = find.byWidgetPredicate(
        (widget) => widget is Opacity && widget.opacity == 0.45,
      );
      expect(opacityFinder, findsOneWidget);
    });
  });

  group('MnemonicBar Tests', () {
    testWidgets('renders mnemonic characters and highlights packed items', (tester) async {
      final items = [
        const PackItemModel(
          listItemId: '1',
          globalItemId: 'g1',
          name: '身',
          emoji: '🆔',
          sortOrder: 0,
          isPacked: true,
          isHighRisk: false,
          isSkipped: false,
        ),
        const PackItemModel(
          listItemId: '2',
          globalItemId: 'g2',
          name: '手',
          emoji: '📱',
          sortOrder: 1,
          isPacked: false,
          isHighRisk: false,
          isSkipped: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MnemonicBar(
              mnemonic: '身手',
              items: items,
            ),
          ),
        ),
      );

      expect(find.text('身'), findsOneWidget);
      expect(find.text('手'), findsOneWidget);
    });

    testWidgets(
        'packing items in 身手钥钱 triggers full 420ms scale animation without throwing or ErrorWidget',
        (tester) async {
      List<PackItemModel> buildItems({int packedCount = 0}) => [
            PackItemModel(
              listItemId: '1',
              globalItemId: 'g1',
              name: '身份证',
              emoji: '🆔',
              sortOrder: 0,
              isPacked: packedCount >= 1,
              isHighRisk: false,
              isSkipped: false,
            ),
            PackItemModel(
              listItemId: '2',
              globalItemId: 'g2',
              name: '手机',
              emoji: '📱',
              sortOrder: 1,
              isPacked: packedCount >= 2,
              isHighRisk: false,
              isSkipped: false,
            ),
            PackItemModel(
              listItemId: '3',
              globalItemId: 'g3',
              name: '钥匙',
              emoji: '🔑',
              sortOrder: 2,
              isPacked: packedCount >= 3,
              isHighRisk: false,
              isSkipped: false,
            ),
            PackItemModel(
              listItemId: '4',
              globalItemId: 'g4',
              name: '钱包',
              emoji: '👛',
              sortOrder: 3,
              isPacked: packedCount >= 4,
              isHighRisk: false,
              isSkipped: false,
            ),
          ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MnemonicBar(
              mnemonic: '身手钥钱',
              items: buildItems(packedCount: 0),
            ),
          ),
        ),
      );

      for (final ch in ['身', '手', '钥', '钱']) {
        expect(find.text(ch), findsOneWidget);
      }

      // Pack each of the 4 items one by one and step through the 420ms TweenSequence scale animation
      for (int count = 1; count <= 4; count++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MnemonicBar(
                mnemonic: '身手钥钱',
                items: buildItems(packedCount: count),
              ),
            ),
          ),
        );

        for (int ms = 0; ms <= 450; ms += 30) {
          await tester.pump(const Duration(milliseconds: 30));
          expect(tester.takeException(), isNull);
          expect(find.byType(ErrorWidget), findsNothing);
        }
      }
    });
  });

  group('BackpackWidget Tests', () {
    testWidgets('renders backpack custom painter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BackpackWidget(
              progress: 0.5,
              isOpen: false,
              isDone: false,
            ),
          ),
        ),
      );

      expect(find.byType(BackpackWidget), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('PackScreen Interaction Widget Tests (Drag in, Click pack, Unpack)', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;
    late String testListId;
    bool dbClosed = false;

    setUp(() async {
      AudioService.enabled = false;
      HapticService.enabled = false;
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      dbClosed = false;
      // Initialize preset checklist
      final repo = ChecklistRepository(inMemoryDb);
      await repo.ensurePresetChecklist();
      final summaries = await repo.watchAllSummaries().first;
      testListId = summaries.first.id;
      // Own the container so tests can dispose it explicitly before the
      // framework tears the tree down. Disposing a StreamProvider backed by
      // a drift stream schedules a zero-duration timer (StreamQueryStore
      // markAsClosed); if that timer is still pending when the framework
      // disposes the tree, the test fails with "Timer is still pending".
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
      );
    });

    tearDown(() async {
      // addTearDown in each test body already disposes the container,
      // flushes timers and closes the db. This is only a safety net.
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
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PackScreen(checklistId: testListId),
        ),
      );
    }

    /// Advances frames in fixed increments instead of [WidgetTester.pumpAndSettle]
    /// because [BackpackWidget] runs a continuous `_waveController.repeat()` loop
    /// when `reducedMotion` is false.
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

    testWidgets('Click unpacked card to pack item, and click packed card to unpack',
        (WidgetTester tester) async {
      // Dispose the container explicitly and flush its zero-duration
      // timers before the framework disposes the tree (see setUp note).
      addTearDown(() async {
        container.dispose();
        await tester.pump();
        if (!dbClosed) {
          await inMemoryDb.close();
          dbClosed = true;
        }
      });
      // Set tester window size to a realistic phone resolution (400 x 850)
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp());
      // Wait for session and stream to load
      await pumpFrames(tester);

      // Check initial state: "还差 4 件" + mnemonic bar "身手钥钱"
      expect(find.text('身份证'), findsOneWidget);
      expect(find.text('手机'), findsOneWidget);
      expect(find.text('钥匙'), findsOneWidget);
      expect(find.text('钱包'), findsOneWidget);
      expect(find.byType(MnemonicBar), findsOneWidget);
      expect(find.text('0 / 4'), findsOneWidget);

      // 1. Click unpacked card "身份证" -> Fast pack + MnemonicBar scale animation
      await tester.tap(find.text('身份证'));
      await tester.pump(); // animation start
      await tester.pump(const Duration(milliseconds: 500)); // complete flight animation
      await pumpFrames(
        tester,
        total: const Duration(milliseconds: 500),
        step: const Duration(milliseconds: 30),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);

      // Verify packed count increased: "1 / 4"
      expect(find.text('1 / 4'), findsOneWidget);

      // 2. Click packed card "身份证" -> Unpack
      await tester.tap(find.text('身份证'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await pumpFrames(tester);

      // Verify packed count back to "0 / 4"
      expect(find.text('0 / 4'), findsOneWidget);
    });

    testWidgets('Drag card > 8pt into backpack drop zone packs item',
        (WidgetTester tester) async {
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

      // Card location
      final cardFinder = find.text('钥匙');
      final cardCenter = tester.getCenter(cardFinder);

      // Backpack area location (at the bottom)
      final backpackFinder = find.byType(BackpackWidget);
      final backpackCenter = tester.getCenter(backpackFinder);

      // Perform custom pointer drag:
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump();

      // Move down slightly (15pt > 8pt threshold) to start drag
      await gesture.moveBy(const Offset(0, 15));
      await tester.pump();

      // Move to backpack drop zone
      await gesture.moveTo(backpackCenter);
      await tester.pump();

      // Drop (release pointer)
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await pumpFrames(tester);

      // Verify item packed
      expect(find.text('1 / 4'), findsOneWidget);
    });

    testWidgets('Drag card and drop outside drop zone flies back and remains unpacked',
        (WidgetTester tester) async {
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

      // Card location
      final cardFinder = find.text('钱包');
      final cardCenter = tester.getCenter(cardFinder);

      // Drag slightly sideways (outside backpack drop zone)
      final gesture = await tester.startGesture(cardCenter);
      await tester.pump();

      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();

      // Release outside drop zone
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await pumpFrames(tester);

      // Remains unpacked
      expect(find.text('0 / 4'), findsOneWidget);
    });
  });
}
