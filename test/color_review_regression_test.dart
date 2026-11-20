import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/app/theme.dart';
import 'package:daiqi/domain/models/pack_models.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';
import 'package:daiqi/shared/widgets/dashed_border.dart';

import 'p1_710_helpers.dart';

Color _alphaComposite(Color fg, Color bg) {
  final a = fg.a;
  final r = fg.r * a + bg.r * (1.0 - a);
  final g = fg.g * a + bg.g * (1.0 - a);
  final b = fg.b * a + bg.b * (1.0 - a);
  return Color.from(alpha: 1.0, red: r, green: g, blue: b);
}

void main() {
  group('Color Review: Theme Tokens & M3 ColorScheme Convergence', () {
    test('ColorScheme 完整定义暖石中性色，无 M3 默认紫色泄漏', () {
      final scheme = AppTheme.lightTheme.colorScheme;
      expect(scheme.primary, AppColors.primary);
      expect(scheme.onPrimary, AppColors.onDark);
      expect(scheme.surface, AppColors.card);
      expect(scheme.onSurface, AppColors.textPrimary);
      expect(scheme.onSurfaceVariant, AppColors.textSecondary);
      expect(scheme.outline, AppColors.borderStrong);
      expect(scheme.outlineVariant, AppColors.border);
      expect(scheme.surfaceContainerLowest, AppColors.card);
      expect(scheme.surfaceContainerLow, AppColors.background);
      expect(scheme.surfaceContainer, AppColors.secondaryBg);
      expect(scheme.surfaceContainerHigh, AppColors.primaryLight);
      expect(scheme.surfaceContainerHighest, AppColors.border);
      expect(scheme.error, AppColors.danger);
      expect(scheme.onError, AppColors.onDark);
    });

    test('全局控件主题（按钮/开关/复选框/输入框/芯片/分割线/弹窗/时间选择器/进度条）均收拢到 Santorini 色板', () {
      final theme = AppTheme.lightTheme;

      // 1. FilledButton & ElevatedButton disabled state >= 4.5:1
      for (final style in [
        theme.filledButtonTheme.style!,
        theme.elevatedButtonTheme.style!,
      ]) {
        final disabledBg = style.backgroundColor!.resolve({WidgetState.disabled})!;
        final disabledFg = style.foregroundColor!.resolve({WidgetState.disabled})!;
        expect(disabledBg, AppColors.disabledBg);
        expect(disabledFg, AppColors.disabledFg);
        expect(contrast(disabledFg, disabledBg), greaterThanOrEqualTo(4.5));
      }

      // 2. OutlinedButton border contrast >= 3:1 on white card
      final outlinedSide = theme.outlinedButtonTheme.style!.side!.resolve({})!;
      expect(outlinedSide.color, AppColors.borderStrong);
      expect(contrast(outlinedSide.color, AppColors.card), greaterThanOrEqualTo(3.0));

      // 3. TextButton foreground & disabled foreground
      final textFg = theme.textButtonTheme.style!.foregroundColor!.resolve({})!;
      final textDisabledFg =
          theme.textButtonTheme.style!.foregroundColor!.resolve({WidgetState.disabled})!;
      expect(textFg, AppColors.primary);
      expect(textDisabledFg, AppColors.disabledFg);
      expect(contrast(textDisabledFg, AppColors.card), greaterThanOrEqualTo(4.5));

      // 4. Switch track outline eliminates M3 default purple-grey
      expect(
        theme.switchTheme.trackOutlineColor!.resolve({WidgetState.selected}),
        Colors.transparent,
      );
      expect(
        theme.switchTheme.trackOutlineColor!.resolve({}),
        AppColors.borderStrong,
      );

      // 5. Checkbox theme
      expect(
        theme.checkboxTheme.fillColor!.resolve({WidgetState.selected}),
        AppColors.primary,
      );
      expect(
        theme.checkboxTheme.checkColor!.resolve({WidgetState.selected}),
        AppColors.onDark,
      );
      expect(theme.checkboxTheme.side?.color, AppColors.textSecondary);

      // 6. InputDecoration theme
      expect(theme.inputDecorationTheme.hintStyle?.color, AppColors.textSecondary);
      expect(theme.inputDecorationTheme.helperStyle?.color, AppColors.textSecondary);
      expect(theme.inputDecorationTheme.errorStyle?.color, AppColors.danger);

      // 7. Divider, Dialog, SnackBar, ProgressIndicator, TimePicker themes
      expect(theme.dividerTheme.color, AppColors.border);
      expect(theme.dialogTheme.titleTextStyle?.color, AppColors.textPrimary);
      expect(theme.dialogTheme.contentTextStyle?.color, AppColors.textSecondary);
      expect(theme.snackBarTheme.backgroundColor, AppColors.textPrimary);
      expect(theme.snackBarTheme.contentTextStyle?.color, AppColors.onDark);
      expect(theme.snackBarTheme.actionTextColor, AppColors.pastelAmber);
      expect(theme.progressIndicatorTheme.color, AppColors.primary);
      expect(theme.progressIndicatorTheme.linearTrackColor, AppColors.secondaryBg);
      expect(theme.timePickerTheme.backgroundColor, AppColors.card);
      expect(theme.timePickerTheme.dialBackgroundColor, AppColors.background);
      expect(theme.timePickerTheme.dialHandColor, AppColors.primary);
    });

    test('浅色与深色背景下的全站核心配色满足 WCAG 对比度标准（正文 >= 4.5:1，大字/图标/边框 >= 3:1）', () {
      // Light surfaces: body text >= 4.5:1
      for (final bg in [
        AppColors.card,
        AppColors.background,
        AppColors.secondaryBg,
        AppColors.cardPacked,
        AppColors.primaryLight,
      ]) {
        expect(contrast(AppColors.textPrimary, bg), greaterThanOrEqualTo(4.5));
        expect(contrast(AppColors.textSecondary, bg), greaterThanOrEqualTo(4.5));
      }

      // Dark surfaces: white text >= 4.5:1
      for (final darkBg in [
        AppColors.primary,
        AppColors.textPrimary,
        AppColors.done,
        AppColors.danger,
      ]) {
        expect(contrast(AppColors.onDark, darkBg), greaterThanOrEqualTo(4.5));
      }

      // Semantic badges & alerts >= 4.5:1
      expect(contrast(AppColors.done, AppColors.doneLight), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.orange, AppColors.orangeLight), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.danger, AppColors.dangerLight), greaterThanOrEqualTo(4.5));
      expect(
        contrast(AppColors.pastelAmber, AppColors.textPrimary),
        greaterThanOrEqualTo(4.5),
      );

      // Non-text UI boundaries & dark overlay icons >= 3.0:1
      expect(contrast(AppColors.borderStrong, AppColors.card), greaterThanOrEqualTo(3.0));
      final compositedDoorIcon = _alphaComposite(AppColors.onDarkSubtle, AppColors.textPrimary);
      expect(contrast(compositedDoorIcon, AppColors.textPrimary), greaterThanOrEqualTo(3.0));
    });

    test('除 lib/app/theme.dart 外，lib/ 下不再散落硬编码 Color(0x...) 或 Color.fromRGBO(...)', () {
      final libDir = Directory('lib');
      final offending = <String>[];
      final pattern = RegExp(r'Color\s*\(|Color\.fromRGBO\s*\(|Colors\.white[0-9]+');

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final normalized = entity.path.replaceAll('\\', '/');
        if (normalized.endsWith('lib/app/theme.dart')) continue;
        final content = entity.readAsStringSync();
        if (pattern.hasMatch(content)) {
          offending.add(normalized);
        }
      }
      expect(offending, isEmpty, reason: 'Found hardcoded colors outside theme.dart: $offending');
    });
  });

  group('Color Review: Key Controls Widget Regressions', () {
    testWidgets('ItemCardWidget 跳过态不使用整卡低透明，正文对比度 >= 4.5:1；占位态图标对比度 >= 3:1', (tester) async {
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
      const normalItem = PackItemModel(
        listItemId: 'n1',
        globalItemId: 'g2',
        name: '钥匙',
        emoji: '🔑',
        sortOrder: 1,
        isPacked: false,
        isHighRisk: true,
        isSkipped: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Row(
              children: [
                SizedBox(width: 110, child: ItemCardWidget(item: skippedItem)),
                SizedBox(width: 110, child: ItemCardWidget(item: normalItem, isPlaceholder: true)),
                SizedBox(width: 110, child: ItemCardWidget(item: normalItem)),
              ],
            ),
          ),
        ),
      );

      // 1. Skipped item text must NOT be wrapped in low-opacity Opacity widget
      final skippedTextFinder = find.text('雨伞');
      expect(skippedTextFinder, findsOneWidget);
      final ancestorOpacities = find.ancestor(
        of: skippedTextFinder,
        matching: find.byType(Opacity),
      );
      expect(ancestorOpacities, findsNothing);

      final skippedText = tester.widget<Text>(skippedTextFinder);
      expect(skippedText.style?.color, AppColors.textSecondary);
      expect(contrast(skippedText.style!.color!, AppColors.cardPacked), greaterThanOrEqualTo(4.5));

      // 2. Placeholder icon uses AppColors.textSecondary (>= 3:1)
      final placeholderIcon = tester.widget<Icon>(find.byIcon(Icons.north_rounded));
      expect(placeholderIcon.color, AppColors.textSecondary);
      final placeholderFill = _alphaComposite(
        AppColors.primaryLight.withValues(alpha: 0.45),
        AppColors.background,
      );
      expect(contrast(placeholderIcon.color!, placeholderFill), greaterThanOrEqualTo(3.0));

      // 3. High-risk badge white on danger >= 4.5:1
      final badgeText = tester.widget<Text>(find.text('必带'));
      expect(contrast(badgeText.style!.color!, AppColors.danger), greaterThanOrEqualTo(4.5));
    });

    testWidgets('完成页「出门 🚪」按钮在禁用态下不硬编码白字，使用高对比 disabledFg/disabledBg', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      final listId = (await h.db.select(h.db.checklistLists).get()).first.id;
      final session = await h.sessionRepo.getOrCreateSession(listId);

      await tester.pumpWidget(
        h.routerApp(initialLocation: '/done/${session.id}?listId=$listId'),
      );
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      final departBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '出门 🚪'),
      );
      final disabledBg = departBtn.style!.backgroundColor!.resolve({WidgetState.disabled})!;
      final disabledFg = departBtn.style!.foregroundColor!.resolve({WidgetState.disabled})!;
      expect(disabledBg, AppColors.disabledBg);
      expect(disabledFg, AppColors.disabledFg);
      expect(contrast(disabledFg, disabledBg), greaterThanOrEqualTo(4.5));

      // Text child must not hardcode color: Colors.white so disabledForegroundColor applies
      final labelText = tester.widget<Text>(find.text('出门 🚪'));
      expect(labelText.style?.color, isNull);
    });

    testWidgets('首页「新建专属清单」虚线按钮使用 borderStrong 清晰描边', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await h.repo.ensurePresetChecklist();
      await tester.pumpWidget(h.routerApp(initialLocation: '/'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      final dashedPaint = tester.widget<CustomPaint>(
        find.ancestor(
          of: find.text('新建专属清单'),
          matching: find.byType(CustomPaint),
        ).first,
      );
      final painter = dashedPaint.painter! as DashedBorderPainter;
      expect(painter.color, AppColors.borderStrong);
      expect(contrast(painter.color, AppColors.card), greaterThanOrEqualTo(3.0));
    });

    testWidgets('编辑页口诀输入框在白色卡片内使用 background 暖石底色形成层次区分', (tester) async {
      final h = Harness710(reducedMotion: true);
      addTearDown(() => h.dispose(tester));
      setView(tester, size: const Size(400, 850), top: 24);

      await tester.pumpWidget(h.routerApp(initialLocation: '/editor'));
      await pumpFrames(tester, total: const Duration(milliseconds: 400));

      // Turn on mnemonic switch (first Switch on page)
      final mnemonicSwitch = find.byType(Switch).first;
      await tester.ensureVisible(mnemonicSwitch);
      await tester.tap(mnemonicSwitch);
      await pumpFrames(tester, total: const Duration(milliseconds: 300));

      final mnemonicField = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == '如：身手钥钱',
        ),
      );
      expect(mnemonicField.decoration?.filled, isTrue);
      expect(mnemonicField.decoration?.fillColor, AppColors.background);
    });
  });
}
