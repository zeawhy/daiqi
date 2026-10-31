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
      expect(find.text('!'), findsNothing);
    });

    testWidgets('renders high-risk item card with exclamation mark', (tester) async {
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
      expect(find.text('!'), findsOneWidget);
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
        (widget) => widget is Opacity && widget.opacity == 0.35,
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
      await tester.pumpAndSettle();

      // Check initial state: "还差 4 件"
      expect(find.text('身份证'), findsOneWidget);
      expect(find.text('手机'), findsOneWidget);
      expect(find.text('钥匙'), findsOneWidget);
      expect(find.text('钱包'), findsOneWidget);
      expect(find.text('0 / 4'), findsOneWidget);

      // 1. Click unpacked card "身份证" -> Fast pack
      await tester.tap(find.text('身份证'));
      await tester.pump(); // animation start
      await tester.pump(const Duration(milliseconds: 500)); // complete flight animation
      await tester.pumpAndSettle();

      // Verify packed count increased: "1 / 4"
      expect(find.text('1 / 4'), findsOneWidget);

      // 2. Click packed card "身份证" -> Unpack
      await tester.tap(find.text('身份证'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // Remains unpacked
      expect(find.text('0 / 4'), findsOneWidget);
    });
  });
}
