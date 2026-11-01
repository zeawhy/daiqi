import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:go_router/go_router.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/app/theme.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/domain/models/pack_models.dart';
import 'package:daiqi/features/done/done_screen.dart';
import 'package:daiqi/features/editor/checklist_editor_screen.dart';
import 'package:daiqi/features/pack/backpack_widget.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/l10n/app_localizations.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AudioService.enabled = false;
    HapticService.enabled = false;
  });

  group('Milestone 7: Edge Cases and Polish Tests', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;
    bool dbClosed = false;

    setUp(() {
      inMemoryDb = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
        ],
      );
      dbClosed = false;
    });

    tearDown(() async {
      container.dispose();
      if (!dbClosed) {
        await inMemoryDb.close();
        dbClosed = true;
      }
    });

    Widget createTestApp(Widget child, {GoRouter? router}) {
      if (router != null) {
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
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets('Single-item checklist edge case: packing item navigates to DoneScreen',
        (WidgetTester tester) async {
      final checklistRepo = container.read(checklistRepositoryProvider);
      final listId = await checklistRepo.createChecklist(
        name: '单件清单',
        emoji: '🔑',
        items: [
          (name: '唯独钥匙', emoji: '🔑'),
        ],
      );

      final router = GoRouter(
        initialLocation: '/pack/$listId',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HomeScreen'))),
          GoRoute(
            path: '/pack/:id',
            builder: (context, state) => PackScreen(checklistId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/done/:sessionId',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              final lid = state.uri.queryParameters['listId'] ?? '';
              return DoneScreen(sessionId: sessionId, listId: lid);
            },
          ),
        ],
      );

      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SizedBox.shrink(), router: router));
      await tester.pumpAndSettle();

      expect(find.text('唯独钥匙'), findsOneWidget);
      expect(find.text('0 / 1'), findsOneWidget);

      
      // Tap single item to pack
      await tester.tap(find.text('唯独钥匙'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle();

      // Should be on DoneScreen with "出门 🚪" button
      expect(find.text('出门 🚪'), findsOneWidget);
      expect(find.text('全部带齐，出门吧！'), findsOneWidget);
    });

    testWidgets('Over 15 items checklist: renders cleanly with scrollable grid',
        (WidgetTester tester) async {
      final checklistRepo = container.read(checklistRepositoryProvider);
      final manyItems = List.generate(
        18,
        (i) => (name: '物品${i + 1}', emoji: '📦'),
      );

      final listId = await checklistRepo.createChecklist(
        name: '长清单',
        emoji: '📋',
        items: manyItems,
      );

      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(PackScreen(checklistId: listId)));
      await tester.pumpAndSettle();

      expect(find.text('0 / 18'), findsOneWidget);
      expect(find.text('物品1'), findsOneWidget);

      // Verify grid is scrollable
      final scrollableFinder = find.byType(SingleChildScrollView);
      expect(scrollableFinder, findsOneWidget);

      // Drag to scroll down
      await tester.drag(scrollableFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Items further down should be visible
      expect(find.text('物品18'), findsOneWidget);
      // Backpack and progress area remains visible at bottom
      expect(find.text('0 / 18'), findsOneWidget);
    });

    testWidgets('Long item name renders cleanly in ItemCardWidget without overflow',
        (WidgetTester tester) async {
      const longNameItem = PackItemModel(
        listItemId: 'item-long',
        globalItemId: 'g-long',
        name: '这是一张名字非常非常非常非常非常非常长的卡片测试',
        emoji: '🏷️',
        sortOrder: 0,
        isPacked: false,
        isHighRisk: false,
        isSkipped: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 86,
                child: ItemCardWidget(item: longNameItem),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('这是一张名字非常非常非常非常非常非常长的卡片测试'), findsOneWidget);
      expect(find.text('🏷️'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Duplicate item addition rejection in ChecklistEditorScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const ChecklistEditorScreen()));
      await tester.pumpAndSettle();

      // Add item "雨伞"
      final inputFinder = find.byType(TextField).last;
      await tester.enterText(inputFinder, '雨伞');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('雨伞'), findsOneWidget);

      // Try adding duplicate "雨伞"
      await tester.enterText(inputFinder, '雨伞');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should show SnackBar "清单里已经有 雨伞 了"
      expect(find.text('清单里已经有 雨伞 了'), findsOneWidget);
    });

    testWidgets('All skipped items triggers "今天什么都不带吗？" with "直接出门"',
        (WidgetTester tester) async {
      final checklistRepo = container.read(checklistRepositoryProvider);
      final listId = await checklistRepo.createChecklist(
        name: '不带清单',
        emoji: '🧳',
        items: [
          (name: '随身物品', emoji: '📱'),
        ],
      );

      final router = GoRouter(
        initialLocation: '/pack/$listId',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HomeScreen'))),
          GoRoute(
            path: '/pack/:id',
            builder: (context, state) => PackScreen(checklistId: state.pathParameters['id']!),
          ),
        ],
      );

      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(const SizedBox.shrink(), router: router));
      await tester.pumpAndSettle();

      // Long press item to skip
      await tester.longPress(find.text('随身物品'));
      await tester.pumpAndSettle();

      // Tap "今天不带"
      expect(find.text('今天不带'), findsOneWidget);
      await tester.tap(find.text('今天不带'));
      await tester.pumpAndSettle();

      // Empty prompt should appear
      expect(find.text('今天什么都不带吗？'), findsOneWidget);
      expect(find.text('直接出门'), findsOneWidget);

      // Tap "直接出门"
      await tester.tap(find.text('直接出门'));
      await tester.pumpAndSettle();

      // Navigated to HomeScreen
      expect(find.text('HomeScreen'), findsOneWidget);
    });

    testWidgets('BackpackWidget respects reducedMotion mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BackpackWidget(
                progress: 0.5,
                reducedMotion: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackpackWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
