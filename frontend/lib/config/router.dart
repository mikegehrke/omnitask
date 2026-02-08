import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_layout.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/tasks/task_create_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/profile_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      redirect: (context, state) {
        final isAuth = authProvider.isAuthenticated;
        final isSplash = state.matchedLocation == '/splash';
        final isAuthLocation = state.matchedLocation.startsWith('/auth');

        if (isSplash) return null;

        if (!isAuth && !isAuthLocation) {
          return '/auth/login';
        }

        if (isAuth && isAuthLocation) {
          return '/';
        }

        return null;
      },
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth routes
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main app with bottom navigation
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return HomeLayout(child: child);
          },
          routes: [
            GoRoute(
              path: '/',
              redirect: (context, state) => '/dashboard',
            ),
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/tasks',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const TaskListScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
              ),
            ),
          ],
        ),

        // Task routes (full screen)
        GoRoute(
          path: '/tasks/create',
          builder: (context, state) => const TaskCreateScreen(),
        ),
        GoRoute(
          path: '/tasks/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TaskDetailScreen(taskId: id);
          },
        ),

        // Settings routes
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}
