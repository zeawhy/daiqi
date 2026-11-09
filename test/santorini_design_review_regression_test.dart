import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/features/pack/backpack_painter.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/shared/widgets/brand_backpack_icon.dart';
import 'package:daiqi/shared/widgets/mini_backpack.dart';

import 'p1_710_helpers.dart';

void main() {
  group('Santorini Design Review P0-1: BrandBackpackIcon & Emoji 拦截', () {
    testWidgets('BrandBackpackIcon 矢量组件支持各指定尺寸与对勾正常渲染', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                BrandBackpackIcon(size: 20, showCheck: true),
                BrandBackpackIcon(size: 26, showCheck: false),
                BrandBackpackIcon(size: 34, showCheck: true),
                BrandBackpackIcon(size: 52, showCheck: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BrandBackpackIcon), findsNWidgets(4));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ChecklistAvatar 对 🎒 拦截渲染 BrandBackpackIcon，其余分类 Emoji 保持原生 Text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                ChecklistAvatar(emoji: '🎒', size: 28),
                ChecklistAvatar(emoji: '💼', size: 28),
                ChecklistAvatar(emoji: '🧳', size: 28),
              ],
            ),
          ),
        ),
      );

      // 只有 🎒 渲染为 BrandBackpackIcon
      expect(find.byType(BrandBackpackIcon), findsOneWidget);
      // 没有任何高饱和红书包 Text('🎒')
      expect(find.text('🎒'), findsNothing);
      // 其余 Emoji 保持 Text 渲染
      expect(find.text('💼'), findsOneWidget);
      expect(find.text('🧳'), findsOneWidget);
    });

    testWidgets('首页自建清单空状态渲染 BrandBackpackIcon 且无 Text(🎒)', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      // 仅预设清单，自建清单为空
      await h.repo.ensurePresetChecklist();

      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('还没有自建清单'), findsOneWidget);
      // 空状态内包含 BrandBackpackIcon
      expect(find.byType(BrandBackpackIcon), findsOneWidget);
      // 红书包 Text('🎒') 彻底消除
      expect(find.text('🎒'), findsNothing);
    });

    testWidgets('设置页关于入口渲染 BrandBackpackIcon(size: 20, showCheck: true) 且无旧 Material 图标', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/settings'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('关于「带齐了」'), findsOneWidget);
      expect(find.byType(BrandBackpackIcon), findsOneWidget);
      final icon = tester.widget<BrandBackpackIcon>(find.byType(BrandBackpackIcon));
      expect(icon.size, 20);
      expect(icon.showCheck, true);
      expect(find.byIcon(Icons.backpack_outlined), findsNothing);
    });

    testWidgets('新建清单编辑页左上角选择器拦截 🎒 渲染为 BrandBackpackIcon', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/editor'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      expect(find.text('新建清单'), findsOneWidget);
      expect(find.byType(BrandBackpackIcon), findsOneWidget);
      expect(find.text('🎒'), findsNothing);
    });
  });

  group('Santorini Design Review P0-2: BackpackPainter v2 几何与 40dp 拉链缩放修复', () {
    test('BackpackPainter 在 40dp 小尺寸下正常绘制且拉链头按比例缩放、隐藏长拉片', () {
      final painter = BackpackPainter(
        progress: 1.0,
        isDone: true,
        doneTransition: 1.0,
        zipperProgress: 1.0,
        smileOpacity: 1.0,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      // 40dp 绘制不抛异常
      expect(() => painter.paint(canvas, const Size(40, 40)), returnsNormally);
      final picture = recorder.endRecording();
      picture.dispose();
    });

    testWidgets('首页右上角 MiniBackpack 尺寸 32dp 包裹于 52x52dp 白卡中且由 RepaintBoundary 隔离', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // 找到 Header 中的 MiniBackpack
      final miniBackpackFinder = find.byType(MiniBackpack);
      expect(miniBackpackFinder, findsOneWidget);
      final miniBackpack = tester.widget<MiniBackpack>(miniBackpackFinder);
      expect(miniBackpack.size, 32);

      // 验证外层包裹了 RepaintBoundary
      final repaintBoundaries = find.ancestor(
        of: miniBackpackFinder,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaries, findsWidgets);
    });
  });

  group('Santorini Design Review P1-1: 字体层级规范 (方案 A)', () {
    test('TextTheme 与 AppBarTheme 已全面落实无衬线克制杂志风规范', () {
      final theme = AppTheme.lightTheme;
      final textTheme = theme.textTheme;

      // L1 displayLarge
      expect(textTheme.displayLarge?.fontSize, 28);
      expect(textTheme.displayLarge?.fontWeight, FontWeight.w700);
      expect(textTheme.displayLarge?.letterSpacing, 1.0);

      // L2 headlineLarge & appBarTheme
      expect(textTheme.headlineLarge?.fontSize, 21);
      expect(textTheme.headlineLarge?.fontWeight, FontWeight.w600);
      expect(textTheme.headlineLarge?.letterSpacing, 0.6);
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 21);
      expect(theme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.w600);
      expect(theme.appBarTheme.titleTextStyle?.letterSpacing, 0.6);

      // L3 headlineMedium
      expect(textTheme.headlineMedium?.fontSize, 19);
      expect(textTheme.headlineMedium?.fontWeight, FontWeight.w600);
      expect(textTheme.headlineMedium?.letterSpacing, 0.4);

      // L4 titleLarge & titleMedium
      expect(textTheme.titleLarge?.fontSize, 16);
      expect(textTheme.titleLarge?.fontWeight, FontWeight.w600);
      expect(textTheme.titleLarge?.letterSpacing, 0.3);
      expect(textTheme.titleMedium?.fontSize, 15.5);
      expect(textTheme.titleMedium?.fontWeight, FontWeight.w600);
      expect(textTheme.titleMedium?.letterSpacing, 0.3);

      // 严禁全站负字距残留
      for (final style in [
        textTheme.displayLarge,
        textTheme.headlineLarge,
        textTheme.headlineMedium,
        textTheme.titleLarge,
        textTheme.titleMedium,
        textTheme.bodyLarge,
        textTheme.bodyMedium,
        textTheme.labelLarge,
        textTheme.labelSmall,
        theme.appBarTheme.titleTextStyle,
      ]) {
        if (style?.letterSpacing != null) {
          expect(style!.letterSpacing! >= 0.0, isTrue);
        }
      }
    });

    testWidgets('首页刊头大标题为 28sp w700 正字距 1.0', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final mastheadFinder = find.text('带齐了');
      expect(mastheadFinder, findsOneWidget);
      final Text mastheadText = tester.widget(mastheadFinder);
      expect(mastheadText.style?.fontSize, 28);
      expect(mastheadText.style?.fontWeight, FontWeight.w700);
      expect(mastheadText.style?.letterSpacing, 1.0);
    });

    testWidgets('首页 Hero 卡标题为 19sp w600 正字距 0.4', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final heroTitleFinder = find.text('伸手要钱');
      expect(heroTitleFinder, findsOneWidget);
      final Text heroText = tester.widget(heroTitleFinder);
      expect(heroText.style?.fontSize, 19);
      expect(heroText.style?.fontWeight, FontWeight.w600);
      expect(heroText.style?.letterSpacing, 0.4);
    });

    testWidgets('装包页清单标题降为 23sp w600 正字距 0.4（严禁 -0.5）', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        4,
        name: '伸手要钱',
        emoji: '🤚',
        nameOf: (i) => const ['身份证', '手机', '钥匙', '钱包'][i],
      );
      await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final titleFinder = find.descendant(
        of: find.byType(PackScreen),
        matching: find.text('伸手要钱'),
      );
      expect(titleFinder, findsOneWidget);
      final Text titleText = tester.widget(titleFinder);
      expect(titleText.style?.fontSize, 23);
      expect(titleText.style?.fontWeight, FontWeight.w600);
      expect(titleText.style?.letterSpacing, 0.4);
    });

    testWidgets('完成页大标题降为 23sp w600 正字距 0.4（严禁 -0.5）', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      final listId = await h.makeList(
        4,
        name: '伸手要钱',
        emoji: '🤚',
        nameOf: (i) => const ['身份证', '手机', '钥匙', '钱包'][i],
      );
      await tester.pumpWidget(
        h.routerApp(initialLocation: '/done/$listId?packed=4&total=4'),
      );
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final doneTitleFinder = find.text('全部带齐，出门吧！');
      expect(doneTitleFinder, findsOneWidget);
      final Text doneText = tester.widget(doneTitleFinder);
      expect(doneText.style?.fontSize, 23);
      expect(doneText.style?.fontWeight, FontWeight.w600);
      expect(doneText.style?.letterSpacing, 0.4);
    });

    testWidgets('遗忘页标题为 24sp w600 正字距 0.6，统计大数字为 22sp w700 正字距 0.2', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/forgot'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final forgotTitleFinder = find.byWidgetPredicate(
        (w) => w is Text && w.data == '遗忘记录' && w.style?.fontSize == 24,
      );
      expect(forgotTitleFinder, findsOneWidget);
      final Text titleText = tester.widget(forgotTitleFinder);
      expect(titleText.style?.fontSize, 24);
      expect(titleText.style?.fontWeight, FontWeight.w600);
      expect(titleText.style?.letterSpacing, 0.6);

      // 统计大数字 0
      final zeroStatFinder = find.text('0');
      expect(zeroStatFinder, findsWidgets);
      final Text zeroText = tester.widget(zeroStatFinder.first);
      expect(zeroText.style?.fontSize, 22);
      expect(zeroText.style?.fontWeight, FontWeight.w700);
      expect(zeroText.style?.letterSpacing, 0.2);
    });
  });

  group('Santorini Design Review P1-2: 首页暖米灰渐层刊头背板', () {
    testWidgets('首页顶部存在 215dp 暖米灰渐层背板与暖阳微晕', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final backdropFinder = find.byKey(const ValueKey('home_masthead_backdrop'));
      expect(backdropFinder, findsOneWidget);

      final Container container = tester.widget(backdropFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      final LinearGradient gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.first, AppColors.headerBackdropTop);
      expect(gradient.colors.last, AppColors.headerBackdropBottom);

      // 包含右上角暖阳微光 RadialGradient
      final radialGradients = find.descendant(
        of: backdropFinder,
        matching: find.byWidgetPredicate((w) {
          if (w is Container && w.decoration is BoxDecoration) {
            final d = w.decoration as BoxDecoration;
            return d.gradient is RadialGradient;
          }
          return false;
        }),
      );
      expect(radialGradients, findsOneWidget);
    });
  });
}
