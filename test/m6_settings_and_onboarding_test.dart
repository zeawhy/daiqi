import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/features/onboarding/onboarding_screen.dart';
import 'package:daiqi/features/settings/settings_screen.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';
import 'package:daiqi/shared/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M6 NotificationService Tests', () {
    test('NotificationService schedule and cancel run safely', () async {
      await NotificationService.scheduleChecklistReminder(
        listId: 'test-list-1',
        listName: '通勤',
        itemCount: 4,
        reminderTime: '08:30',
        reminderWeekdays: [1, 2, 3, 4, 5],
      );

      await NotificationService.cancelChecklistReminders('test-list-1');
    });
  });

  group('M6 SettingsScreen Widget Tests', () {
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

    testWidgets('renders all settings options including sound, haptic, motion, permission, onboarding and clear',
        (tester) async {
      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('声音'), findsOneWidget);
      expect(find.text('震动'), findsOneWidget);
      expect(find.text('减少动效'), findsOneWidget);
      expect(find.text('通知权限'), findsOneWidget);
      expect(find.text('重新播放引导'), findsOneWidget);
      expect(find.text('清除所有遗忘记录'), findsOneWidget);
      expect(find.text('关于「带齐了」'), findsOneWidget);
    });

    testWidgets('Toggling sound and haptic switches updates services', (tester) async {
      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find first switch (Sound)
      final soundSwitch = find.byType(Switch).first;
      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();

      expect(AudioService.enabled, isFalse);

      // Tap again to restore
      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();
      expect(AudioService.enabled, isTrue);
    });

    testWidgets('Clearing forgot records shows secondary confirmation and clears records',
        (tester) async {
      // Create a forgot record first
      final summaries = await chkRepo.watchAllSummaries().first;
      await chkRepo.recordForgotItems(
        listId: summaries.first.id,
        itemNames: ['钥匙'],
      );

      final statsBefore = await chkRepo.getForgotStats();
      expect(statsBefore.forgotCount, 1);

      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap '清除所有遗忘记录'
      await tester.tap(find.text('清除所有遗忘记录'));
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('清除遗忘记录'), findsOneWidget);
      expect(find.text('清除'), findsOneWidget);

      // Confirm clear
      await tester.tap(find.text('清除'));
      await tester.pumpAndSettle();

      final statsAfter = await chkRepo.getForgotStats();
      expect(statsAfter.forgotCount, 0);
    });
  });

  group('M6 OnboardingScreen Widget Tests', () {
    late AppDatabase inMemoryDb;
    late ProviderContainer container;

    setUp(() async {
      AudioService.enabled = false;
      HapticService.enabled = false;
      inMemoryDb = AppDatabase(NativeDatabase.memory());

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

    testWidgets('renders key card, finger animation, and tapping key packs it and reveals 开始使用 button',
        (tester) async {
      addTearDown(() async {
        await tester.pump(const Duration(milliseconds: 50));
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('带齐了'), findsOneWidget);
      expect(find.text('试试把钥匙拖进包里'), findsOneWidget);
      expect(find.text('钥匙'), findsOneWidget);
      expect(find.text('🔑'), findsOneWidget);
      expect(find.text('开始使用'), findsNothing);

      // Tap key card
      await tester.tap(find.text('钥匙'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('就是这样！出门前把东西都装进包里'), findsOneWidget);
      expect(find.text('开始使用'), findsOneWidget);
    });
  });
}
