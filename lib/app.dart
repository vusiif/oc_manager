import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/main_shell.dart';
import 'features/search/search_page.dart';
import 'features/tag/tag_management_page.dart';
import 'features/trash/drafts_page.dart';
import 'features/trash/trash_page.dart';
import 'features/relation/relation_graph_page.dart';
import 'features/settings/settings_page.dart';
import 'providers/settings_provider.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
    ),
    GoRoute(
      path: '/world/:worldId/graph',
      builder: (context, state) {
        final worldId = int.parse(state.pathParameters['worldId']!);
        return RelationGraphPage(worldId: worldId);
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/tags',
      builder: (context, state) => const TagManagementPage(),
    ),
    GoRoute(
      path: '/drafts',
      builder: (context, state) => const DraftsPage(),
    ),
    GoRoute(
      path: '/trash',
      builder: (context, state) => const TrashPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'OC Manager',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
