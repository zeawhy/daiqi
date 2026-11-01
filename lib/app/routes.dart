import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/done/done_screen.dart';
import '../features/editor/checklist_editor_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/forgot/forgot_screen.dart';
import '../features/home/home_screen.dart';
import '../features/navigation/main_scaffold.dart';
import '../features/pack/pack_screen.dart';
import '../features/settings/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/forgot',
              builder: (context, state) => const ForgotScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/pack/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PackScreen(checklistId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/done/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId']!;
        final listId = state.uri.queryParameters['listId'] ?? '';
        return DoneScreen(sessionId: sessionId, listId: listId);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/editor',
      builder: (context, state) {
        return const ChecklistEditorScreen();
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/editor/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        return ChecklistEditorScreen(checklistId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/onboarding',
      builder: (context, state) {
        return const OnboardingScreen();
      },
    ),
  ],
);
