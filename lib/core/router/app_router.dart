import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/role_login_screen.dart';
import '../../features/client/presentation/screens/client_delivery_screen.dart';
import '../../features/client/presentation/screens/client_home_screen.dart';
import '../../features/client/presentation/screens/client_profile_screen.dart';
import '../../features/client/presentation/screens/client_shell.dart';
import '../../features/client/presentation/screens/client_tracking_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(child: RoleLoginScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ClientShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientHomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/delivery',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientDeliveryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/tracking',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientTrackingScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/client/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
