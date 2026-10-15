import 'dart:developer' as developer;

import '../../features/auth/data/auth_models.dart';
import '../../features/broker/presentation/widgets/broker_flow_widgets.dart';
import '../../features/client/data/client_booking_models.dart';
import '../../features/driver/data/driver_request_models.dart';
import '../network/api_client.dart';
import 'fcm_message_service.dart';

class NotificationDestinationResolver {
  NotificationDestinationResolver(this.api);
  final SskApiClient api;

  Future<NotificationDestination> resolve(
    NotificationIntent intent,
    AuthSession session,
  ) async {
    final role = session.user.role.trim().toLowerCase();
    final history = NotificationDestination(switch (role) {
      'driver' => '/driver/notifications',
      'broker' => '/broker/notifications',
      'client' => '/client/notifications',
      _ => '/gps/profile',
    });
    final access = session.tokens.accessToken;
    try {
      // A sparse push can be enriched from persisted notification metadata.
      if (intent.targetKey == null && intent.notificationId.isNotEmpty) {
        final response = await api.getNotifications(
          accessToken: access,
          limit: 100,
        );
        final payload = _map(response['data']);
        final rows =
            payload['notifications'] ??
            payload['items'] ??
            payload['results'] ??
            payload['rows'] ??
            payload['data'] ??
            response['notifications'] ??
            response['items'] ??
            response['results'] ??
            response['rows'] ??
            response['data'];
        if (rows is List) {
          for (final row in rows.whereType<Map>()) {
            if ((row['id'] ?? row['notification_id'])?.toString() ==
                intent.notificationId) {
              intent = NotificationIntent({
                ...Map<String, dynamic>.from(row),
                'notification_id': intent.notificationId,
              });
              break;
            }
          }
        }
      }
      final key = intent.targetKey;
      final id = key == null ? '' : intent.value(key);
      final encoded = Uri.encodeComponent(id);
      switch (key) {
        case 'driver_request_id':
          if (role == 'broker') {
            return const NotificationDestination('/broker/driver-requests');
          }
          if (role != 'driver') return history;
          final response = await api.getDriverRequestById(
            accessToken: access,
            id: id,
          );
          final request = DriverRequestItem.fromMap(
            _entity(response, ['request', 'driverRequest', 'driver_request']),
          );
          if (request.id != id) return history;
          return NotificationDestination('/driver/request', extra: request);
        case 'job_request_id':
          if (role != 'broker') return history;
          final requests = await fetchAllBrokerJobRequests(
            api,
            accessToken: access,
          );
          for (final request in requests) {
            if (request.id == id) {
              return NotificationDestination('/broker/request', extra: request);
            }
          }
          return const NotificationDestination('/broker/home');
        case 'trip_id':
          if (role == 'driver') {
            return NotificationDestination('/driver/delivery-details/$encoded');
          }
          if (role != 'client' && role != 'broker') return history;
          final response = await api.getTrip(accessToken: access, tripId: id);
          final trip = _entity(response, ['trip']);
          final booking = _map(trip['booking']);
          final bookingId =
              (trip['booking_id'] ?? trip['bookingId'] ?? booking['id'])
                  ?.toString();
          if (bookingId == null || bookingId.isEmpty) return history;
          return await _booking(bookingId, role, access, history);
        case 'booking_id':
          return await _booking(id, role, access, history);
        case 'thread_id':
          final prefix = switch (role) {
            'client' => '/chats',
            'driver' => '/driver/chats',
            'broker' => '/broker/chats',
            _ => null,
          };
          return prefix == null
              ? history
              : NotificationDestination('$prefix/direct/$encoded');
        // There are no standalone incident/dispute screens in this project.
        // A supplied trip_id already takes precedence above.
        default:
          return history;
      }
    } catch (error) {
      // Deleted, expired, inaccessible, or unavailable targets open real history.
      developer.log(
        'Push target unavailable (${error.runtimeType})',
        name: 'SSK.Push',
      );
      return history;
    }
  }

  Future<NotificationDestination> _booking(
    String id,
    String role,
    String access,
    NotificationDestination history,
  ) async {
    if (role == 'driver') {
      return NotificationDestination(
        '/driver/deliveries/${Uri.encodeComponent(id)}',
      );
    }
    if (role != 'client' && role != 'broker') return history;
    final response = await api.getBookingById(accessToken: access, id: id);
    final booking = ClientBooking.fromJson(_entity(response, ['booking']));
    if (booking.id != id) return history;
    return NotificationDestination('/$role/tracking/details', extra: booking);
  }
}

// Socket-driven flows may already have opened this exact entity while the push
// target was loading. Compare IDs as well as paths for routes using extras.
bool notificationDestinationIsOpen(
  NotificationDestination destination,
  String location,
  Object? extra,
) {
  final target = destination.extra;
  if (target is DriverRequestItem &&
      target.tripId.isNotEmpty &&
      location ==
          '/driver/delivery-details/${Uri.encodeComponent(target.tripId)}') {
    return true;
  }
  final samePath =
      destination.location == location ||
      (destination.location == '/driver/request' &&
          location == '/driver/order-accepted');
  if (!samePath) return false;
  if (target == null) return true;
  if (target is DriverRequestItem && extra is DriverRequestItem) {
    return target.id == extra.id;
  }
  if (target is BookingRequest && extra is BookingRequest) {
    return target.id == extra.id;
  }
  if (target is ClientBooking && extra is ClientBooking) {
    return target.id == extra.id;
  }
  return false;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

Map<String, dynamic> _entity(Map<String, dynamic> response, List<String> keys) {
  final data = _map(response['data']);
  for (final source in [data, response]) {
    for (final key in keys) {
      final entity = _map(source[key]);
      if (entity.isNotEmpty) return entity;
    }
  }
  return data.isNotEmpty ? data : response;
}
