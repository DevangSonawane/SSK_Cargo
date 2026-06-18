import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppRole { broker, driver, client }

final selectedRoleProvider = StateProvider<AppRole>((ref) => AppRole.client);
