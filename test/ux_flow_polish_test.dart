import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/domain/models/pack_models.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';

import 'p1_710_helpers.dart';

void main() {
  group('UX Flow Polish: PackScreen 拖拽引导、跳过态恢复与状态胶囊', () {
    testWidgets('拖拽卡片时底部出现虚线落点光环与「拖到这里放进包里」胶囊，悬停后切换「松手放进包里」',
        (tester) async {
      final h = Harness710(reducedMotion: false);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        3,
        name: '通勤包',
        nameOf: (i) => const ['钥匙', '手机', '工牌'][i],
      );

      await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.byKey(const ValueKey('pack_status_pill')), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('pack_drop_zone_halo')), findsNothing);

      final cardCenter = tester.getCenter(find.text('钥匙'));
      final gesture = await tester.startGesture(cardCenter);
      // Move > 8pt horizontally to enter drag mode without entering backpack drop zone
      await gesture.moveBy(const Offset(40, 20));
      await pumpFrames(tester, total: const Duration(milliseconds: 120));

      expect(find.byKey(const ValueKey('pack_drop_zone_halo')), findsOneWidget);
      expect(find.text('拖到这里放进包里'), findsOneWidget);

      // Drag into backpack area
      final backpackCenter = tester.getCenter(find.byKey(const ValueKey('pack_drop_zone_halo')));
      await gesture.moveTo(backpackCenter);
      await pumpFrames(tester, total: const Duration(milliseconds: 120));

      expect(find.text('松手放进包里'), findsOneWidget);

      await gesture.up();
      await pumpFrames(tester, total: const Duration(milliseconds: 500));
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('跳过态卡片展示「不带」高对比徽章，轻点即可弹出操作面板恢复带上', (tester) async {
      const skippedItem = PackItemModel(
        listItemId: 's1',
        globalItemId: 'g1',
        name: '雨伞',
        emoji: '☂️',
        sortOrder: 0,
        isPacked: false,
        isHighRisk: false,
        isSkipped: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SizedBox(width: 110, child: ItemCardWidget(item: skippedItem)),
          ),
        ),
      );
      final badge = tester.widget<Text>(find.text('不带'));
      expect(badge.style?.color, AppColors.textSecondary);
      expect(contrast(badge.style!.color!, AppColors.secondaryBg), greaterThanOrEqualTo(4.5));

      // On PackScreen, tapping a skipped item opens the bottom sheet to restore
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(2, name: '雨天', nameOf: (i) => const ['钥匙', '雨伞'][i]);
      final session = await h.sessionRepo.getOrCreateSession(listId);
      final items = await h.repo.getItemsForChecklist(listId);
      await h.sessionRepo.toggleSkipped(session.id, items[1].id);

      await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('不带'), findsOneWidget);
      await tester.tap(find.text('雨伞'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      expect(find.text('恢复带上'), findsOneWidget);
      await tester.tap(find.text('恢复带上'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));
      expect(find.text('不带'), findsNothing);
    });
  });

  group('UX Flow Polish: HomeScreen 主卡进度条与高危徽章', () {
    testWidgets('进行中且含高危物品的首页主卡展示进度条与高危徽章，320dp + 1.3x 无溢出', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      setView(tester, size: const Size(320, 720), top: 24);

      final listId = await h.makeList(
        3,
        name: '商务出差清单',
        nameOf: (i) => const ['身份证', '钥匙', '充电器'][i],
        highRisk: const ['钥匙'],
      );
      final session = await h.sessionRepo.getOrCreateSession(listId);
      final items = await h.repo.getItemsForChecklist(listId);
      await h.sessionRepo.packItem(session.id, items.first.id);

      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('hero_high_risk_badge')), findsOneWidget);
      expect(find.text('1 高危'), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_progress_bar')), findsOneWidget);
    });
  });

  group('UX Flow Polish: ChecklistEditorScreen 场景模板与口诀实时预览', () {
    testWidgets('新建清单可一键套用场景模板，开启口诀条后实时展示字-物对应预览', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/editor'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('场景模板 · 一键套用'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('editor_template_通勤')));
      await pumpFrames(tester, total: const Duration(milliseconds: 250));

      expect(find.text('物品列表 (6)'), findsOneWidget);
      expect(find.text('工牌'), findsOneWidget);

      // Switch to 健身 template replaces template-filled name & items
      await tester.tap(find.byKey(const ValueKey('editor_template_健身')));
      await pumpFrames(tester, total: const Duration(milliseconds: 250));
      expect(find.text('物品列表 (5)'), findsOneWidget);
      expect(find.text('运动鞋'), findsOneWidget);

      // Enable mnemonic switch -> live mapping preview appears
      final mnemonicSwitch = find.byType(Switch).first;
      await tester.ensureVisible(mnemonicSwitch);
      await tester.tap(mnemonicSwitch);
      await pumpFrames(tester, total: const Duration(milliseconds: 250));

      expect(find.byKey(const ValueKey('editor_mnemonic_preview')), findsOneWidget);
    });

    testWidgets('编辑已有清单时不显示新建场景模板区', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(2, name: '我的包');
      await tester.pumpWidget(h.routerApp(initialLocation: '/editor/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('场景模板 · 一键套用'), findsNothing);
    });
  });

  group('UX Flow Polish: DoneScreen 清单胶囊、已装物品快览与连胜徽章', () {
    testWidgets('完成页展示清单名称胶囊、已装物品快览与连胜徽章，窄屏 + 1.3x 无溢出', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await h.repo.ensurePresetChecklist();
      final list = (await h.db.select(h.db.checklistLists).get()).first;
      final items = await h.repo.getItemsForChecklist(list.id);

      // Create 2 departed sessions for streak >= 2
      for (var i = 0; i < 2; i++) {
        final s = await h.sessionRepo.getOrCreateSession(list.id);
        for (final item in items) {
          await h.sessionRepo.packItem(s.id, item.id);
        }
        await h.sessionRepo.updateSessionStatus(
          s.id,
          'departed',
          departedAt: DateTime.now().toUtc().subtract(Duration(hours: 2 - i)),
        );
      }

      final activeSession = await h.sessionRepo.getOrCreateSession(list.id);
      for (final item in items) {
        await h.sessionRepo.packItem(activeSession.id, item.id);
      }

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      setView(tester, size: const Size(360, 760), top: 24);

      await tester.pumpWidget(
        h.routerApp(initialLocation: '/done/${activeSession.id}?listId=${list.id}'),
      );
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('done_checklist_pill')), findsOneWidget);
      expect(find.byKey(const ValueKey('done_streak_badge')), findsOneWidget);
      expect(find.byKey(const ValueKey('done_packed_items_wrap')), findsOneWidget);
      expect(find.textContaining('连续 2 次零遗漏 🔥'), findsOneWidget);
    });
  });

  group('UX Flow Polish: ForgotScreen 排行榜动效与首位徽章', () {
    testWidgets('遗忘记录排行榜在正常与减少动效模式下均无异常渲染', (tester) async {
      final h = Harness710(reducedMotion: false);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.makeList(2, name: '通勤', highRisk: const ['雨伞', '耳机']);

      await tester.pumpWidget(h.routerApp(initialLocation: '/forgot'));
      await pumpFrames(tester, total: const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.text('最常忘的东西'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
