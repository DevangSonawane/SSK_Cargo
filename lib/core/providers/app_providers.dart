import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppRole { admin, broker, client, driver }

final selectedRoleProvider = StateProvider<AppRole>((ref) => AppRole.client);
final bottomNavVisibleProvider = StateProvider<bool>((ref) => true);
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

AppRole appRoleFromApiRole(String role) {
  return switch (role) {
    'admin' => AppRole.admin,
    'broker' => AppRole.broker,
    'driver' => AppRole.driver,
    _ => AppRole.client,
  };
}
