import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/access_entry_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/client/presentation/screens/client_delivery_screen.dart';
import '../../features/client/presentation/screens/client_home_screen.dart';
import '../../features/client/presentation/screens/client_profile_screen.dart';
import '../../features/client/presentation/screens/client_shell.dart';
import '../../features/client/presentation/screens/client_tracking_screen.dart';
import '../../features/client/presentation/screens/tracking_details_screen.dart';
import '../../features/client/presentation/widgets/client_flow_widgets.dart';
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
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(child: LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => const NoTransitionPage(child: SignupScreen()),
      ),
      GoRoute(
        path: '/access',
        pageBuilder: (context, state) => const NoTransitionPage(child: AccessEntryScreen()),
      ),
      GoRoute(
        path: '/client/tracking/details',
        pageBuilder: (context, state) {
          final shipment = state.extra as TrackingDemoShipment?;
          return NoTransitionPage(
            child: TrackingDetailsScreen(
              shipment: shipment ?? trackingDemoShipments.first,
            ),
          );
        },
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
