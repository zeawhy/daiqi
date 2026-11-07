// 共用夹具：P1 #7/#8/#9/#10 复现与验证测试。拷到 daiqi/test/ 下使用。
import 'dart:math' as math;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:daiqi/app/providers.dart';
import 'package:daiqi/app/theme.dart';
import 'package:daiqi/data/database.dart';
import 'package:daiqi/data/repositories/checklist_repository.dart';
import 'package:daiqi/data/repositories/pack_session_repository.dart';
import 'package:daiqi/features/done/done_screen.dart';
import 'package:daiqi/features/editor/checklist_editor_screen.dart';
import 'package:daiqi/features/forgot/forgot_screen.dart';
import 'package:daiqi/features/home/home_screen.dart';
import 'package:daiqi/features/navigation/main_scaffold.dart';
import 'package:daiqi/features/onboarding/onboarding_screen.dart';
import 'package:daiqi/features/pack/pack_screen.dart';
import 'package:daiqi/features/settings/settings_screen.dart';
import 'package:daiqi/l10n/app_localizations.dart';
import 'package:daiqi/shared/services/audio_service.dart';
import 'package:daiqi/shared/services/haptic_service.dart';

/// 设置虚拟屏幕：逻辑尺寸 [size]，dpr=1，四边安全区。
void setView(
  WidgetTester t, {
  Size size = const Size(400, 850),
  double top = 0,
  double bottom = 0,
  double left = 0,
  double right = 0,
}) {
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

Future<void> pumpFrames(
  WidgetTester tester, {
  Duration total = const Duration(milliseconds: 500),
  Duration step = const Duration(milliseconds: 50),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// 拦截 SystemChannels.platform 上的 HapticFeedback.vibrate 调用，用于实测 #8 震动开关是否漏管。
class HapticSpy {
  final List<String> calls = [];

  HapticSpy() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add('${call.arguments}');
      }
      return null;
    });
  }

  void clear() => calls.clear();

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  }
}

/// 独立的内存库 + ProviderContainer + 完整路由，封装 HomeScreen / MainScaffold / PackScreen / DoneScreen / Editor。
class Harness710 {
  late AppDatabase db;
  late ProviderContainer container;
  late ChecklistRepository repo;
  late PackSessionRepository sessionRepo;
  bool _closed = false;

  Harness710({bool hapticEnabled = false, bool reducedMotion = false}) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    AudioService.enabled = false;
    HapticService.enabled = hapticEnabled;
    OnboardingService.markCompleted();
    db = AppDatabase(NativeDatabase.memory());
    repo = ChecklistRepository(db);
    sessionRepo = PackSessionRepository(db, repo);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
    if (reducedMotion) {
      container.read(reducedMotionProvider.notifier).setReducedMotion(true);
    }
  }

  /// 创建 N 个物品的清单，返回 listId。
  Future<String> makeList(
    int n, {
    String name = '测试清单',
    String emoji = '🎒',
    String? mnemonic,
    bool reminderEnabled = false,
    String? reminderTime,
    List<int>? reminderWeekdays,
    List<String> highRisk = const [],
    String Function(int i)? nameOf,
  }) async {
    final id = await repo.createChecklist(
      name: name,
      emoji: emoji,
      mnemonic: mnemonic,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
      reminderWeekdays: reminderWeekdays,
      items: List.generate(
        n,
        (i) => (name: nameOf?.call(i) ?? '物品${i + 1}', emoji: '📦'),
      ),
    );
    if (highRisk.isNotEmpty) {
      await repo.recordForgotItems(listId: id, itemNames: highRisk);
    }
    return id;
  }

  /// 构造带完整 Shell / 路由的测试 App。
  Widget routerApp({
    String initialLocation = '/',
    bool disableAnimations = false,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/forgot', builder: (_, _) => const ForgotScreen()),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/pack/:id',
          builder: (_, s) => PackScreen(checklistId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/done/:sessionId',
          builder: (_, s) => DoneScreen(
            sessionId: s.pathParameters['sessionId']!,
            listId: s.uri.queryParameters['listId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/editor',
          builder: (_, _) => const ChecklistEditorScreen(),
        ),
        GoRoute(
          path: '/editor/:id',
          builder: (_, s) => ChecklistEditorScreen(checklistId: s.pathParameters['id']),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          if (!disableAnimations) return child!;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          );
        },
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
