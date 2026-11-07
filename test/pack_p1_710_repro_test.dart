// P1 #7 / #8 / #9 / #10 + P0 #16 复现与验证测试套件（红 → 绿）。
// 用法：将本目录下 p1_710_helpers.dart 与本文件拷入 daiqi/test/，执行：
//   flutter test test/pack_p1_710_repro_test.dart --reporter expanded
//
// 修复前（main @ 54ba305，共 21 个子项：19 红 2 绿）：
//   - 19 红（FAIL）：T7a, T7b, T7c, T8a, T8b, T8c, T8d, T9a(x2), T9b(x4), T9c, T10a, T10b, T10c, T16a, T16b；
//   - 2 绿（PASS）：T7d（默认预设主卡回退保护）、T16c（轻点取出/长按菜单/未装卡交互回归保护）。
// 修复后：21 个子项全部 PASS（21 绿）。

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daiqi/data/database.dart';
import 'package:daiqi/domain/models/pack_models.dart';
import 'package:daiqi/features/editor/checklist_editor_screen.dart';
import 'package:daiqi/features/onboarding/onboarding_screen.dart';
import 'package:daiqi/features/pack/mnemonic_bar.dart';

import 'p1_710_helpers.dart';

void main() {
  group('P1 #7: 首页动态主卡优先级（进行中 > 提醒最近 > 上次使用 > 预设）与按钮文案', () {
    testWidgets(
      'T7a (红→绿): 有未完成进行中会话的清单优先升为顶部主卡，按钮显示“继续装包（还差 N 件）”，预设清单保留在下方列表',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        final tripId = await h.makeList(
          4,
          name: '出差行李',
          emoji: '🧳',
          nameOf: (i) => const ['护照', '充电器', '转换头', '洗漱包'][i],
        );

        // 启动会话并装入 2 件（还差 2 件未装）
        final session = await h.sessionRepo.getOrCreateSession(tripId);
        final items = await h.sessionRepo.getPackItems(session.id, tripId);
        await h.sessionRepo.packItem(session.id, items[0].listItemId);
        await h.sessionRepo.packItem(session.id, items[1].listItemId);

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 500));

        expect(find.text('出差行李'), findsOneWidget);
        expect(find.text('伸手要钱'), findsOneWidget);

        // “出差行李”必须位于顶部主卡位置（Y 坐标高于“伸手要钱”）
        final tripY = tester.getCenter(find.text('出差行李')).dy;
        final presetY = tester.getCenter(find.text('伸手要钱')).dy;
        expect(tripY, lessThan(presetY));

        // 主卡 CTA 按钮文案为“继续装包（还差 2 件）”
        expect(find.text('继续装包（还差 2 件）'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'T7b (红→绿): 无未完成会话时，提醒时间最近的清单优先于较远提醒、上次使用及预设清单',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        final now = DateTime.now();
        final nearTime = now.add(const Duration(minutes: 20));
        final farTime = now.add(const Duration(minutes: 180));
        String fmtTime(DateTime t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

        // 1) 上次用过的清单（无提醒）
        final usedId = await h.makeList(3, name: '周末露营', emoji: '⛺');
        await h.db.into(h.db.packSessions).insert(
              PackSessionsCompanion.insert(
                id: 'used_session_1',
                listId: usedId,
                status: 'departed',
                startedAt: now.toUtc().subtract(const Duration(hours: 3)),
                departedAt: Value(now.toUtc().subtract(const Duration(hours: 2))),
              ),
            );

        // 2) 较远提醒清单（+180min）
        await h.makeList(
          3,
          name: '晚间健身',
          emoji: '🏋️',
          reminderEnabled: true,
          reminderTime: fmtTime(farTime),
          reminderWeekdays: const [1, 2, 3, 4, 5, 6, 7],
        );

        // 3) 最近提醒清单（+20min）
        await h.makeList(
          3,
          name: '晨间通勤',
          emoji: '🚇',
          reminderEnabled: true,
          reminderTime: fmtTime(nearTime),
          reminderWeekdays: const [1, 2, 3, 4, 5, 6, 7],
        );

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 500));

        final nearY = tester.getCenter(find.text('晨间通勤')).dy;
        final farY = tester.getCenter(find.text('晚间健身')).dy;
        final usedY = tester.getCenter(find.text('周末露营')).dy;
        final presetY = tester.getCenter(find.text('伸手要钱')).dy;

        // “晨间通勤”应选为顶部主卡
        expect(nearY, lessThan(farY));
        expect(nearY, lessThan(usedY));
        expect(nearY, lessThan(presetY));
        expect(find.text('开始装包'), findsOneWidget);
      },
    );

    testWidgets(
      'T7c (红→绿): 无未完成会话且无提醒时，上次用过的清单优先于预设清单',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        final gymId = await h.makeList(3, name: '游泳装备', emoji: '🏊');
        final now = DateTime.now().toUtc();
        await h.db.into(h.db.packSessions).insert(
              PackSessionsCompanion.insert(
                id: 'gym_dep_1',
                listId: gymId,
                status: 'departed',
                startedAt: now.subtract(const Duration(hours: 2)),
                departedAt: Value(now.subtract(const Duration(hours: 1))),
              ),
            );

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 500));

        final gymY = tester.getCenter(find.text('游泳装备')).dy;
        final presetY = tester.getCenter(find.text('伸手要钱')).dy;
        expect(gymY, lessThan(presetY));
        expect(find.text('开始装包'), findsOneWidget);
      },
    );

    testWidgets(
      'T7d (默认回退保护): 初始无会话无提醒时，预设“伸手要钱”作为顶部主卡显示',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        await h.makeList(3, name: '新建未用清单');

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 500));

        final presetY = tester.getCenter(find.text('伸手要钱')).dy;
        final customY = tester.getCenter(find.text('新建未用清单')).dy;
        expect(presetY, lessThan(customY));
      },
    );
  });

  group('P1 #8: “减少动效”与“震动”开关全局统一生效', () {
    testWidgets(
      'T8a (红→绿): 关闭震动开关 (HapticService.enabled = false) 后，首页长按菜单、底栏切换、卡片点击均不触发系统震动',
      (tester) async {
        final spy = HapticSpy();
        addTearDown(spy.dispose);

        final h = Harness710(hapticEnabled: false, reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        await h.makeList(4, name: '通勤清单');

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 400));
        spy.clear();

        // 1) 长按清单卡弹出管理菜单
        await tester.longPress(find.text('通勤清单'));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        expect(spy.calls, isEmpty, reason: '长按打开菜单不应绕过 HapticService.enabled');

        // 关闭弹窗
        await tester.tapAt(const Offset(20, 40));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        spy.clear();

        // 2) 点击底部导航栏切换到“设置”再切回“清单”
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        await tester.tap(find.byIcon(Icons.inventory_2_outlined));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        expect(spy.calls, isEmpty, reason: '底部导航栏切换不应绕过 HapticService.enabled');

        // 3) 点击清单卡进入装包页
        await tester.tap(find.text('通勤清单'));
        await pumpFrames(tester, total: const Duration(milliseconds: 300));
        expect(spy.calls, isEmpty, reason: '首页卡片点击不应绕过 HapticService.enabled');
      },
    );

    testWidgets(
      'T8b (红→绿): 开启减少动效后，首页停止无限漂浮 (pumpAndSettle 不超时)，且按压卡片不产生 0.97 缩放',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        await h.makeList(4, name: '通勤清单');

        await tester.pumpWidget(h.routerApp());
        // 若 _floatController 仍在无限 repeat()，pumpAndSettle 会直接超时报错！
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        // 按下清单卡保持不松手，检查不存在 scale < 1.0 的 AnimatedScale
        final g = await tester.startGesture(tester.getCenter(find.text('通勤清单')));
        await tester.pump(const Duration(milliseconds: 80));
        final shrinkingScales = tester
            .widgetList<AnimatedScale>(find.byType(AnimatedScale))
            .where((w) => w.scale < 1.0)
            .toList();
        expect(shrinkingScales, isEmpty, reason: '减少动效开启时按压不应产生 0.97 缩放');
        await g.cancel();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'T8c (红→绿): 开启减少动效后，底部导航栏切换 Tab 不产生 elasticOut 缩放弹跳',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        await tester.pumpWidget(h.routerApp());
        await tester.pumpAndSettle();

        // 点击切换到“设置”Tab，并在 40ms 中间帧检查图标 Transform.scale
        await tester.tap(find.byIcon(Icons.tune_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));

        final settingsIconFinder = find.byIcon(Icons.settings_rounded);
        expect(settingsIconFinder, findsOneWidget);

        // 检查包裹选中图标的 Transform 矩阵缩放因子应为 1.0（旧版为 0.75 -> elasticOut）
        final transforms = tester.widgetList<Transform>(
          find.ancestor(of: settingsIconFinder, matching: find.byType(Transform)),
        );
        for (final tr in transforms) {
          final scaleX = tr.transform.storage[0];
          expect(scaleX, closeTo(1.0, 0.001));
        }
      },
    );

    testWidgets(
      'T8d (红→绿): 开启减少动效后，引导页 OnboardingScreen 停止 _fingerController 循环动画 (pumpAndSettle 不超时)',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: h.container,
            child: const MaterialApp(home: OnboardingScreen()),
          ),
        );
        // 旧版 _fingerController 在 initState 无条件 ..repeat()，导致 pumpAndSettle 超时
        await tester.pumpAndSettle(const Duration(milliseconds: 100));
        expect(find.text('试试把钥匙拖进包里'), findsOneWidget);
      },
    );
  });

  group('P1 #9: 完成页副标题与口诀条窄屏防溢出、编辑器口诀 8 字上限', () {
    for (final (label, size) in <(String, Size)>[
      ('360x640', const Size(360, 640)),
      ('320x480', const Size(320, 480)),
    ]) {
      testWidgets(
        'T9a (红→绿): 完成页副标题含连胜文案在窄屏 [$label] 下不发生 RenderFlex overflow',
        (tester) async {
          final h = Harness710(reducedMotion: true);
          addTearDown(() => h.dispose(tester));
          setView(tester, size: size, top: 24);

          final listId = await h.makeList(12);
          final now = DateTime.now().toUtc();
          for (int s = 0; s < 12; s++) {
            await h.db.into(h.db.packSessions).insert(
                  PackSessionsCompanion.insert(
                    id: 'streak_s_$s',
                    listId: listId,
                    status: 'departed',
                    startedAt: now.subtract(Duration(hours: (s + 2) * 2)),
                    departedAt: Value(now.subtract(Duration(hours: (s + 2) * 2 - 1))),
                  ),
                );
          }

          final session = await h.sessionRepo.getOrCreateSession(listId);
          final items = await h.sessionRepo.getPackItems(session.id, listId);
          for (final it in items) {
            await h.sessionRepo.packItem(session.id, it.listItemId);
          }

          await tester.pumpWidget(
            h.routerApp(initialLocation: '/done/${session.id}?listId=$listId'),
          );
          await pumpFrames(tester, total: const Duration(milliseconds: 300));

          expect(
            tester.takeException(),
            isNull,
            reason: 'DoneScreen 在 $label 下不应溢出',
          );
          expect(find.text('12 / 12 件已装包'), findsOneWidget);
          expect(find.textContaining('连续 12 次零遗漏 🔥'), findsOneWidget);

          final countRect = tester.getRect(find.text('12 / 12 件已装包'));
          final streakRect = tester.getRect(find.textContaining('连续 12 次零遗漏 🔥'));
          expect(countRect.left, greaterThanOrEqualTo(0.0));
          expect(countRect.right, lessThanOrEqualTo(size.width));
          expect(streakRect.left, greaterThanOrEqualTo(0.0));
          expect(streakRect.right, lessThanOrEqualTo(size.width));
        },
      );
    }

    for (final (label, size, k) in <(String, Size, int)>[
      ('360x640 k=7', const Size(360, 640), 7),
      ('360x640 k=8', const Size(360, 640), 8),
      ('320x480 k=6', const Size(320, 480), 6),
      ('320x480 k=8', const Size(320, 480), 8),
    ]) {
      testWidgets(
        'T9b (红→绿): 口诀条 MnemonicBar 在窄屏 [$label] 下不发生 RenderFlex overflow 且保持单行紧凑',
        (tester) async {
          setView(tester, size: size, top: 24);
          final mnemonic = List.generate(k, (i) => '一二三四五六七八九十'[i]).join();
          final items = List.generate(
            k,
            (i) => PackItemModel(
              listItemId: 'id_$i',
              globalItemId: 'gid_$i',
              name: '物品$i',
              emoji: '📦',
              sortOrder: i,
              isPacked: i < k ~/ 2,
              isHighRisk: false,
              isSkipped: false,
            ),
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MnemonicBar(
                      mnemonic: mnemonic,
                      items: items,
                      reducedMotion: true,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(
            tester.takeException(),
            isNull,
            reason: 'MnemonicBar 在 $label 下不应溢出',
          );
          final barRect = tester.getRect(find.byType(MnemonicBar));
          final lastCharRect = tester.getRect(find.text(mnemonic[k - 1]));
          expect(barRect.right, lessThanOrEqualTo(size.width - 16.0 + 0.5));
          expect(lastCharRect.right, lessThanOrEqualTo(size.width - 16.0 + 0.5));
        },
      );
    }

    testWidgets(
      'T9c (红→绿): 编辑器 ChecklistEditorScreen 自动口诀最多取前 8 字，且 10 件物品的清单在装包页正常渲染 8 字口诀条',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: h.container,
            child: const MaterialApp(home: ChecklistEditorScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 依次添加 10 件不同首字的物品
        const names = ['身份证', '手机', '钥匙', '钱包', '耳机', '雨伞', '水杯', '充电器', '纸巾', '工牌'];
        final itemInput = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == '输入物品名称，按回车添加',
        );
        for (final name in names) {
          await tester.enterText(itemInput, name);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
        }

        // 打开“口诀条”开关（第一个 Switch）
        final mnemonicSwitch = find.byType(Switch).first;
        await tester.ensureVisible(mnemonicSwitch);
        await tester.tap(mnemonicSwitch);
        await tester.pump();

        // 查找口诀输入框，验证自动生成的口诀被限制在 8 个字（“身手钥钱耳雨水充”）
        final mnemonicField = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) => w is TextField && (w.decoration?.hintText?.contains('身手钥钱') ?? false),
          ),
        );
        final generated = mnemonicField.controller!.text;
        expect(generated.characters.length, equals(8));
        expect(generated, equals('身手钥钱耳雨水充'));
        expect(mnemonicField.maxLength, equals(8));

        // 同时验证 10 件物品 + 8 字口诀在 PackScreen (360x640) 下仍可正常显示 MnemonicBar 且不溢出
        final list10Id = await h.makeList(
          10,
          name: '十全大补',
          mnemonic: generated,
          nameOf: (i) => names[i],
        );
        setView(tester, size: const Size(360, 640), top: 24);
        await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$list10Id'));
        await pumpFrames(tester, total: const Duration(milliseconds: 500));

        expect(find.byType(MnemonicBar), findsOneWidget);
        expect(find.text('充'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('P1 #10: 清单管理显式 ⋯ 按钮（48dp 热区）与单清单提示可见', () {
    testWidgets(
      'T10a (红→绿): 只有 1 个自建清单时，首页即显示管理提示（不再要求 > 1 个）',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        await h.makeList(4, name: '唯一自建清单');

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        expect(find.textContaining('长按管理'), findsOneWidget);
      },
    );

    testWidgets(
      'T10b (红→绿): 清单卡右侧提供 48x48dp 热区的 ⋯ 按钮，点击直接打开管理菜单（编辑/复制/删除）而非进入装包页',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        final id = await h.makeList(4, name: '日常通勤');

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        final moreBtnFinder = find.byKey(ValueKey('checklist_more_$id'));
        expect(moreBtnFinder, findsOneWidget);

        // 验证热区 >= 48x48dp
        final btnRect = tester.getRect(moreBtnFinder);
        expect(btnRect.width, greaterThanOrEqualTo(48.0));
        expect(btnRect.height, greaterThanOrEqualTo(48.0));

        // 点击 ⋯ 按钮应弹出管理菜单，包含立即开始装包、编辑、复制、删除
        await tester.tap(moreBtnFinder);
        await pumpFrames(tester, total: const Duration(milliseconds: 300));

        expect(find.text('立即开始装包'), findsOneWidget);
        expect(find.text('编辑'), findsOneWidget);
        expect(find.text('复制'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
      },
    );

    testWidgets(
      'T10c (红→绿): 当自建清单被 #7 提升为顶部主卡时，主卡同样支持点击 ⋯ 按钮打开管理菜单',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        final id = await h.makeList(4, name: '进行中清单');
        final session = await h.sessionRepo.getOrCreateSession(id);
        final items = await h.sessionRepo.getPackItems(session.id, id);
        await h.sessionRepo.packItem(session.id, items.first.listItemId);

        await tester.pumpWidget(h.routerApp());
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        // 此时“进行中清单”位于顶部主卡，验证其 ⋯ 按钮同样存在且可点击打开管理菜单
        final heroMoreFinder = find.byKey(ValueKey('checklist_more_$id'));
        expect(heroMoreFinder, findsOneWidget);

        final heroMoreRect = tester.getRect(heroMoreFinder);
        expect(heroMoreRect.width, greaterThanOrEqualTo(48.0));
        expect(heroMoreRect.height, greaterThanOrEqualTo(48.0));

        await tester.tap(heroMoreFinder);
        await pumpFrames(tester, total: const Duration(milliseconds: 300));

        expect(find.text('编辑'), findsOneWidget);
        expect(find.text('复制'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
      },
    );
  });

  group('P0 #16: 滑动浏览网格时触到已装包卡片防误触取消装包', () {
    testWidgets(
      'T16a (红→绿): 从已装包卡片上起手滑动浏览网格（移动 > 8pt）后松手，已装状态保持不变',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 640), top: 24);

        final listId = await h.makeList(12, name: '差旅清单');
        final session = await h.sessionRepo.getOrCreateSession(listId);
        final items = await h.sessionRepo.getPackItems(session.id, listId);
        // 先装入前 9 件（剩余 3 件未装排第 1 行，已装的“物品1..3”排第 2 行首屏可见）
        for (int i = 0; i < 9; i++) {
          await h.sessionRepo.packItem(session.id, items[i].listItemId);
        }

        await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        expect(find.text('9 / 12'), findsOneWidget);

        // 从已装卡“物品1”起手向上滑动 80pt 浏览网格后松手
        final start = tester.getCenter(find.text('物品1'));
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(const Offset(0, -40));
        await tester.pump(const Duration(milliseconds: 16));
        await gesture.moveBy(const Offset(0, -40));
        await tester.pump(const Duration(milliseconds: 16));
        await gesture.up();
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        // 滑动后“物品1”绝不能被误触取出，已装数仍为 9 / 12
        expect(find.text('9 / 12'), findsOneWidget);
        final afterItems = await h.sessionRepo.getPackItems(session.id, listId);
        expect(afterItems.firstWhere((i) => i.name == '物品1').isPacked, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'T16b (红→绿): 从已装包卡片起手滑动超 8pt 后又折返至起点附近（终点距起点 <= 8pt）松手，仍不触发取出',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 640), top: 24);

        final listId = await h.makeList(6, name: '短途清单');
        final session = await h.sessionRepo.getOrCreateSession(listId);
        final items = await h.sessionRepo.getPackItems(session.id, listId);
        await h.sessionRepo.packItem(session.id, items[0].listItemId);
        await h.sessionRepo.packItem(session.id, items[1].listItemId);

        await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$listId'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        expect(find.text('2 / 6'), findsOneWidget);

        // 从已装卡“物品1”起手向下滑 30pt（> 8pt），再滑回 +28pt（终点距起点仅 2pt）后松手
        final start = tester.getCenter(find.text('物品1'));
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(const Offset(0, -30));
        await tester.pump(const Duration(milliseconds: 16));
        await gesture.moveBy(const Offset(0, 28));
        await tester.pump(const Duration(milliseconds: 16));
        await gesture.up();
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        expect(find.text('2 / 6'), findsOneWidget);
        final afterItems = await h.sessionRepo.getPackItems(session.id, listId);
        expect(afterItems.firstWhere((i) => i.name == '物品1').isPacked, isTrue);
      },
    );

    testWidgets(
      'T16c (回归保护): 轻点已装卡（<= 8pt）正常取出、长按已装卡正常弹菜单、未装卡点击与拖拽行为不变',
      (tester) async {
        final h = Harness710(reducedMotion: true);
        addTearDown(() => h.dispose(tester));
        setView(tester, size: const Size(360, 800), top: 24);

        await h.repo.ensurePresetChecklist();
        final summaries = await h.repo.watchAllSummaries().first;
        final presetId = summaries.first.id;

        await tester.pumpWidget(h.routerApp(initialLocation: '/pack/$presetId'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        // 1) 轻点未装卡“钥匙” -> 正常装包 (1 / 4)
        await tester.tap(find.text('钥匙'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));
        expect(find.text('1 / 4'), findsOneWidget);

        // 2) 长按已装卡“钥匙” -> 弹出菜单且不取出 (仍为 1 / 4)
        await tester.longPress(find.text('钥匙'));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));
        expect(find.text('今天不带'), findsOneWidget);
        expect(find.text('1 / 4'), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await pumpFrames(tester, total: const Duration(milliseconds: 400));

        // 3) 轻点已装卡“钥匙”（含微小手指抖动 3pt <= 8pt）-> 正常取出 (0 / 4)
        final keyCenter = tester.getCenter(find.text('钥匙'));
        final tapGesture = await tester.startGesture(keyCenter);
        await tapGesture.moveBy(const Offset(2, 2));
        await tester.pump(const Duration(milliseconds: 16));
        await tapGesture.up();
        await pumpFrames(tester, total: const Duration(milliseconds: 400));
        expect(find.text('0 / 4'), findsOneWidget);

        // 4) 拖拽未装卡“手机”超 8pt 但在背包外松手 -> 飞回原位不装包 (0 / 4)
        final phoneCenter = tester.getCenter(find.text('手机'));
        final dragGesture = await tester.startGesture(phoneCenter);
        await dragGesture.moveBy(const Offset(0, 25));
        await tester.pump(const Duration(milliseconds: 16));
        await dragGesture.up();
        await pumpFrames(tester, total: const Duration(milliseconds: 400));
        expect(find.text('0 / 4'), findsOneWidget);
      },
    );
  });
}
