import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/shared/widgets/mini_backpack.dart';

import 'p1_710_helpers.dart';

void main() {
  group('首页顶部设计回归：底图背景 + 展示标题字体', () {
    test('底图与子集字体资源文件存在、体积克制且已在 pubspec.yaml 注册（非思源宋体）', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/images/'));
      expect(pubspec, contains('family: DaiqiDisplay'));
      expect(pubspec, contains('asset: assets/fonts/DaiqiDisplay-Regular.ttf'));
      expect(pubspec.toLowerCase(), isNot(contains('sourcehanserif')));
      expect(pubspec.toLowerCase(), isNot(contains('notoserif')));

      final bgFile = File('assets/images/home_header_bg.webp');
      expect(bgFile.existsSync(), isTrue);
      final bgBytes = bgFile.lengthSync();
      expect(bgBytes, greaterThan(1024));
      expect(bgBytes, lessThan(100 * 1024));

      final fontFile = File('assets/fonts/DaiqiDisplay-Regular.ttf');
      expect(fontFile.existsSync(), isTrue);
      final fontBytes = fontFile.lengthSync();
      expect(fontBytes, greaterThan(500));
      expect(fontBytes, lessThan(100 * 1024));
    });

    testWidgets('首页顶栏渲染底图、左侧可读性柔光衬底与展示字体大标题「带齐了」', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(tester.takeException(), isNull);

      // 1. 底图组件与可读性衬底挂载正常
      final bgImageFinder = find.byKey(const ValueKey('home_masthead_bg_image'));
      expect(bgImageFinder, findsOneWidget);
      final Image bgImage = tester.widget(bgImageFinder);
      expect(bgImage.fit, BoxFit.cover);
      expect(bgImage.alignment, Alignment.topRight);
      expect(bgImage.excludeFromSemantics, isTrue);

      expect(
        find.byKey(const ValueKey('home_masthead_readability_scrim')),
        findsOneWidget,
      );

      // 2. 顶栏背板完整覆盖问候胶囊、标题、日期与右上角迷你背包
      final backdropRect = tester.getRect(
        find.byKey(const ValueKey('home_masthead_backdrop')),
      );
      final pillRect = tester.getRect(
        find.byKey(const ValueKey('home_greeting_pill')),
      );
      final titleFinder = find.text('带齐了');
      final titleRect = tester.getRect(titleFinder);
      final backpackRect = tester.getRect(find.byType(MiniBackpack));

      expect(backdropRect.top, equals(0.0));
      expect(backdropRect.bottom, greaterThan(titleRect.bottom + 20));
      expect(backdropRect.bottom, greaterThan(backpackRect.bottom));
      expect(pillRect.top, greaterThanOrEqualTo(backdropRect.top));

      // 3. 「带齐了」采用专属展示字体 DaiqiDisplay（严禁思源宋体）
      final Text titleWidget = tester.widget(titleFinder);
      expect(titleWidget.style?.fontFamily, AppTheme.homeDisplayFontFamily);
      expect(titleWidget.style?.fontFamily, isNot(contains('Serif')));
      expect(titleWidget.style?.fontSize, 34);
      expect(titleWidget.style?.letterSpacing, 1.6);
      expect(titleWidget.style?.color, AppColors.textPrimary);

      // 4. 其余首页区块保持原样
      expect(find.text('伸手要钱'), findsOneWidget);
      expect(find.text('我的清单'), findsOneWidget);
    });

    testWidgets('多屏幕尺寸 (320dp 小屏 / 768dp 宽屏) 及 1.3x 大字号与下滑时顶栏无溢出且平滑过渡',
        (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));

      await h.repo.ensurePresetChecklist();
      for (var i = 0; i < 5; i++) {
        await h.makeList(2, name: '清单$i');
      }

      final cases = const <({Size size, double scale})>[
        (size: Size(320, 568), scale: 1.0),
        (size: Size(360, 800), scale: 1.3),
        (size: Size(393, 852), scale: 1.3),
        (size: Size(768, 1024), scale: 1.3),
      ];
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final c in cases) {
        tester.platformDispatcher.textScaleFactorTestValue = c.scale;
        setView(tester, size: c.size, top: 44);
        await tester.pumpWidget(h.routerApp(initialLocation: '/'));
        await pumpFrames(tester, total: const Duration(milliseconds: 350));

        expect(tester.takeException(), isNull);
        expect(find.text('带齐了'), findsOneWidget);
        expect(find.byKey(const ValueKey('home_masthead_bg_image')), findsOneWidget);
      }

      // 验证列表向下大幅滚动时顶栏背板平滑淡出隐藏，不污染下方卡片背景
      tester.platformDispatcher.textScaleFactorTestValue = 1.0;
      setView(tester, size: const Size(393, 520), top: 44);
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 250));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -280));
      await pumpFrames(tester, total: const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('home_masthead_backdrop')), findsNothing);
    });
  });
}
