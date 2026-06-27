import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/access_entry_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/broker/presentation/screens/add_driver_screen.dart';
import '../../features/broker/presentation/screens/add_vehicle_screen.dart';
import '../../features/broker/presentation/screens/broker_history_screen.dart';
import '../../features/broker/presentation/screens/broker_home_screen.dart';
import '../../features/broker/presentation/screens/broker_profile_screen.dart';
import '../../features/broker/presentation/screens/broker_shell.dart';
import '../../features/broker/presentation/screens/broker_tracking_screen.dart';
import '../../features/broker/presentation/screens/broker_vehicles_screen.dart';
import '../../features/broker/presentation/screens/driver_detail_screen.dart';
import '../../features/broker/presentation/widgets/broker_flow_widgets.dart';
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
        path: '/broker/login',
        pageBuilder: (context, state) => const NoTransitionPage(child: BrokerLoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          final initialRole = switch (roleParam) {
            'broker' => SignupRole.broker,
            'client' => SignupRole.client,
            'driver' => SignupRole.driver,
            _ => null,
          };

          return NoTransitionPage(
            child: SignupScreen(initialRole: initialRole),
          );
        },
      ),
      GoRoute(
        path: '/client/signup',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SignupScreen(initialRole: SignupRole.client),
        ),
      ),
      GoRoute(
        path: '/broker/signup',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SignupScreen(initialRole: SignupRole.broker),
        ),
      ),
      GoRoute(
        path: '/driver/signup',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SignupScreen(initialRole: SignupRole.driver),
        ),
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
      GoRoute(
        path: '/broker/profile',
        pageBuilder: (context, state) => const NoTransitionPage(child: BrokerProfileScreen()),
      ),
      GoRoute(
        path: '/broker/vehicles/add',
        pageBuilder: (context, state) => const NoTransitionPage(child: AddVehicleScreen()),
      ),
      GoRoute(
        path: '/broker/drivers/add',
        pageBuilder: (context, state) => const NoTransitionPage(child: AddDriverScreen()),
      ),
      GoRoute(
        path: '/broker/drivers/:id',
        pageBuilder: (context, state) {
          final extraDriver = state.extra as BrokerDriver?;
          final driverId = state.pathParameters['id'];
          final driver = extraDriver ??
              ref.read(brokerDriversProvider).firstWhere(
                    (driver) => driver.id == driverId,
                    orElse: () => mockBrokerDrivers.first,
                  );
          return NoTransitionPage(
            child: DriverDetailScreen(driver: driver),
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BrokerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BrokerHomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/vehicles',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BrokerVehiclesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/tracking',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BrokerTrackingScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/broker/history',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: BrokerHistoryScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
