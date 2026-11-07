// P1 #4 / #5 / #6 复现与验证测试（红 → 绿）。
// 用法：将本目录下 p1_helpers.dart 与本文件拷入 daiqi/test/，执行：
//   flutter test test/pack_p1_456_repro_test.dart --reporter expanded
//
// 修复前（main @ 54ba305）：
//   - T4a, T4b, T4c, T4d, T5a, T5b, T6a, T6b 均 FAIL（红），复现全部缺陷；
//   - T4e, T5c 为 P0 坐标与排序不回归保护，修复前后均 PASS（绿）。
// 修复后：全部 10 条用例 PASS（绿）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/features/pack/backpack_widget.dart';

import 'p1_helpers.dart';

void main() {
  group('P1 #4: 背包自适应高度、极小屏/横屏防溢出与自动滚动线性调速', () {
    testWidgets('T4a (红→绿): 360x640 小屏 12 件物品时，背包缩为小号且网格至少完整显示 3 行',
        (tester) async {
      final h = Harness();
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(360, 640), top: 24);
      final id = await h.makeList(12);

      await tester.pumpWidget(h.app(id));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      final bpWidget = tester.widget<BackpackWidget>(find.byType(BackpackWidget));
      final bpArea = backpackAreaRect(tester);
      final gridRect = gridViewportRect(tester);

      // 物品 > 6 件时缩为小号背包（高 140..165），背包区总高 <= 190dp（旧值 269dp）
      expect(bpWidget.height, inInclusiveRange(140.0, 165.0));
      expect(bpArea.height, lessThanOrEqualTo(190.0));

      // 3 行卡片需 3 * 86 + 2 * 10 + 16 (上下 padding) = 294dp（旧值仅 233dp = 2 行）
      expect(gridRect.height, greaterThanOrEqualTo(294.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('T4b (红→绿): 物品 <= 6 件时大屏保持 220 大背包，360x640 小屏自适应且 4 件带口诀完整露出 2 行',
        (tester) async {
      // 1) 360x640 小屏 + 4 件带口诀
      final h1 = Harness();
      addTearDown(() => h1.dispose(tester));
      setView(tester, size: const Size(360, 640), top: 24);
      final id1 = await h1.makeList(4, mnemonic: '身手钥钱');

      await tester.pumpWidget(h1.app(id1));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      final bpSmall = tester.widget<BackpackWidget>(find.byType(BackpackWidget));
      final gridSmall = gridViewportRect(tester);
      // 360x640 (availH=616) 下 clamp(616*0.30, 140, 220) = 184.8，使 2 行卡片 (198dp) 完整显示（旧值仅 164.6dp）
      expect(bpSmall.height, inInclusiveRange(140.0, 200.0));
      expect(gridSmall.height, greaterThanOrEqualTo(198.0));

      // 2) 400x850 大屏 + 4 件带口诀：保持 220dp 大背包
      setView(tester, size: const Size(400, 850), top: 40);
      await tester.pumpWidget(h1.app(id1));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      final bpLarge = tester.widget<BackpackWidget>(find.byType(BackpackWidget));
      expect(bpLarge.height, equals(220.0));
    });

    for (final (label, size, top, n) in <(String, Size, double, int)>[
      ('320x480 n=0', const Size(320, 480), 24, 0),
      ('320x480 n=4', const Size(320, 480), 24, 4),
      ('800x360 n=0', const Size(800, 360), 0, 0),
      ('800x360 n=1', const Size(800, 360), 0, 1),
      ('800x360 n=4', const Size(800, 360), 0, 4),
      ('800x360 n=12', const Size(800, 360), 0, 12),
    ]) {
      testWidgets('T4c (红→绿): 极小屏/横屏无 RenderFlex overflow [$label]',
          (tester) async {
        final h = Harness();
        addTearDown(() => h.dispose(tester));
        setView(tester, size: size, top: top);
        final id = await h.makeList(n, mnemonic: n == 4 ? '一二三四' : null);
        await tester.pumpWidget(h.app(id));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Expected no overflow at $label',
        );
      });
    }

    testWidgets('T4d (红→绿): 拖拽自动滚动按距离边缘远近线性调速（浅边缘慢、深边缘快）',
        (tester) async {
      final h = Harness();
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 40);
      final id = await h.makeList(24);

      await tester.pumpWidget(h.app(id));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      final scrollFinder = find.byType(SingleChildScrollView).first;
      final scrollable = tester.widget<SingleChildScrollView>(scrollFinder);
      final controller = scrollable.controller!;
      final gridRect = tester.getRect(scrollFinder);

      // 从第一张卡中心起拖，横向移到网格右侧安全区（避开垂直自然滚动手势）
      final start = tester.getCenter(find.text('物品1'));
      final g = await tester.startGesture(start);
      await g.moveBy(const Offset(12, 0));
      await tester.pump();
      expect(draggedCard, findsOneWidget);

      // 1) 移到距网格底边 50pt 处（刚进 60pt 阈值区，深度 t = 10/60）
      final shallowY = gridRect.bottom - 50.0;
      await g.moveTo(Offset(gridRect.center.dx, shallowY));
      await tester.pump();
      final offset0 = controller.offset;
      await g.moveBy(const Offset(1, 0));
      await tester.pump();
      final shallowDelta = controller.offset - offset0;

      // 2) 移到距网格底边 5pt 处（贴近底边，深度 t = 55/60）
      final deepY = gridRect.bottom - 5.0;
      await g.moveTo(Offset(gridRect.center.dx, deepY));
      await tester.pump();
      final offset1 = controller.offset;
      await g.moveBy(const Offset(1, 0));
      await tester.pump();
      final deepDelta = controller.offset - offset1;

      await g.up();
      await pumpFrames(tester, total: const Duration(milliseconds: 500));

      // 修复前 shallowDelta == 15.0 且 deepDelta == 15.0；修复后浅边缘 < 6.0，深边缘 > 14.0
      expect(shallowDelta, greaterThan(0.0));
      expect(shallowDelta, lessThan(6.5));
      expect(deepDelta, greaterThan(14.0));
      expect(deepDelta, greaterThan(shallowDelta * 2.5));
    });

    testWidgets('T4e (P0 坐标不回归): 小号背包下拖拽跟随、点击飞入背包口、包外飞回坐标均精确对齐',
        (tester) async {
      final h = Harness();
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(360, 640), top: 24);
      final id = await h.makeList(12);

      await tester.pumpWidget(h.app(id));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      // 1) 拖拽浮卡中心 == 指针位置
      final start = tester.getCenter(find.text('物品1'));
      final g = await tester.startGesture(start);
      await g.moveBy(const Offset(0, 15));
      await tester.pump();
      await g.moveBy(const Offset(30, 45));
      await tester.pump();
      final pointer = start + const Offset(30, 60);
      final floatingCenter = tester.getRect(draggedCard).center;
      expect((floatingCenter - pointer).distance, lessThan(1.0));

      // 2) 松手飞回卡槽中心
      await g.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 279));
      final flybackEndCenter = tester.getRect(draggedCard).center;
      await pumpFrames(tester, total: const Duration(milliseconds: 100));
      final realSlotCenter = slotRect(tester, '物品1').center;
      expect((flybackEndCenter - realSlotCenter).distance, lessThan(2.0));

      // 3) 点击装包终点 == 小号背包口 (top + 0.22 * height)
      final areaRect = backpackAreaRect(tester);
      final expectedMouth = Offset(
        areaRect.left + areaRect.width / 2,
        areaRect.top + areaRect.height * 0.22,
      );
      await tester.tap(find.text('物品1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 399));
      final clickEndCenter = tester.getRect(draggedCard).center;
      expect((clickEndCenter - expectedMouth).distance, lessThan(2.0));
      await pumpFrames(tester, total: const Duration(milliseconds: 200));
    });
  });

  group('P1 #5: 高危提醒横幅前置、可折叠与高危卡片置顶', () {
    testWidgets('T5a (红→绿): 360x640 小屏 12 件物品含高危时，横幅位于网格上方且首屏可见',
        (tester) async {
      final h = Harness();
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(360, 640), top: 24);
      final id = await h.makeList(12, highRisk: ['物品11', '物品12']);

      await tester.pumpWidget(h.app(id));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      final bannerFinder = find.textContaining('你以前忘过，先装它们');
      expect(bannerFinder, findsOneWidget);

      final bannerRect = tester.getRect(bannerFinder);
      final gridRect = gridViewportRect(tester);

      // 横幅必须在网格滚动区上方（旧版在网格最下方 bannerRect.top > gridRect.bottom）
      expect(bannerRect.bottom, lessThanOrEqualTo(gridRect.top + 1.0));
      expect(bannerRect.top, greaterThanOrEqualTo(24.0));
      expect(bannerRect.bottom, lessThan(640.0));
    });

    testWidgets('T5b (红→绿): 高危未装物品 > 2 件时横幅默认单行折叠，点击可展开/收起',
        (tester) async {
      final h = Harness();
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(360, 640), top: 24);
      final id = await h.makeList(
        10,
        highRisk: ['身份证', '充电器', '大门钥匙', '工牌'],
        nameOf: (i) => const [
          '纸巾',
          '雨伞',
          '水杯',
          '耳机',
          '眼镜',
          '口罩',
          '身份证',
          '充电器',
          '大门钥匙',
          '工牌',
        ][i],
      );

      await tester.pumpWidget(h.app(id));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      final bannerTextFinder = find.textContaining('你以前忘过，先装它们');
      expect(bannerTextFinder, findsOneWidget);

      // 默认折叠态：单行（maxLines == 1），包含“等 4 件你以前忘过，先装它们”
      final collapsedText = tester.widget<Text>(bannerTextFinder);
      expect(collapsedText.maxLines, equals(1));
      expect(collapsedText.data, contains('等 4 件你以前忘过，先装它们'));

      // 点击展开：显示全部 4 件物品名，maxLines 不再限制为 1
      await tester.tap(bannerTextFinder);
      await tester.pump();
      final expandedText = tester.widget<Text>(find.textContaining('你以前忘过，先装它们'));
      expect(expandedText.maxLines, isNull);
      for (final name in ['身份证', '充电器', '大门钥匙', '工牌']) {
        expect(expandedText.data, contains(name));
      }

      // 再次点击收起为单行
      await tester.tap(find.textContaining('你以前忘过，先装它们'));
      await tester.pump();
      expect(tester.widget<Text>(find.textContaining('你以前忘过，先装它们')).maxLines, equals(1));
    });

    testWidgets('T5c: 高危未装卡在网格置顶且保持原相对顺序，装包后横幅自动隐藏且不破坏口诀条顺序',
        (tester) async {
      final h = Harness();
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 40);
      // 原顺序：0=身份证, 1=手机, 2=钥匙(高危), 3=钱包(高危)
      final id = await h.makeList(
        4,
        mnemonic: '身手钥钱',
        highRisk: ['钱包', '钥匙'],
        nameOf: (i) => const ['身份证', '手机', '钥匙', '钱包'][i],
      );

      await tester.pumpWidget(h.app(id));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      // 钥匙(sortOrder=2)和钱包(sortOrder=3)排在第 0、1 格，身份证(0)排在第 2 格
      final rKey = slotRect(tester, '钥匙');
      final rWallet = slotRect(tester, '钱包');
      final rId = slotRect(tester, '身份证');
      expect(rKey.top, equals(rWallet.top));
      expect(rKey.left, lessThan(rWallet.left));
      expect(rWallet.left, lessThan(rId.left));

      // 装入两件高危物品后，横幅自动消失
      await tester.tap(find.text('钥匙'));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      expect(find.textContaining('你以前忘过，先装它们'), findsOneWidget);

      await tester.tap(find.text('钱包'));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));
      expect(find.textContaining('你以前忘过，先装它们'), findsNothing);
    });
  });

  group('P1 #6: 关键文字颜色对比度 (WCAG AA >= 4.5:1) 与“必带”徽标字号', () {
    test('T6a (红→绿): 清单 6 项及全背景色彩对比度均 >= 4.5:1', () {
      // 1) 装包页“还差 N 件”橙色文字 on background (#F6F7FB)
      expect(
        contrast(AppColors.orange, AppColors.background),
        greaterThanOrEqualTo(4.5),
        reason: 'orange on background must be >= 4.5:1 (was 2.05)',
      );

      // 2) 完成页“出门 🚪” / 空态“直接出门”按钮：白字 on AppColors.done
      expect(
        contrast(Colors.white, AppColors.done),
        greaterThanOrEqualTo(4.5),
        reason: 'white on done must be >= 4.5:1 (was 2.69)',
      );
      // done 作为绿色文字在 background / doneLight 上也必须 >= 4.5:1
      expect(contrast(AppColors.done, AppColors.background), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.done, AppColors.doneLight), greaterThanOrEqualTo(4.5));

      // 3) 高危横幅、“高危”徽标：AppColors.danger on AppColors.dangerLight (#FFECEC)
      expect(
        contrast(AppColors.danger, AppColors.dangerLight),
        greaterThanOrEqualTo(4.5),
        reason: 'danger on dangerLight must be >= 4.5:1 (was 2.68)',
      );

      // 4) “必带”徽标：白字 on AppColors.danger
      expect(
        contrast(Colors.white, AppColors.danger),
        greaterThanOrEqualTo(4.5),
        reason: 'white on danger must be >= 4.5:1 (was 3.05)',
      );

      // 5) 全局次要文字 textSecondary on background / card / secondaryBg / cardPacked
      expect(
        contrast(AppColors.textSecondary, AppColors.background),
        greaterThanOrEqualTo(4.5),
        reason: 'textSecondary on background must be >= 4.5:1 (was 3.99)',
      );
      expect(contrast(AppColors.textSecondary, AppColors.secondaryBg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textSecondary, AppColors.cardPacked), greaterThanOrEqualTo(4.5));

      // 6) 预设卡渐变 (primaryGradient) 起点与尾端对白字均 >= 4.5:1
      for (final c in AppColors.primaryGradient.colors) {
        expect(
          contrast(Colors.white, c),
          greaterThanOrEqualTo(4.5),
          reason: 'white on primaryGradient color $c must be >= 4.5:1 (was 2.84 at end)',
        );
      }
    });

    testWidgets('T6b (红→绿): “必带”徽标字号 >= 10px 且在 360dp 窄屏上不遮挡中央 Emoji',
        (tester) async {
      final h = Harness();
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(360, 640), top: 24);
      final id = await h.makeList(4, highRisk: ['物品1']);

      await tester.pumpWidget(h.app(id));
      await pumpFrames(tester, total: const Duration(milliseconds: 600));

      final badgeFinder = find.text('必带');
      expect(badgeFinder, findsOneWidget);

      final badgeText = tester.widget<Text>(badgeFinder);
      expect(badgeText.style?.fontSize, greaterThanOrEqualTo(10.0));

      // 检查徽标外框与中央 Emoji 文字区域不发生重叠
      final badgeBoxRect = tester.getRect(
        find.ancestor(of: badgeFinder, matching: find.byType(Container)).first,
      );
      final emojiRect = tester.getRect(find.text('📦').first);
      expect(badgeBoxRect.overlaps(emojiRect), isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
