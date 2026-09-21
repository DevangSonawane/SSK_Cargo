import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../widgets/broker_flow_widgets.dart';

/// Broker-only live tracking view.
///
/// Mirrors the React web app's broker JobDetail: live map + route + trip
/// progress + driver contact. Deliberately NOT the client
/// [TrackingDetailsScreen] — no Pay now, no rating, no cancel booking,
/// no invoice sharing.
class BrokerTrackLiveScreen extends ConsumerStatefulWidget {
  const BrokerTrackLiveScreen({super.key, required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  ConsumerState<BrokerTrackLiveScreen> createState() =>
      _BrokerTrackLiveScreenState();
}

class _BrokerTrackLiveScreenState
    extends ConsumerState<BrokerTrackLiveScreen> {
  static const _pollInterval = Duration(seconds: 8);

  late TrackingDemoShipment _shipment;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _tripStatusSubscription;

  @override
  void initState() {
    super.initState();
    _shipment = widget.shipment;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startLiveUpdates();
    });
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted) _refreshLivePosition();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tripStatusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) return;
    final socket = ref.read(appSocketServiceProvider);
    await socket.ensureConnected(accessToken: session.tokens.accessToken);
    await _tripStatusSubscription?.cancel();
    _tripStatusSubscription = socket.tripStatusStream.listen((payload) {
      if (!mounted) return;
      if (!_matchesShipment(payload)) return;
      final status = _readString(payload, const [
        'status',
        'trip_status',
        'requestStatus',
        'request_status',
      ]);
      setState(() {
        _shipment = _shipment.copyWith(
          status: status.isEmpty ? _shipment.status : _statusLabel(status),
          bookingStatus: status.isEmpty
              ? _shipment.bookingStatus
              : status.toLowerCase(),
        );
      });
      _refreshLivePosition();
    });
  }

  bool _matchesShipment(Map<String, dynamic> payload) {
    final refs = <String>{
      _shipment.bookingId ?? '',
      _shipment.tripId ?? '',
      _shipment.trackingId,
    }..remove('');
    if (refs.isEmpty) return false;
    for (final key in const [
      'bookingId',
      'booking_id',
      'tripId',
      'trip_id',
      'id',
    ]) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && refs.contains(value)) return true;
    }
    final nested = payload['trip'];
    if (nested is Map) {
      for (final key in const ['bookingId', 'booking_id', 'id']) {
        final value = nested[key]?.toString().trim() ?? '';
        if (value.isNotEmpty && refs.contains(value)) return true;
      }
    }
    return false;
  }

  Future<void> _refreshLivePosition() async {
    final bookingId = _shipment.bookingId?.trim() ?? '';
    final session = ref.read(authSessionProvider).valueOrNull;
    if (bookingId.isEmpty || session == null || !mounted) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBookingTrack(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      final data = response['data'];
      if (data is! Map<String, dynamic>) return;
      final lat = _toDouble(data['driverLat'] ?? data['driver_lat']);
      final lng = _toDouble(data['driverLng'] ?? data['driver_lng']);
      if ((lat == null || lng == null) && !mounted) return;
      if (mounted && (lat != null || lng != null)) {
        setState(() {
          _shipment = _shipment.copyWith(
            liveLat: lat ?? _shipment.liveLat,
            liveLng: lng ?? _shipment.liveLng,
          );
        });
      }
    } catch (_) {
      // Best effort: the map still renders the static route.
    }
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  Future<void> _callDriver() async {
    final phone = _shipment.assignedDriverPhone?.trim() ?? '';
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number is not available.')),
      );
      return;
    }
    final launched = await launchUrl(
      Uri.parse('tel:$phone'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone app.')),
      );
    }
  }

  void _openChat() {
    final bookingId = _shipment.bookingId?.trim() ?? '';
    if (bookingId.isEmpty) {
      context.push('/broker/chats');
    } else {
      context.push('/broker/chats/$bookingId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusKey = (_shipment.bookingStatus ?? _shipment.status)
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    final statusLabel = _statusLabel(_shipment.bookingStatus ?? _shipment.status);
    final statusColor = _trackStatusColor(statusKey);
    final driverName = _shipment.assignedDriverName?.trim() ?? '';
    final driverPhone = _shipment.assignedDriverPhone?.trim() ?? '';
    final truckName = _shipment.assignedTruckName?.trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refreshLivePosition,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  BrokerBackButton(onTap: () => context.pop()),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track Live',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '#${_shipment.trackingId} · $statusLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TrackStatusPill(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 300,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.line),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF101828,
                      ).withValues(alpha: 0.055),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TrackingRouteMapView(
                      shipment: _shipment,
                      liveMode: true,
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE23A4B),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _TrackRouteCard(shipment: _shipment),
              const SizedBox(height: 14),
              _TrackProgressCard(statusKey: statusKey),
              if (driverName.isNotEmpty) ...[
                const SizedBox(height: 14),
                _TrackDriverCard(
                  name: driverName,
                  phone: driverPhone,
                  onCall: _callDriver,
                  onChat: _openChat,
                ),
              ],
              if (truckName.isNotEmpty) ...[
                const SizedBox(height: 14),
                _TrackTruckCard(name: truckName),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openChat,
                      icon: const Icon(
                        AppIcons.chat_bubble_outline_rounded,
                        size: 17,
                      ),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandDark,
                        side: const BorderSide(color: AppColors.brandBorder),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _callDriver,
                      icon: const Icon(AppIcons.phone_rounded, size: 17),
                      label: const Text('Call driver'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackStatusPill extends StatelessWidget {
  const _TrackStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TrackRouteCard extends StatelessWidget {
  const _TrackRouteCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.fillSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrackRailStop(
                  marker: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FA56E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2FA56E,
                          ).withValues(alpha: 0.18),
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  label: 'Pickup',
                  value: shipment.fromLocation.trim().isEmpty
                      ? 'Pickup pending'
                      : shipment.fromLocation.trim(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                _TrackRailStop(
                  marker: const Icon(
                    AppIcons.location_on_rounded,
                    color: Color(0xFF2FA56E),
                    size: 18,
                  ),
                  label: 'Drop-off',
                  value: shipment.toLocation.trim().isEmpty
                      ? 'Drop pending'
                      : shipment.toLocation.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrackMetaTile(
                  icon: AppIcons.scale_outlined,
                  label: 'Weight',
                  value: shipment.weight.trim().isEmpty
                      ? '-'
                      : shipment.weight.trim(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackMetaTile(
                  icon: AppIcons.local_shipping_outlined,
                  label: 'Truck',
                  value:
                      shipment.assignedTruckName?.trim().isEmpty != false
                      ? '-'
                      : shipment.assignedTruckName!.trim(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackRailStop extends StatelessWidget {
  const _TrackRailStop({
    required this.marker,
    required this.label,
    required this.value,
  });

  final Widget marker;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          height: 22,
          child: Align(alignment: Alignment.topCenter, child: marker),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrackMetaTile extends StatelessWidget {
  const _TrackMetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.brandFill,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: const Color(0xFF2FA56E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackProgressCard extends StatelessWidget {
  const _TrackProgressCard({required this.statusKey});

  final String statusKey;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('assigned', 'Assigned'),
      ('en_route_pickup', 'En Route'),
      ('picked_up', 'Picked Up'),
      ('in_transit', 'In Transit'),
      ('delivered', 'Delivered'),
    ];
    final rawIndex = steps.indexWhere((step) => step.$1 == statusKey);
    final activeIndex = rawIndex < 0 ? 0 : rawIndex;
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: i <= activeIndex
                              ? AppColors.brand
                              : colors.line,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[i].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: i <= activeIndex
                              ? AppColors.brand
                              : colors.textTertiary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != steps.length - 1)
                  Container(
                    height: 2,
                    width: 12,
                    color: i < activeIndex ? AppColors.brand : colors.line,
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackDriverCard extends StatelessWidget {
  const _TrackDriverCard({
    required this.name,
    required this.phone,
    required this.onCall,
    required this.onChat,
  });

  final String name;
  final String phone;
  final VoidCallback onCall;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.brandFill,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials.isEmpty ? 'D' : initials,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF2FA56E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onChat,
            icon: const Icon(AppIcons.chat_bubble_outline_rounded, size: 20),
            color: AppColors.brandDark,
            style: IconButton.styleFrom(
              backgroundColor: colors.brandFill,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onCall,
            icon: const Icon(AppIcons.phone_rounded, size: 20),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTruckCard extends StatelessWidget {
  const _TrackTruckCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.brandFill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              AppIcons.local_shipping_outlined,
              color: Color(0xFF2FA56E),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Truck',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _trackStatusColor(String status) {
  return switch (status) {
    'delivered' || 'completed' => AppColors.brand,
    'cancelled' || 'canceled' => AppColors.dangerIcon,
    'confirmed' ||
    'assigned' ||
    'en_route_pickup' ||
    'in_transit' ||
    'picked_up' => AppColors.accentBlue,
    'pending' => const Color(0xFFD97706),
    _ => AppColors.textSecondary,
  };
}

String _statusLabel(String status) {
  final cleaned = status.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (cleaned.isEmpty) return 'In transit';
  return cleaned
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
