import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'shell.dart';
import 'theme/app_theme.dart';
import '../features/chat/chat_page.dart';
import '../features/history/history_page.dart';
import '../features/home/home_page.dart';
import '../features/me/me_page.dart';
import '../features/phrasebook/phrasebook_page.dart';
import '../features/review/review_page.dart';
import '../features/scenario/scenario_library_page.dart';
import '../features/scenario/scenario_page.dart';
import '../features/settings/asr_config_page.dart';
import '../features/settings/data_settings_page.dart';
import '../features/settings/model_config_page.dart';
import '../features/settings/settings_page.dart';
import '../features/tips/tips_detail_page.dart';
import '../features/tips/tips_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/home', pageBuilder: (_, __) => _fade(const HomePage())),
        GoRoute(path: '/history', pageBuilder: (_, __) => _fade(const HistoryPage())),
        GoRoute(path: '/phrasebook', pageBuilder: (_, __) => _fade(const PhrasebookPage())),
        GoRoute(path: '/me', pageBuilder: (_, __) => _fade(const MePage())),
      ],
    ),
    GoRoute(
      path: '/scenarios',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, _) => _slide(const ScenarioLibraryPage()),
    ),
    GoRoute(
      path: '/scenario/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) => _slide(ScenarioPage(scenarioId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/chat/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) => _slide(ChatPage(sessionId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/review/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) => _slide(ReviewPage(sessionId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, __) => _slide(const SettingsPage()),
    ),
    GoRoute(
      path: '/settings/model',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, __) => _slide(const ModelConfigPage()),
    ),
    GoRoute(
      path: '/settings/asr',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, __) => _slide(const AsrConfigPage()),
    ),
    GoRoute(
      path: '/settings/data',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, __) => _slide(const DataSettingsPage()),
    ),
    GoRoute(
      path: '/tips',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, __) => _slide(const TipsPage()),
    ),
    GoRoute(
      path: '/tips/:id',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (_, state) =>
          _slide(TipsDetailPage(articleId: state.pathParameters['id']!)),
    ),
    GoRoute(path: '/', redirect: (_, __) => '/home'),
  ],
);

Page<void> _fade(Widget child) => CustomTransitionPage<void>(
      key: ValueKey(child.runtimeType),
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

Page<void> _slide(Widget child) => CustomTransitionPage<void>(
      key: ValueKey('${child.runtimeType}_${identityHashCode(child)}'),
      child: child,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );

class KeleApp extends ConsumerWidget {
  const KeleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(settingsControllerProvider);
    return MaterialApp.router(
      title: 'Saylo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
