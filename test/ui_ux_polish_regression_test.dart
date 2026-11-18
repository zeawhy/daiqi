import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/features/forgot/record_forgot_sheet.dart';
import 'package:daiqi/features/onboarding/onboarding_screen.dart';
import 'package:daiqi/shared/widgets/brand_backpack_icon.dart';

import 'p1_710_helpers.dart';

void main() {
  group('1. PackScreen UX 修复回归 (空清单快捷加项 & 删除撤销)', () {
    testWidgets('空清单点击快捷物品仅加入当前清单，不重复创建新清单', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.repo.createChecklist(
        name: '空周末包',
        emoji: '🎒',
        items: const [],
      );

      await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('先往清单里加点东西'), findsOneWidget);

      // Tap first ActionChip in empty state
      final firstChip = find.byType(ActionChip).first;
      await tester.tap(firstChip);
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final allLists = await h.db.select(h.db.checklistLists).get();
      expect(allLists.where((l) => l.name == '空周末包').length, 1);
      final items = await h.repo.getItemsForChecklist(listId);
      expect(items.length, 1);
    });

    testWidgets('装包页长按从清单删除物品后显示撤销提示，点撤销可恢复', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        2,
        name: '短途包',
        nameOf: (i) => const ['充电宝', '耳机'][i],
      );

      await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('充电宝'), findsOneWidget);

      await tester.longPress(find.text('充电宝'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      expect(find.text('从清单删除'), findsOneWidget);
      await tester.tap(find.text('从清单删除'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('已从清单移除「充电宝」'), findsOneWidget);
      expect(find.text('充电宝'), findsNothing);

      await tester.tap(find.text('撤销'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('充电宝'), findsOneWidget);
    });
  });

  group('2. ChecklistEditorScreen UX 修复回归 (提醒星期保留、未保存守卫、待输入自动提交与移除撤销)', () {
    testWidgets('编辑已有清单时保留自定义提醒重复日（如周六、周日），保存后不丢失', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        2,
        name: '周末徒步',
        reminderEnabled: true,
        reminderTime: '07:30',
        reminderWeekdays: const [6, 7],
      );

      await tester.pumpWidget(h.routerApp(initialLocation: '/editor/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // Tap 保存 directly without touching weekdays
      await tester.tap(find.text('保存'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final updated = await h.repo.getChecklist(listId);
      final weekdays =
          (jsonDecode(updated!.reminderWeekdays!) as List).cast<int>();
      expect(weekdays, const [6, 7]);
    });

    testWidgets('未保存修改拦截返回弹窗；输入框未按加号直接点保存自动提交待加物品', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      await tester.tap(find.text('新建专属清单'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // Enter checklist name and type an item WITHOUT pressing '+'
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, '差旅包');
      await tester.enterText(textFields.at(1), '护手霜');
      await tester.pump();

      // Tap AppBar BackButton -> PopScope intercepts and shows unsaved changes dialog
      await tester.tap(find.byType(BackButton));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      expect(find.text('放弃未保存的修改？'), findsOneWidget);
      await tester.tap(find.text('继续编辑'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      // Now tap 保存 -> pending item '护手霜' is auto-committed!
      await tester.tap(find.text('保存'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final allLists = await h.db.select(h.db.checklistLists).get();
      final created = allLists.firstWhere((s) => s.name == '差旅包');
      final createdItems = await h.repo.getItemsForChecklist(created.id);
      expect(createdItems.map((i) => i.name), contains('护手霜'));
    });

    testWidgets('编辑页点击移除按钮后弹出撤销提示，点撤销恢复原物品', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        2,
        name: '通勤包',
        nameOf: (i) => const ['工牌', '雨伞'][i],
      );

      await tester.pumpWidget(h.routerApp(initialLocation: '/editor/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      await tester.tap(find.byTooltip('移除 工牌'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      expect(find.text('已移除「工牌」'), findsOneWidget);
      expect(find.text('工牌'), findsNothing);

      await tester.tap(find.text('撤销'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      expect(find.text('工牌'), findsOneWidget);
    });
  });

  group('3. HomeScreen 与底栏 UX 打磨回归', () {
    testWidgets('Hero 主卡超过 4 件物品时显示 +N 溢出提示；管理菜单复制与删除均有反馈', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        6,
        name: '露营装备',
        nameOf: (i) => ['帐篷', '睡袋', '头灯', '水壶', '防潮垫', '登山杖'][i],
      );
      // Make it the active hero card
      await h.sessionRepo.getOrCreateSession(listId);

      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // 6 items -> shows 4 items + '+2' badge
      expect(find.text('+2'), findsOneWidget);

      // Open management menu via ⋯ button and duplicate
      await tester.tap(find.byKey(ValueKey('checklist_more_$listId')));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));
      await tester.tap(find.text('复制'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('已复制「露营装备」'), findsOneWidget);

      // Delete the duplicated list and verify feedback snackbar
      final listsAfterCopy = await h.db.select(h.db.checklistLists).get();
      final copyList = listsAfterCopy.firstWhere((l) => l.id != listId);
      await tester.tap(find.byKey(ValueKey('checklist_more_${copyList.id}')));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));
      await tester.tap(find.text('删除'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('已删除「${copyList.name}」'), findsOneWidget);
    });
  });

  group('4. ForgotScreen 与 RecordForgotSheet UX 打磨回归', () {
    testWidgets('跨 Tab 实时刷新：在设置页清除遗忘记录后切回遗忘记录 Tab 立即更新为空状态', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(2, name: '日常', highRisk: const ['钥匙']);

      await tester.pumpWidget(h.routerApp(initialLocation: '/forgot'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(listId, isNotEmpty);
      expect(find.text('忘了 钥匙'), findsOneWidget);
      expect(find.text('左滑可删除'), findsOneWidget);

      // Switch to 设置 tab via bottom nav
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      await tester.tap(find.text('清除所有遗忘记录'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));
      await tester.tap(find.text('清除'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // Switch back to 遗忘记录 tab -> IndexedStack ForgotScreen has live-updated!
      await tester.tap(find.byIcon(Icons.history_toggle_off_rounded));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('忘了 钥匙'), findsNothing);
      expect(find.text('还没有忘过东西，继续保持 👍'), findsOneWidget);
    });

    testWidgets('遗忘记录排行与时间线对 🎒 物品统一拦截为 BrandBackpackIcon', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.repo.createChecklist(
        name: '背囊测试',
        emoji: '🎒',
        items: const [(name: '备用包', emoji: '🎒')],
      );
      await h.repo.recordForgotItems(listId: listId, itemNames: const ['备用包']);

      await tester.pumpWidget(h.routerApp(initialLocation: '/forgot'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // Ranking & Timeline both render BrandBackpackIcon instead of Text('🎒')
      expect(find.text('忘了 备用包'), findsOneWidget);
      expect(find.text('🎒'), findsNothing);
      expect(find.byType(BrandBackpackIcon), findsWidgets);
    });

    testWidgets('记一笔弹窗拦截 🎒 为 BrandBackpackIcon；输入清单外物品无需先按加号即可直接提交',
        (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.repo.createChecklist(
        name: '背囊测试',
        emoji: '🎒',
        items: const [(name: '备用包', emoji: '🎒')],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: ctx,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => RecordForgotSheet(listId: listId),
                      );
                    },
                    child: const Text('打开弹窗'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await pumpFrames(tester, total: const Duration(milliseconds: 200));
      await tester.tap(find.text('打开弹窗'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      // Chip for '备用包' intercepts 🎒 -> no raw Text('🎒')
      expect(find.text('备用包'), findsOneWidget);
      expect(find.text('🎒'), findsNothing);
      expect(find.byType(BrandBackpackIcon), findsOneWidget);

      // Type outside item '遮阳帽' WITHOUT pressing '+' -> save button enables immediately!
      await tester.enterText(find.byType(TextField), '遮阳帽');
      await pumpFrames(tester, total: const Duration(milliseconds: 250));

      expect(find.text('将清单外的物品加入「背囊测试」'), findsOneWidget);
      final submitBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '记下来，下次提醒我'),
      );
      expect(submitBtn.onPressed, isNotNull);

      await tester.tap(find.text('记下来，下次提醒我'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final itemsAfter = await h.repo.getItemsForChecklist(listId);
      expect(itemsAfter.map((e) => e.name), contains('遮阳帽'));
    });
  });

  group('5. OnboardingScreen 与 DoneScreen 打磨回归', () {
    testWidgets('引导页标题符合 Santorini L1 规范，320x480 小屏不溢出且支持点击「跳过」', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(320, 480), top: 20);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/onboarding'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);

      final title = tester.widget<Text>(
        find.descendant(
          of: find.byType(OnboardingScreen),
          matching: find.text('带齐了'),
        ),
      );
      expect(title.style?.fontSize, 28);
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(title.style?.letterSpacing, 1.0);

      expect(find.text('跳过'), findsOneWidget);
      await tester.tap(find.text('跳过'));
      await pumpFrames(tester, total: const Duration(milliseconds: 500));

      // Navigated away from OnboardingScreen to HomeScreen
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byKey(const ValueKey('home_masthead_backdrop')), findsOneWidget);
    });

    testWidgets('完成页返回与记一笔热区 >= 48dp，减少动效开启时点出门无空白等待直达首页', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      final allLists = await h.db.select(h.db.checklistLists).get();
      final listId = allLists.first.id;
      final session = await h.sessionRepo.getOrCreateSession(listId);

      await tester.pumpWidget(
        h.routerApp(initialLocation: '/done/${session.id}?listId=$listId'),
      );
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      final backHitBox = tester.getSize(
        find.ancestor(
          of: find.text('‹ 返回'),
          matching: find.byType(GestureDetector),
        ).first,
      );
      expect(backHitBox.height, greaterThanOrEqualTo(48));

      final forgotLinkHitBox = tester.getSize(
        find.ancestor(
          of: find.textContaining('还是忘了东西？记一笔'),
          matching: find.byType(GestureDetector),
        ).first,
      );
      expect(forgotLinkHitBox.height, greaterThanOrEqualTo(48));

      // With reducedMotion: true, tapping 出门 🚪 completes immediately in a single pump cycle
      await tester.tap(find.text('出门 🚪'));
      await pumpFrames(tester, total: const Duration(milliseconds: 100));

      final updated = await h.sessionRepo.getSessionById(session.id);
      expect(updated?.status, 'departed');
    });
  });
}
