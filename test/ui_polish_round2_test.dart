import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/features/forgot/record_forgot_sheet.dart';
import 'package:daiqi/features/onboarding/onboarding_screen.dart';
import 'package:daiqi/shared/widgets/brand_backpack_icon.dart';

import 'p1_710_helpers.dart';

void main() {
  group('Round 2 UI/UX Polish: Theme & Bottom Navigation', () {
    test('AppTheme configures charcoal ProgressIndicatorTheme', () {
      expect(
        AppTheme.lightTheme.progressIndicatorTheme.color,
        AppColors.primary,
      );
    });

    testWidgets('底栏在 320dp 窄屏 + 1.3x 大字号选中「遗忘记录」时无溢出', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      setView(tester, size: const Size(320, 640), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/forgot'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('遗忘记录'), findsWidgets);
    });
  });

  group('Round 2 UI/UX Polish: PackScreen 非 P0 区域打磨', () {
    testWidgets('装包页顶部「返回」与「编辑」胶囊热区高度 >= 48dp', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        3,
        name: '通勤包',
        nameOf: (i) => const ['钥匙', '手机', '工牌'][i],
      );

      await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final backHit = tester.getSize(
        find.ancestor(
          of: find.text('‹ 返回'),
          matching: find.byType(GestureDetector),
        ).first,
      );
      final editHit = tester.getSize(
        find.ancestor(
          of: find.text('编辑'),
          matching: find.byType(GestureDetector),
        ).first,
      );

      expect(backHit.height, greaterThanOrEqualTo(48));
      expect(editHit.height, greaterThanOrEqualTo(48));
    });

    testWidgets('全部跳过横幅在 320dp + 1.3x 大字号下不溢出，且「直接出门」为胶囊 StadiumBorder', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      setView(tester, size: const Size(320, 680), top: 24);

      final listId = await h.makeList(
        1,
        name: '单品包',
        nameOf: (_) => '雨伞',
      );
      final session = await h.sessionRepo.getOrCreateSession(listId);
      final items = await h.repo.getItemsForChecklist(listId);
      await h.sessionRepo.toggleSkipped(session.id, items.first.id);

      await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      expect(find.text('今天什么都不带吗？'), findsOneWidget);
      final departBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '直接出门'),
      );
      expect(departBtn.style?.shape?.resolve({}), isA<StadiumBorder>());
    });
  });

  group('Round 2 UI/UX Polish: ChecklistEditorScreen 打磨', () {
    testWidgets('名称字数计数实时更新、加号按钮动态高亮、提醒重复日摘要与 4 列图标网格', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/editor'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // Live character counter starts at 0/12
      expect(find.text('0/12'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.first, '短途差旅');
      await tester.pump();
      expect(find.text('4/12'), findsOneWidget);

      // Add-item '+' button reflects empty vs non-empty input state
      IconButton findAddBtn() => tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.add_rounded),
          matching: find.byType(IconButton),
        ).first,
      );
      expect(
        findAddBtn().style?.backgroundColor?.resolve({}),
        AppColors.primaryLight,
      );
      await tester.enterText(fields.at(1), '充电器');
      await tester.pump();
      expect(
        findAddBtn().style?.backgroundColor?.resolve({}),
        AppColors.primary,
      );

      // Open emoji picker -> 4-column GridView with BrandBackpackIcon
      await tester.tap(find.bySemanticsLabel('更换清单图标'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
      expect(find.byType(BrandBackpackIcon), findsWidgets);
      await tester.tap(find.text('💼'));
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      // Enable reminder switch -> shows '工作日' summary
      final reminderSwitch = find.byType(Switch).last;
      await tester.ensureVisible(reminderSwitch);
      await tester.tap(reminderSwitch);
      await pumpFrames(tester, total: const Duration(milliseconds: 300));
      expect(find.text('工作日'), findsOneWidget);
    });
  });

  group('Round 2 UI/UX Polish: ForgotScreen & RecordForgotSheet 打磨', () {
    testWidgets('记一笔弹窗禁用态提交按钮对比度 >= 4.5:1，无清单物品时展示输入引导', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

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
                        builder: (_) => const RecordForgotSheet(),
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

      expect(find.text('输入这次忘带的物品，下次会自动置顶提醒'), findsOneWidget);

      final submitBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '记下来，下次提醒我'),
      );
      expect(submitBtn.onPressed, isNull);
      final disabledBg = submitBtn.style?.backgroundColor?.resolve({WidgetState.disabled});
      final disabledFg = submitBtn.style?.foregroundColor?.resolve({WidgetState.disabled});
      expect(disabledBg, AppColors.secondaryBg);
      expect(disabledFg, AppColors.textSecondary);
      expect(contrast(disabledFg!, disabledBg!), greaterThanOrEqualTo(4.5));
    });

    testWidgets('遗忘记录页「记一笔」按钮热区 >= 48dp、排行榜显示「高危」徽章，320dp + 1.3x 无溢出', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      setView(tester, size: const Size(320, 720), top: 24);

      await h.makeList(2, name: '日常', highRisk: const ['蓝牙耳机']);

      await tester.pumpWidget(h.routerApp(initialLocation: '/forgot'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);
      final recordBtnSize = tester.getSize(
        find.widgetWithText(FilledButton, '记一笔'),
      );
      expect(recordBtnSize.height, greaterThanOrEqualTo(48));
      expect(find.text('高危'), findsOneWidget);
    });
  });

  group('Round 2 UI/UX Polish: Settings, Done & Onboarding 打磨', () {
    testWidgets('设置页展示 4 个分节标题与统一圆形图标徽章', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/settings'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('交互与反馈'), findsOneWidget);
      expect(find.text('通知与引导'), findsOneWidget);
      expect(find.text('数据管理'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);

      expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);
      expect(find.byIcon(Icons.motion_photos_off_outlined), findsOneWidget);
    });

    testWidgets('完成页「返回」胶囊在 1.3x 大字号下不换行、不拉伸占满整行', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      final listId = (await h.db.select(h.db.checklistLists).get()).first.id;
      final session = await h.sessionRepo.getOrCreateSession(listId);

      await tester.pumpWidget(
        h.routerApp(initialLocation: '/done/${session.id}?listId=$listId'),
      );
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      final backPillSize = tester.getSize(
        find.ancestor(
          of: find.text('‹ 返回'),
          matching: find.byType(Container),
        ).first,
      );
      expect(backPillSize.width, greaterThanOrEqualTo(76));
      expect(backPillSize.width, lessThan(200));
    });

    testWidgets('引导页「跳过」按钮在标准屏下热区高度 >= 48dp', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/onboarding'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.byType(OnboardingScreen), findsOneWidget);
      final skipHitSize = tester.getSize(
        find.ancestor(
          of: find.text('跳过'),
          matching: find.byType(GestureDetector),
        ).first,
      );
      expect(skipHitSize.height, greaterThanOrEqualTo(48));
    });
  });
}
