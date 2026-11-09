import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/shared/widgets/mini_backpack.dart';

import 'p1_710_helpers.dart';

void main() {
  group('Task 1 Regression: 首页会话卡片进度与剩余件数实时刷新', () {
    testWidgets(
      '从首页进入装包页装 N 件后点“稍后再装”返回首页，顶部主卡徽章百分比、按钮剩余件数与迷你背包进度均实时更新',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(400, 850), top: 24);

        await h.repo.ensurePresetChecklist();
        await h.makeList(
          7,
          name: '16798',
          emoji: '🎒',
          nameOf: (i) => const ['耳机', '钱包', '身份证', '水杯', '钥匙', '纸巾', '充电宝'][i],
        );

        // 1) 先渲染首页（此时 allChecklistsStreamProvider 已开始监听）
        await tester.pumpWidget(h.routerApp(initialLocation: '/'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        expect(find.text('16798'), findsOneWidget);
        expect(find.text('共 7 件'), findsOneWidget);

        // 2) 从首页点击“16798”进入装包页
        await tester.tap(find.text('16798'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        expect(find.text('0 / 7'), findsOneWidget);

        // 3) 依次点击装入 3 件物品（耳机、钱包、身份证 -> 3 / 7 ≈ 43%，还差 4 件）
        for (final itemName in const ['耳机', '钱包', '身份证']) {
          await tester.tap(find.text(itemName));
          await pumpFrames(tester, total: const Duration(milliseconds: 300));
        }
        expect(find.text('3 / 7'), findsOneWidget);

        // 4) 点击“‹ 返回” -> 弹窗点“稍后再装”回到首页
        await tester.tap(find.text('‹ 返回'));
        await pumpFrames(tester, total: const Duration(milliseconds: 200));
        expect(find.text('稍后再装'), findsOneWidget);

        await tester.tap(find.text('稍后再装'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        // 5) 断言首页顶部会话主卡徽章与按钮文案已实时刷新（不再停留在 0% 和还差 7 件）
        expect(find.text('进行中 · 已装 43%'), findsOneWidget);
        expect(find.text('进行中 · 已装 0%'), findsNothing);
        expect(find.text('继续装包（还差 4 件）'), findsOneWidget);
        expect(find.text('继续装包（还差 7 件）'), findsNothing);

        final miniBackpack = tester.widget<MiniBackpack>(find.byType(MiniBackpack).first);
        expect(miniBackpack.progress, closeTo(3 / 7, 0.001));
      },
    );

    testWidgets(
      '装包页中跳过物品（今天不带）或编辑清单后返回首页，已装状态不丢失且百分比与剩余件数口径一致',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(400, 850), top: 24);

        await h.repo.ensurePresetChecklist();
        final listId = await h.makeList(
          5,
          name: '差旅包',
          emoji: '🧳',
          nameOf: (i) => const ['护照', '机票', '充电器', '雨伞', '外套'][i],
        );

        await tester.pumpWidget(h.routerApp(initialLocation: '/'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        // 进入“差旅包”装包页
        await tester.tap(find.text('差旅包'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        // 装入 2 件（护照、机票）
        await tester.tap(find.text('护照'));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        await tester.tap(find.text('机票'));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        expect(find.text('2 / 5'), findsOneWidget);

        // 长按“雨伞”标记为“今天不带”（有效总数变为 4，已装 2 -> 50%，还差 2 件）
        await tester.longPress(find.text('雨伞'));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        await tester.tap(find.text('今天不带'));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        expect(find.text('2 / 4'), findsOneWidget);

        // 在会话进行中调用 updateChecklist（模拟编辑清单新增 1 件物品“洗漱包”，移除“外套”）
        await h.repo.updateChecklist(
          listId: listId,
          name: '差旅包',
          emoji: '🧳',
          items: const [
            (name: '护照', emoji: '🛂'),
            (name: '机票', emoji: '🎫'),
            (name: '充电器', emoji: '🔌'),
            (name: '雨伞', emoji: '☂️'),
            (name: '洗漱包', emoji: '🧴'),
          ],
        );
        await pumpFrames(tester, total: const Duration(milliseconds: 300));

        // 已装的 2 件与跳过的 1 件状态均保留，仍为 2 / 4
        expect(find.text('2 / 4'), findsOneWidget);

        // 返回首页
        await tester.tap(find.text('‹ 返回'));
        await pumpFrames(tester, total: const Duration(milliseconds: 200));
        await tester.tap(find.text('稍后再装'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        expect(find.text('进行中 · 已装 50%'), findsOneWidget);
        expect(find.text('继续装包（还差 2 件）'), findsOneWidget);
      },
    );
  });

  group('Task 2 Regression: 设置页与编辑页 Switch 开启/关闭态拇指与轨道高对比可见', () {
    testWidgets(
      'SettingsScreen 三档开关与 ChecklistEditorScreen 两档开关在开启/关闭态下拇指与轨道颜色对比度均清晰可见',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(400, 850), top: 24);

        await h.repo.ensurePresetChecklist();
        await tester.pumpWidget(h.routerApp(initialLocation: '/settings'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        expect(switches.length, equals(3));

        final BuildContext ctx = tester.element(find.byType(Switch).first);
        final switchTheme = Theme.of(ctx).switchTheme;

        for (final sw in switches) {
          // Widget 本身不得再用 AppColors.primary 覆盖 activeThumbColor
          expect(sw.activeThumbColor, isNot(equals(AppColors.primary)));

          final selectedStates = <WidgetState>{WidgetState.selected};
          final unselectedStates = <WidgetState>{};

          final selectedThumb = sw.thumbColor?.resolve(selectedStates) ??
              sw.activeThumbColor ??
              switchTheme.thumbColor!.resolve(selectedStates)!;
          final selectedTrack = sw.trackColor?.resolve(selectedStates) ??
              sw.activeTrackColor ??
              switchTheme.trackColor!.resolve(selectedStates)!;

          final unselectedThumb = sw.thumbColor?.resolve(unselectedStates) ??
              sw.inactiveThumbColor ??
              switchTheme.thumbColor!.resolve(unselectedStates)!;
          final unselectedTrack = sw.trackColor?.resolve(unselectedStates) ??
              sw.inactiveTrackColor ??
              switchTheme.trackColor!.resolve(unselectedStates)!;

          // 开启态：白色拇指 (#FFFFFF) 落在炭黑轨道 (#262626) 上，对比度 >= 4.5:1
          expect(selectedThumb, equals(Colors.white));
          expect(selectedTrack, equals(AppColors.primary));
          expect(contrast(selectedThumb, selectedTrack), greaterThanOrEqualTo(4.5));

          // 关闭态：石色拇指 (#57534E) 落在浅暖灰轨道 (#EEEEEC) 上，对比度 >= 4.5:1
          expect(unselectedThumb, equals(AppColors.textSecondary));
          expect(unselectedTrack, equals(AppColors.secondaryBg));
          expect(contrast(unselectedThumb, unselectedTrack), greaterThanOrEqualTo(4.5));
        }

        // 检查 ChecklistEditorScreen 中的两个 Switch（口诀条、定时提醒）同样无炭黑拇指覆盖
        await tester.pumpWidget(h.routerApp(initialLocation: '/editor'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        final editorSwitches = tester.widgetList<Switch>(find.byType(Switch)).toList();
        expect(editorSwitches.length, equals(2));
        for (final sw in editorSwitches) {
          expect(sw.activeThumbColor, isNot(equals(AppColors.primary)));
        }
      },
    );
  });
}
