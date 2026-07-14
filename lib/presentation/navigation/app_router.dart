import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/root_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/library_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final GlobalKey<NavigatorState> _libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return RootScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _searchNavigatorKey,
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _libraryNavigatorKey,
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
