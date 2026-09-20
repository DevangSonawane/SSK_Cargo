import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/client_map_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/google_places_provider.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/services/booking_payment_gateway.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../core/widgets/truck_marker_icon.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../shared/data/trip_route_stop.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';

part 'client_flow/location_flow.dart';
part 'client_flow/booking_models_and_shared_widgets.dart';
part 'client_flow/booking_location_screen.dart';
part 'client_flow/truck_search_loader.dart';
part 'client_flow/negotiation_sheets.dart';
part 'client_flow/checkout_and_status_widgets.dart';
part 'client_flow/search_selection_widgets.dart';
part 'client_flow/vehicle_and_bottom_bar.dart';
