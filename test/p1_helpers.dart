// 共用夹具：P1 #4/#5/#6 复现测试。拷到 daiqi/test/ 下使用。
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/app/theme.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/features/done/done_screen.dart';
import 'package:daiqi/features/home/home_screen.dart';
import 'package:daiqi/features/pack/backpack_widget.dart';
import 'package:daiqi/features/pack/item_card_widget.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/l10n/app_localizations.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';

/// 设置虚拟屏幕：逻辑尺寸 [size]，dpr=1，四边安全区。
void setView(WidgetTester t,
    {Size size = const Size(400, 850),
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0}) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  final p = FakeViewPadding(top: top, bottom: bottom, left: left, right: right);
  t.view.padding = p;
  t.view.viewPadding = p;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetPadding();
    t.view.resetViewPadding();
  });
}

Future<void> pumpFrames(WidgetTester tester,
    {Duration total = const Duration(milliseconds: 500),
    Duration step = const Duration(milliseconds: 50)}) async {
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

Finder get draggedCard =>
    find.byWidgetPredicate((w) => w is ItemCardWidget && w.isDragged);

/// 一个独立的内存库 + ProviderContainer + 路由，封装 PackScreen / DoneScreen / HomeScreen。
class Harness {
  late AppDatabase db;
  late ProviderContainer container;
  late ChecklistRepository repo;
  bool _closed = false;

  Harness() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    AudioService.enabled = false;
    HapticService.enabled = false;
    db = AppDatabase(NativeDatabase.memory());
    repo = ChecklistRepository(db);
    container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
  }

  /// 创建 N 个物品的清单，返回 listId。[highRisk] 里的物品名会被记一笔“忘过”。
  Future<String> makeList(int n,
      {String name = '测试清单',
      String? mnemonic,
      List<String> highRisk = const [],
      String Function(int i)? nameOf}) async {
    final id = await repo.createChecklist(
      name: name,
      emoji: '🎒',
      mnemonic: mnemonic,
      items: List.generate(n, (i) => (name: nameOf?.call(i) ?? '物品${i + 1}', emoji: '📦')),
    );
    if (highRisk.isNotEmpty) {
      await repo.recordForgotItems(listId: id, itemNames: highRisk);
    }
    return id;
  }

  Widget app(String listId, {String initial = '/pack'}) {
    final router = GoRouter(
      initialLocation: initial == '/pack' ? '/pack/$listId' : initial,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/pack/:id', builder: (_, s) => PackScreen(checklistId: s.pathParameters['id']!)),
        GoRoute(
            path: '/done/:sessionId',
            builder: (_, s) => DoneScreen(
                sessionId: s.pathParameters['sessionId']!, listId: s.uri.queryParameters['listId'] ?? '')),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  Future<void> dispose(WidgetTester tester) async {
    if (_closed) return;
    _closed = true;
    container.dispose();
    await tester.pump();
    await db.close();
  }
}

/// 背包区域（含计数文字与 padding）的 Rect：`_backpackAreaKey` 所在 Container。
Rect backpackAreaRect(WidgetTester t) {
  final c = find
      .ancestor(of: find.byType(BackpackWidget), matching: find.byType(Container))
      .first;
  return t.getRect(c);
}

/// 网格滚动区（`_gridAreaKey` 所在的 SingleChildScrollView）的 viewport Rect。
Rect gridViewportRect(WidgetTester t) => t.getRect(find.byType(SingleChildScrollView).first);

/// 屏幕上某物品卡槽（SizedBox 86 高）的 Rect。
Rect slotRect(WidgetTester t, String name) =>
    t.getRect(find.ancestor(of: find.text(name), matching: find.byType(SizedBox)).first);

// ---- WCAG ----
double _lin(int c) {
  final s = c / 255;
  return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
}

double luminance(Color c) {
  final r = (c.r * 255).round(), g = (c.g * 255).round(), b = (c.b * 255).round();
  return 0.2126 * _lin(r) + 0.7152 * _lin(g) + 0.0722 * _lin(b);
}

double contrast(Color a, Color b) {
  final la = luminance(a), lb = luminance(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
