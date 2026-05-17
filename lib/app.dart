import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/world/world_list_page.dart';
import 'features/world/world_detail_page.dart';
import 'features/character/character_detail_page.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WorldListPage(),
    ),
    GoRoute(
      path: '/world/:id',
      builder: (context, state) {
        final worldId = int.parse(state.pathParameters['id']!);
        return WorldDetailPage(worldId: worldId);
      },
    ),
    GoRoute(
      path: '/world/:worldId/character/:characterId',
      builder: (context, state) {
        final worldId = int.parse(state.pathParameters['worldId']!);
        final characterId = int.parse(state.pathParameters['characterId']!);
        return CharacterDetailPage(
          worldId: worldId,
          characterId: characterId,
        );
      },
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
