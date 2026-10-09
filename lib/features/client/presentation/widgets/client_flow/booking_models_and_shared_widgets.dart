part of '../client_flow_widgets.dart';

class BookingData {
  const BookingData({
    required this.from,
    required this.to,
    required this.tripType,
    this.city = '',
    this.vehicle,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.loadingStops = const [],
    this.unloadingStops = const [],
    this.material = '',
    this.additionalNotes = '',
    this.weight = 0,
    this.quantity = 1,
    this.weightUnit = 'tons',
    this.truckCategory = '',
    this.truckBodyType = '',
    this.scheduledDate,
    this.distance = 0,
    this.durationMin,
    this.durationInTrafficMin,
    this.amount = 0,
    this.brokerId = '',
    this.truckId = '',
    this.isScheduled = false,
    this.searchMode,
    this.searchRadiusKm = 15,
    this.selectedBrokerId = '',
    this.paymentMode = PaymentMode.payLater,
    this.selectedPaymentLabel = '',
    this.isExpress = false,
    this.expressSurcharge = 0,
    this.expectedDeliveryHours,
    this.estimatedDeliveryDate,
    this.estimatedDeliveryDays,
    this.expressInsuranceIncluded = false,
  });

  final String from;
  final String to;
  final TripType tripType;
  final String city;
  final VehicleOption? vehicle;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final List<BookingStop> loadingStops;
  final List<BookingStop> unloadingStops;
  final String material;
  final String additionalNotes;
  final double weight;
  final int quantity;
  final String weightUnit;
  final String truckCategory;
  /// Optional open/closed structure filter (`''` = any). Sent as
  /// `truck_body_type` on `POST /api/bookings`, never on the quote call
  /// (pricing doesn't use it). Web parity: BookTruck.jsx `truckBodyType`.
  final String truckBodyType;
  final DateTime? scheduledDate;
  final double distance;
  final int? durationMin;
  final int? durationInTrafficMin;
  final double amount;
  final String brokerId;
  final String truckId;
  final bool isScheduled;
  final BookingSearchMode? searchMode;
  final double searchRadiusKm;
  final String selectedBrokerId;
  final PaymentMode paymentMode;
  final String selectedPaymentLabel;
  final bool isExpress;
  final double expressSurcharge;
  final double? expectedDeliveryHours;
  final DateTime? estimatedDeliveryDate;
  final int? estimatedDeliveryDays;
  final bool expressInsuranceIncluded;

  String get transportType =>
      tripType == TripType.interCity ? 'inter' : 'intra';
  String get truckType => vehicle?.label ?? '';
  String get weightText => weight > 0 ? '$weight $weightUnit' : '';
  String get distanceText => distance > 0
      ? '${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km'
      : '';
  String get amountText =>
      amount > 0 ? '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}' : '';

  BookingData copyWith({
    String? from,
    String? to,
    TripType? tripType,
    String? city,
    VehicleOption? vehicle,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    List<BookingStop>? loadingStops,
    List<BookingStop>? unloadingStops,
    String? material,
    String? additionalNotes,
    double? weight,
    int? quantity,
    String? weightUnit,
    String? truckCategory,
    String? truckBodyType,
    DateTime? scheduledDate,
    double? distance,
    int? durationMin,
    int? durationInTrafficMin,
    double? amount,
    String? brokerId,
    String? truckId,
    bool? isScheduled,
    BookingSearchMode? searchMode,
    double? searchRadiusKm,
    String? selectedBrokerId,
    PaymentMode? paymentMode,
    String? selectedPaymentLabel,
    bool? isExpress,
    double? expressSurcharge,
    double? expectedDeliveryHours,
    DateTime? estimatedDeliveryDate,
    int? estimatedDeliveryDays,
    bool? expressInsuranceIncluded,
  }) {
    return BookingData(
      from: from ?? this.from,
      to: to ?? this.to,
      tripType: tripType ?? this.tripType,
      city: city ?? this.city,
      vehicle: vehicle ?? this.vehicle,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      loadingStops: loadingStops ?? this.loadingStops,
      unloadingStops: unloadingStops ?? this.unloadingStops,
      material: material ?? this.material,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      weightUnit: weightUnit ?? this.weightUnit,
      truckCategory: truckCategory ?? this.truckCategory,
      truckBodyType: truckBodyType ?? this.truckBodyType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      distance: distance ?? this.distance,
      durationMin: durationMin ?? this.durationMin,
      durationInTrafficMin: durationInTrafficMin ?? this.durationInTrafficMin,
      amount: amount ?? this.amount,
      brokerId: brokerId ?? this.brokerId,
      truckId: truckId ?? this.truckId,
      isScheduled: isScheduled ?? this.isScheduled,
      searchMode: searchMode ?? this.searchMode,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      selectedBrokerId: selectedBrokerId ?? this.selectedBrokerId,
      paymentMode: paymentMode ?? this.paymentMode,
      selectedPaymentLabel: selectedPaymentLabel ?? this.selectedPaymentLabel,
      isExpress: isExpress ?? this.isExpress,
      expressSurcharge: expressSurcharge ?? this.expressSurcharge,
      expectedDeliveryHours:
          expectedDeliveryHours ?? this.expectedDeliveryHours,
      estimatedDeliveryDate:
          estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      estimatedDeliveryDays:
          estimatedDeliveryDays ?? this.estimatedDeliveryDays,
      expressInsuranceIncluded:
          expressInsuranceIncluded ?? this.expressInsuranceIncluded,
    );
  }
}

double? _routeDistanceKm(Iterable<LatLng> points) {
  final values = points.toList(growable: false);
  if (values.length < 2) {
    return null;
  }

  var meters = 0.0;
  for (var index = 1; index < values.length; index++) {
    final previous = values[index - 1];
    final current = values[index];
    meters += Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
  }
  return meters / 1000;
}

class _IntermediateStopsList extends StatelessWidget {
  const _IntermediateStopsList({
    required this.loadingStops,
    required this.unloadingStops,
    required this.onRemoveLoading,
    required this.onRemoveUnloading,
  });

  final List<BookingStop> loadingStops;
  final List<BookingStop> unloadingStops;
  final ValueChanged<int> onRemoveLoading;
  final ValueChanged<int> onRemoveUnloading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final children = <Widget>[
      for (var index = 0; index < loadingStops.length; index++)
        _IntermediateStopTile(
          label: l10n.loadingPointNumber(index + 1),
          location: loadingStops[index].location,
          icon: AppIcons.inventory_2_outlined,
          color: context.colors.warningEmphasis,
          onRemove: () => onRemoveLoading(index),
        ),
      for (var index = 0; index < unloadingStops.length; index++)
        _IntermediateStopTile(
          label: l10n.unloadingPointNumber(index + 1),
          location: unloadingStops[index].location,
          icon: AppIcons.inventory_2_rounded,
          color: const Color(0xFFE35A62),
          onRemove: () => onRemoveUnloading(index),
        ),
    ];

    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: 8),
          children[index],
        ],
      ],
    );
  }
}

class _IntermediateStopTile extends StatelessWidget {
  const _IntermediateStopTile({
    required this.label,
    required this.location,
    required this.icon,
    required this.color,
    required this.onRemove,
  });

  final String label;
  final String location;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.fillSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(AppIcons.close_rounded, size: 18),
            tooltip: l10n.clientBookingRemoveStopTooltip,
            color: context.colors.textSecondary,
          ),
        ],
      ),
    );
  }
}

enum PaymentMode { payNow, payLater }

enum PaymentMethod {
  googlePay,
  phonePe,
  paytm,
  otherUpi,
  card,
  cashOnDelivery,
  netBanking,
  emi,
  payLater,
  advance,
  toBeBilled,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    return switch (this) {
      PaymentMethod.googlePay => 'Google Pay',
      PaymentMethod.phonePe => 'PhonePe',
      PaymentMethod.paytm => 'PayTM',
      PaymentMethod.otherUpi => 'Other UPI',
      PaymentMethod.card => 'Card',
      PaymentMethod.cashOnDelivery => 'Cash On Delivery',
      PaymentMethod.netBanking => 'Net Banking',
      PaymentMethod.emi => 'EMI',
      PaymentMethod.payLater => 'To Pay',
      PaymentMethod.advance => 'Advance',
      PaymentMethod.toBeBilled => 'To Be Billed',
    };
  }
}

class TruckSize {
  const TruckSize({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class VehicleOption {
  const VehicleOption({
    this.id = '',
    required this.label,
    required this.capacity,
    required this.price,
    required this.accentColor,
    required this.assetPath,
  });

  /// The real `truck_category` string sent to the backend (e.g. `14ft`,
  /// `tata_ace`, `part`). Never derive this back out of [label] — see
  /// `truckCategoryForVehicleOption` below.
  final String id;
  final String label;
  final String capacity;
  final String price;
  final Color accentColor;
  final String assetPath;
}

/// Closest of the 4 bundled artworks for a truck category — no per-type art
/// exists in this app (same constraint as web's `truckImages.js` fix), so the
/// 8 new types share the nearest size: small pickups → small art,
/// 10ft/14ft → medium art, 17ft+ → big art.
String assetPathForTruckCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case '3_wheeler':
    case '3-wheeler':
    case '3 wheeler':
    case 'tata_ace':
    case 'tata-ace':
    case 'tata ace':
    case 'pickup_8ft':
    case 'pickup-8ft':
    case 'pickup 8ft':
    case 'small':
      return 'assets/trucks/small truck.png';
    case 'pickup_10ft':
    case 'pickup-10ft':
    case 'pickup 10ft':
    case '14ft':
    case '14 ft':
    case 'medium':
      return 'assets/trucks/medium truck.png';
    case '17ft':
    case '17 ft':
    case '19ft':
    case '19 ft':
    case '22ft':
    case '22 ft':
    case '32ft_sxl':
    case '32ft-sxl':
    case '32ft sxl':
    case '32ft_mxl':
    case '32ft-mxl':
    case '32ft mxl':
    case 'large':
    case 'big':
      return 'assets/trucks/big truck.png';
    case 'part':
    case 'pooling':
    case 'truck pooling':
    case 'part load':
      return 'assets/trucks/truck pooling.png';
    default:
      return 'assets/trucks/big truck.png';
  }
}

Color accentColorForTruckCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case '3_wheeler':
    case '3-wheeler':
    case '3 wheeler':
    case 'tata_ace':
    case 'tata-ace':
    case 'tata ace':
    case 'pickup_8ft':
    case 'pickup-8ft':
    case 'pickup 8ft':
    case 'small':
      return const Color(0xFF2FA56E);
    case 'pickup_10ft':
    case 'pickup-10ft':
    case 'pickup 10ft':
    case '14ft':
    case '14 ft':
    case 'medium':
      return const Color(0xFF1F88C9);
    case '17ft':
    case '17 ft':
    case '19ft':
    case '19 ft':
    case '22ft':
    case '22 ft':
    case '32ft_sxl':
    case '32ft-sxl':
    case '32ft sxl':
    case '32ft_mxl':
    case '32ft-mxl':
    case '32ft mxl':
    case 'large':
    case 'big':
      return const Color(0xFF7A5AF8);
    default:
      return const Color(0xFFF59E0B);
  }
}

/// Human label for a category when the API didn't supply one (fleet rows for
/// trucks registered via web/admin, old categories, etc.).
String labelForTruckCategory(
  String category, [
  String fallback = '',
  AppLocalizations? l10n,
]) {
  switch (category.trim().toLowerCase()) {
    case '3_wheeler':
    case '3-wheeler':
    case '3 wheeler':
      return '3 Wheeler';
    case 'tata_ace':
    case 'tata-ace':
    case 'tata ace':
      return l10n?.vehicleOptionTataAce ?? 'Tata Ace';
    case 'pickup_8ft':
    case 'pickup-8ft':
    case 'pickup 8ft':
      return l10n?.vehicleOptionPickup8ft ?? 'Pickup 8ft';
    case 'pickup_10ft':
    case 'pickup-10ft':
    case 'pickup 10ft':
      return l10n?.vehicleOptionPickup10ft ?? 'Pickup 10ft';
    case '14ft':
    case '14 ft':
      return l10n?.vehicleOption14ftTruck ?? '14ft Truck';
    case '17ft':
    case '17 ft':
      return l10n?.vehicleOption17ftTruck ?? '17ft Truck';
    case '19ft':
    case '19 ft':
      return l10n?.vehicleOption19ftTruck ?? '19ft Truck';
    case '22ft':
    case '22 ft':
      return l10n?.vehicleOption22ftTruck ?? '22ft Truck';
    case '32ft_sxl':
    case '32ft-sxl':
    case '32ft sxl':
      return '32ft SXL';
    case '32ft_mxl':
    case '32ft-mxl':
    case '32ft mxl':
      return '32ft MXL';
    case 'small':
      return l10n?.vehicleSmallTruck ?? 'Small truck';
    case 'medium':
      return l10n?.vehicleMediumTruck ?? 'Medium truck';
    case 'large':
    case 'big':
      return l10n?.vehicleBigTruck ?? 'Big truck';
    case 'part':
    case 'pooling':
    case 'truck pooling':
      return l10n?.vehicleOptionPartLoad ?? 'Part load';
    case 'part load':
      return l10n?.vehicleOptionPartLoad ?? 'Part load';
    default:
      if (fallback.trim().isNotEmpty) return fallback;
      if (category.trim().isEmpty) return 'Truck';
      final pretty = category
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
      return pretty.isEmpty ? 'Truck' : pretty;
  }
}

/// Builds picker options from live vehicle-types — `id` → category to send,
/// `name` → display label, `capacity` → subtitle, `basePrice` → card price
/// (same as web: the response already carries the correct per-type minimum
/// fare, no separate pricing call needed). Null/zero `basePrice` (e.g.
/// `part`) shows a non-numeric placeholder so no fake fare is displayed.
List<VehicleOption> vehicleOptionsFromTypes(
  List<VehicleType> types, [
  AppLocalizations? l10n,
]) {
  return types
      .map((t) {
        final price = (t.basePrice != null && t.basePrice! > 0)
            ? _formatRupees(t.basePrice!)
            : (t.id.trim().toLowerCase() == 'part'
                  ? (l10n?.vehiclePriceShared ?? 'Shared')
                  : (l10n?.vehiclePriceOnRequest ?? 'On request'));
        return VehicleOption(
          id: t.id,
          label: t.name.isNotEmpty
              ? t.name
              : labelForTruckCategory(t.id, '', l10n),
          capacity: t.capacity,
          price: price,
          accentColor: accentColorForTruckCategory(t.id),
          assetPath: assetPathForTruckCategory(t.id),
        );
      })
      .toList(growable: false);
}

/// The category string to send for a picked option — always the option's own
/// `id`, never guessed back out of its display label.
String truckCategoryForVehicleOption(VehicleOption? option) {
  return option?.id.trim() ?? '';
}

/// Legacy-aware wrapper: prefers the option's own `id`; only falls back to
/// label matching for options built before `id` existed (old persisted
/// drafts, old hardcoded entries). Covers both the old 4 labels and the 8
/// new type labels so nothing ever sends an empty category.
String categoryForVehicleOption(VehicleOption? option) {
  final id = truckCategoryForVehicleOption(option);
  if (id.isNotEmpty) return id;
  final text = (option?.label ?? '').toLowerCase();
  if (text.contains('3 wheeler') || text.contains('3_wheeler')) {
    return '3_wheeler';
  }
  if (text.contains('tata ace') || text.contains('tata_ace')) return 'tata_ace';
  if (text.contains('pickup 8') || text.contains('pickup_8')) {
    return 'pickup_8ft';
  }
  if (text.contains('pickup 10') || text.contains('pickup_10')) {
    return 'pickup_10ft';
  }
  if (text.contains('32ft sxl') ||
      text.contains('32ft_sxl') ||
      text.contains('32ft-sxl')) {
    return '32ft_sxl';
  }
  if (text.contains('32ft mxl') ||
      text.contains('32ft_mxl') ||
      text.contains('32ft-mxl')) {
    return '32ft_mxl';
  }
  if (text.contains('32ft') || text.contains('32 ft')) return '32ft_mxl';
  if (text.contains('22ft') || text.contains('22 ft')) return '22ft';
  if (text.contains('19ft') || text.contains('19 ft')) return '19ft';
  if (text.contains('17ft') || text.contains('17 ft')) return '17ft';
  if (text.contains('14ft') || text.contains('14 ft')) return '14ft';
  if (text.contains('small')) return 'small';
  if (text.contains('medium')) return 'medium';
  if (text.contains('big') || text.contains('large')) return 'large';
  if (text.contains('part') || text.contains('pool')) return 'part';
  return '';
}

const vehicleOptions = <VehicleOption>[
  VehicleOption(
    id: 'small',
    label: 'Small truck',
    capacity: 'Up to 1 Ton',
    price: '₹899',
    accentColor: Color(0xFF2FA56E),
    assetPath: 'assets/trucks/small truck.png',
  ),
  VehicleOption(
    id: 'medium',
    label: 'Medium truck',
    capacity: '1 - 5 Tons',
    price: '₹1,499',
    accentColor: Color(0xFF1F88C9),
    assetPath: 'assets/trucks/medium truck.png',
  ),
  VehicleOption(
    id: 'large',
    label: 'Big truck',
    capacity: '5 - 15 Tons',
    price: '₹2,299',
    accentColor: Color(0xFF7A5AF8),
    assetPath: 'assets/trucks/big truck.png',
  ),
  VehicleOption(
    id: 'part',
    label: 'Truck pooling',
    capacity: 'Shared Space',
    price: '₹499',
    accentColor: Color(0xFFF59E0B),
    assetPath: 'assets/trucks/truck pooling.png',
  ),
];

String localizedVehicleOptionLabel(
  AppLocalizations l10n,
  VehicleOption option,
) {
  switch (option.id.trim().toLowerCase()) {
    case 'small':
      return l10n.vehicleSmallTruck;
    case '3_wheeler':
    case '3-wheeler':
    case '3 wheeler':
      return l10n.vehicleOption3Wheeler;
    case 'medium':
      return l10n.vehicleMediumTruck;
    case 'large':
    case 'big':
      return l10n.vehicleBigTruck;
    case 'part':
    case 'pooling':
    case 'truck pooling':
    case 'part load':
      return l10n.vehicleTruckPooling;
    case 'tata_ace':
    case 'tata-ace':
    case 'tata ace':
      return l10n.vehicleOptionTataAce;
    case 'pickup_8ft':
    case 'pickup-8ft':
    case 'pickup 8ft':
      return l10n.vehicleOptionPickup8ft;
    case 'pickup_10ft':
    case 'pickup-10ft':
    case 'pickup 10ft':
      return l10n.vehicleOptionPickup10ft;
    case '14ft':
    case '14 ft':
      return l10n.vehicleOption14ftTruck;
    case '17ft':
    case '17 ft':
      return l10n.vehicleOption17ftTruck;
    case '19ft':
    case '19 ft':
      return l10n.vehicleOption19ftTruck;
    case '22ft':
    case '22 ft':
      return l10n.vehicleOption22ftTruck;
    case '32ft_sxl':
    case '32ft-sxl':
    case '32ft sxl':
      return option.label.isNotEmpty ? option.label : '32ft SXL';
    case '32ft_mxl':
    case '32ft-mxl':
    case '32ft mxl':
      return option.label.isNotEmpty ? option.label : '32ft MXL';
    default:
      return option.label;
  }
}

/// Optional Open/Closed truck-structure picker (web parity: BookTruck.jsx
/// Step 3 "Truck Structure (optional)" + broker Trucks.jsx "Truck Structure"
/// dropdown). Two cards, same visual weight as the size grid; tapping the
/// active card clears the selection (null = not specified, field omitted).
class TruckBodyTypePicker extends StatelessWidget {
  const TruckBodyTypePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Normalized `open`/`closed` or `''` when unset.
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = TruckBodyType.normalize(selected);
    return Row(
      children: [
        Expanded(
          child: _TruckBodyTypeCard(
            value: TruckBodyType.open,
            label: 'Open Truck',
            icon: AppIcons.inbox_rounded,
            selected: current == TruckBodyType.open,
            onTap: () => onChanged(
              current == TruckBodyType.open ? '' : TruckBodyType.open,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TruckBodyTypeCard(
            value: TruckBodyType.closed,
            label: 'Closed Truck',
            icon: AppIcons.inventory_2_rounded,
            selected: current == TruckBodyType.closed,
            onTap: () => onChanged(
              current == TruckBodyType.closed ? '' : TruckBodyType.closed,
            ),
          ),
        ),
      ],
    );
  }
}

class _TruckBodyTypeCard extends StatelessWidget {
  const _TruckBodyTypeCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: selected ? context.colors.brandFill : context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : context.colors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? const Color(0xFF2FA56E)
                  : context.colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? context.colors.brandEmphasis
                      : context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (selected)
              const Icon(
                AppIcons.check_rounded,
                color: Color(0xFF2FA56E),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// Small "Open"/"Closed" tag shown next to a truck's size label wherever
/// truck details are displayed. Renders nothing when [bodyType] is unset —
/// most existing trucks have none until their owner edits them.
class TruckBodyTypeTag extends StatelessWidget {
  const TruckBodyTypeTag({super.key, required this.bodyType});

  final String bodyType;

  @override
  Widget build(BuildContext context) {
    final normalized = TruckBodyType.normalize(bodyType);
    if (normalized.isEmpty) return const SizedBox.shrink();
    final label = TruckBodyType.labelFor(normalized);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.brandBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.colors.brandEmphasis,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}


String localizedPaymentStatus(
  AppLocalizations l10n,
  String status,
) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) {
    return l10n.pending;
  }
  switch (normalized) {
    case 'paid':
      return l10n.thankYouPaid;
    case 'pending':
      return l10n.pending;
    case 'failed':
      return l10n.paymentStatusFailed;
    case 'refunded':
      return l10n.paymentStatusRefunded;
    case 'partial':
    case 'partially_paid':
      return l10n.paymentStatusPartiallyPaid;
    default:
      return normalized
          .split(RegExp(r'[_\s-]+'))
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
  }
}

List<VehicleOption> resolveVehicleOptions({
  required TripType tripType,
  ClientPricingConfig? pricing,
  required bool isLoading,
  List<VehicleType>? vehicleTypes,
  AppLocalizations? l10n,
}) {
  // Live taxonomy (web parity: built from GET /api/config/vehicle-types).
  // Takes precedence over the legacy hardcoded list + admin-pricing tiers —
  // the response already carries the correct per-type `basePrice`.
  if (vehicleTypes != null && vehicleTypes.isNotEmpty) {
    if (isLoading) {
      return vehicleOptionsFromTypes(vehicleTypes, l10n)
          .map(
            (vehicle) => VehicleOption(
              id: vehicle.id,
              label: vehicle.label,
              capacity: vehicle.capacity,
              price: l10n?.loading ?? 'Loading...',
              accentColor: vehicle.accentColor,
              assetPath: vehicle.assetPath,
            ),
          )
          .toList(growable: false);
    }
    return vehicleOptionsFromTypes(vehicleTypes, l10n);
  }

  if (isLoading) {
    return vehicleOptions
        .map(
          (vehicle) => VehicleOption(
            id: vehicle.id,
            label: vehicle.label,
            capacity: vehicle.capacity,
            price: l10n?.loading ?? 'Loading...',
            accentColor: vehicle.accentColor,
            assetPath: vehicle.assetPath,
          ),
        )
        .toList(growable: false);
  }

  if (pricing == null) {
    return vehicleOptions;
  }

  return vehicleOptions
      .map(
        (vehicle) => VehicleOption(
          id: vehicle.id,
          label: vehicle.label,
          capacity: vehicle.capacity,
          price: _vehiclePriceLabel(
            label: vehicle.label,
            tripType: tripType,
            pricing: pricing,
            fallback: vehicle.price,
            l10n: l10n,
          ),
          accentColor: vehicle.accentColor,
          assetPath: vehicle.assetPath,
        ),
      )
      .toList(growable: false);
}

String _vehiclePriceLabel({
  required String label,
  required TripType tripType,
  required ClientPricingConfig pricing,
  required String fallback,
  AppLocalizations? l10n,
}) {
  if (tripType == TripType.intraCity) {
    final tier = _intraCityTierForVehicle(pricing, label);
    final baseFare = tier?.baseFare ?? 0;
    if (baseFare > 0) {
      final toll = tier?.tollFixedAmount ?? 0;
      if (toll > 0) {
        final base = _formatRupees(baseFare);
        final tollText = _formatRupees(toll);
        return l10n?.vehiclePriceWithToll(base, tollText) ??
            '$base + toll $tollText';
      }
      return _formatRupees(baseFare);
    }
    return fallback;
  }

  final interCityRate = pricing.interCity.baseRatePerKm;
  if (interCityRate > 0) {
    return '${_formatRupees(interCityRate)}/km';
  }

  return fallback;
}

String _formatRupees(double amount) {
  return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
}

String _formatHours(double hours) {
  return '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h';
}

String _formatDateTime(DateTime value) {
  final hour12 = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day}/${value.month}/${value.year} at $hour12:$minute $period';
}

String _formatDateOnly(DateTime value) {
  return '${value.day}/${value.month}/${value.year}';
}

ClientTruckPricingTier? _intraCityTierForVehicle(
  ClientPricingConfig pricing,
  String label,
) {
  final text = label.toLowerCase();
  if (text.contains('small')) return pricing.intraCity.small;
  if (text.contains('medium')) return pricing.intraCity.medium;
  if (text.contains('big') || text.contains('large')) {
    return pricing.intraCity.large;
  }
  return pricing.intraCity.small;
}

class TrackingDemoShipment {
  const TrackingDemoShipment({
    required this.packageName,
    required this.trackingId,
    required this.fromLocation,
    required this.toLocation,
    required this.status,
    required this.customerName,
    required this.weight,
    required this.timeline,
    this.amount = 0,
    this.amountPaid = 0,
    this.paymentStatus = 'pending',
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.liveLat,
    this.liveLng,
    this.podUrl,
    this.podMedia = const [],
    this.podStatus,
    this.podRejectionReason,
    this.ratingStars,
    this.tripId,
    this.bookingId,
    this.bookingStatus,
    this.assignedDriverName,
    this.assignedDriverPhone,
    this.assignedTruckName,
    this.pickupOtp,
    this.pickupOtpVerified = false,
    this.isExpress = false,
    this.expectedDeliveryHours,
    this.estimatedDeliveryDate,
    this.estimatedDeliveryDays,
    this.slaOverageHours = 0,
    this.slaOverageCharge = 0,
    this.tripStartedAt,
    this.haltingGraceHours,
    this.haltingHours = 0,
    this.haltingCharge = 0,
    this.stops = const [],
  });

  TrackingDemoShipment copyWith({
    String? packageName,
    String? trackingId,
    String? fromLocation,
    String? toLocation,
    String? status,
    String? customerName,
    String? weight,
    List<TrackingTimelineStep>? timeline,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    double? liveLat,
    double? liveLng,
    String? bookingId,
    String? bookingStatus,
    String? assignedDriverName,
    String? assignedDriverPhone,
    String? assignedTruckName,
    String? tripId,
    double? amount,
    double? amountPaid,
    String? paymentStatus,
    String? podUrl,
    List<PodDeliveryMedia>? podMedia,
    String? podStatus,
    String? podRejectionReason,
    int? ratingStars,
    String? pickupOtp,
    bool? pickupOtpVerified,
    bool? isExpress,
    double? expectedDeliveryHours,
    DateTime? estimatedDeliveryDate,
    int? estimatedDeliveryDays,
    double? slaOverageHours,
    double? slaOverageCharge,
    DateTime? tripStartedAt,
    double? haltingGraceHours,
    double? haltingHours,
    double? haltingCharge,
    List<TripRouteStop>? stops,
    bool clearPickupLat = false,
    bool clearPickupLng = false,
    bool clearDropLat = false,
    bool clearDropLng = false,
    bool clearLiveLat = false,
    bool clearLiveLng = false,
  }) {
    return TrackingDemoShipment(
      packageName: packageName ?? this.packageName,
      trackingId: trackingId ?? this.trackingId,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      weight: weight ?? this.weight,
      timeline: timeline ?? this.timeline,
      pickupLat: clearPickupLat ? null : (pickupLat ?? this.pickupLat),
      pickupLng: clearPickupLng ? null : (pickupLng ?? this.pickupLng),
      dropLat: clearDropLat ? null : (dropLat ?? this.dropLat),
      dropLng: clearDropLng ? null : (dropLng ?? this.dropLng),
      liveLat: clearLiveLat ? null : (liveLat ?? this.liveLat),
      liveLng: clearLiveLng ? null : (liveLng ?? this.liveLng),
      podUrl: podUrl ?? this.podUrl,
      podMedia: podMedia ?? this.podMedia,
      podStatus: podStatus ?? this.podStatus,
      podRejectionReason: podRejectionReason ?? this.podRejectionReason,
      ratingStars: ratingStars ?? this.ratingStars,
      tripId: tripId ?? this.tripId,
      bookingId: bookingId ?? this.bookingId,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedDriverPhone: assignedDriverPhone ?? this.assignedDriverPhone,
      assignedTruckName: assignedTruckName ?? this.assignedTruckName,
      pickupOtp: pickupOtp ?? this.pickupOtp,
      pickupOtpVerified: pickupOtpVerified ?? this.pickupOtpVerified,
      isExpress: isExpress ?? this.isExpress,
      expectedDeliveryHours:
          expectedDeliveryHours ?? this.expectedDeliveryHours,
      estimatedDeliveryDate:
          estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      estimatedDeliveryDays:
          estimatedDeliveryDays ?? this.estimatedDeliveryDays,
      slaOverageHours: slaOverageHours ?? this.slaOverageHours,
      slaOverageCharge: slaOverageCharge ?? this.slaOverageCharge,
      tripStartedAt: tripStartedAt ?? this.tripStartedAt,
      haltingGraceHours: haltingGraceHours ?? this.haltingGraceHours,
      haltingHours: haltingHours ?? this.haltingHours,
      haltingCharge: haltingCharge ?? this.haltingCharge,
      stops: stops ?? this.stops,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  final String packageName;
  final String trackingId;
  final String fromLocation;
  final String toLocation;
  final String status;
  final String customerName;
  final String weight;
  final List<TrackingTimelineStep> timeline;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final double? liveLat;
  final double? liveLng;
  final double amount;
  final double amountPaid;
  final String paymentStatus;
  final String? podUrl;
  final List<PodDeliveryMedia> podMedia;
  final String? podStatus;
  final String? podRejectionReason;
  final int? ratingStars;
  final String? tripId;
  final String? bookingId;
  final String? bookingStatus;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final String? assignedTruckName;
  final String? pickupOtp;
  final bool pickupOtpVerified;
  final bool isExpress;
  final double? expectedDeliveryHours;
  final DateTime? estimatedDeliveryDate;
  final int? estimatedDeliveryDays;
  final double slaOverageHours;
  final double slaOverageCharge;
  final DateTime? tripStartedAt;
  final double? haltingGraceHours;
  final double haltingHours;
  final double haltingCharge;
  final List<TripRouteStop> stops;
}

class PodDeliveryMedia {
  const PodDeliveryMedia({required this.url, required this.type});

  final String url;
  final String type;

  bool get isVideo => type.trim().toLowerCase() == 'video';
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

String formatPaymentStatus(String status, [AppLocalizations? l10n]) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) {
    return l10n?.statusPending ?? 'Pending';
  }
  switch (normalized) {
    case 'paid':
      return l10n?.thankYouPaid ?? 'Paid';
    case 'pending':
      return l10n?.statusPending ?? 'Pending';
    case 'failed':
      return l10n?.paymentStatusFailed ?? 'Failed';
    case 'refunded':
      return l10n?.paymentStatusRefunded ?? 'Refunded';
    case 'partial':
    case 'partially_paid':
      return l10n?.paymentStatusPartiallyPaid ?? 'Partially paid';
    default:
      return normalized
          .split(RegExp(r'[_\s-]+'))
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
  }
}

class TrackingTimelineStep {
  const TrackingTimelineStep({
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  final String title;
  final String subtitle;
  final bool completed;

  /// Display-only mapping. Timeline steps are built inside pure data-layer
  /// functions (no BuildContext / l10n available there), so the raw [title]
  /// stays English and is translated here at render time. Unknown titles fall
  /// through unchanged.
  String titleDisplay(AppLocalizations l10n) {
    switch (title) {
      case 'Assigned':
        return l10n.brokerActiveJobAssigned;
      case 'En Route Pickup':
        return l10n.brokerActiveJobEnRoutePickup;
      case 'Picked Up':
      case 'Picked up':
        return l10n.brokerActiveJobPickedUp;
      case 'In Transit':
      case 'In transit':
        return l10n.brokerActiveJobInTransit;
      case 'Delivered':
        return l10n.brokerActiveJobDelivered;
      case 'Request received':
        return l10n.brokerFlowRequestReceived;
      case 'Driver request sent':
        return l10n.brokerFlowDriverRequestSent;
      case 'Driver response':
        return l10n.brokerFlowDriverResponse;
      case 'Driver timed out':
        return l10n.brokerFlowDriverTimedOut;
      case 'Broker negotiation':
        return l10n.brokerFlowBrokerNegotiation;
      default:
        return title;
    }
  }

  String subtitleDisplay(AppLocalizations l10n) {
    switch (subtitle) {
      case 'Driver assigned':
        return l10n.brokerActiveJobDriverAssigned;
      case 'Driver heading to pickup':
        return l10n.brokerActiveJobDriverHeadingToPickup;
      case 'Shipment picked up':
        return l10n.brokerActiveJobShipmentPickedUp;
      case 'Shipment on the road':
        return l10n.brokerActiveJobShipmentOnRoad;
      case 'Drop completed':
        return l10n.brokerActiveJobDropCompleted;
      case 'Completed successfully':
        return l10n.driverTimelineCompletedSuccessfully;
      case 'Broker inbox':
        return l10n.brokerFlowBrokerInbox;
      case 'Assignment pending':
        return l10n.brokerFlowAssignmentPending;
      case 'Vehicle assignment pending':
        return l10n.brokerFlowVehicleAssignmentPending;
      case 'Awaiting pickup':
        return l10n.brokerFlowAwaitingPickup;
      case 'Pending':
        return l10n.statusPending;
      case 'Pickup location not provided':
        return l10n.savedAddressPickupLocationNotProvided;
      case 'Drop-off location not provided':
        return l10n.savedAddressDropoffLocationNotProvided;
      case 'Broker handoff is active':
        return l10n.brokerFlowHandoffActive;
      case 'Waiting':
        return l10n.brokerFlowWaiting;
      case 'Truck assignment confirmed':
        return l10n.brokerFlowTruckAssignmentConfirmed;
      case 'Awaiting broker action':
        return l10n.brokerFlowAwaitingBrokerAction;
      default:
        return subtitle;
    }
  }
}

class PickupOtpBanner extends StatelessWidget {
  const PickupOtpBanner({
    super.key,
    required this.pickupOtp,
    required this.pickupOtpVerified,
  });

  final String? pickupOtp;
  final bool pickupOtpVerified;

  @override
  Widget build(BuildContext context) {
    final otp = pickupOtp?.trim();
    if (otp == null || otp.isEmpty) {
      return const SizedBox.shrink();
    }

    final isVerified = pickupOtpVerified;
    final l10n = AppLocalizations.of(context)!;
    final backgroundColor = isVerified
        ? context.colors.brandFill
        : const Color(0xFFFFF6DB);
    final borderColor = isVerified
        ? context.colors.brandBorder
        : const Color(0xFFF3DC8C);
    final accentColor = isVerified
        ? const Color(0xFF2FA56E)
        : const Color(0xFFB88900);
    final title = isVerified
        ? l10n.pickupOtpVerifiedTitle
        : l10n.pickupOtpCodeTitle;
    final message = isVerified
        ? l10n.pickupOtpVerifiedMessage
        : l10n.pickupOtpShareMessage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? AppIcons.verified_rounded : AppIcons.key_rounded,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.done,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.35,
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                otp,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

TrackingDemoShipment trackingShipmentFromBooking(
  ClientBooking booking, [
  AppLocalizations? l10n,
]) {
  final status = booking.status.toLowerCase();
  final raw = booking.raw;
  debugPrint(
    '[TrackingShipment] bookingId=${booking.id} '
    'pickup=${_readBookingCoordinate(raw, const ['pickup_lat', 'pickupLat'])},'
    '${_readBookingCoordinate(raw, const ['pickup_lng', 'pickupLng'])} '
    'drop=${_readBookingCoordinate(raw, const ['drop_lat', 'dropLat'])},'
    '${_readBookingCoordinate(raw, const ['drop_lng', 'dropLng'])} '
    'live=${_readBookingCoordinate(raw, const ['current_lat', 'currentLat', 'truck_lat', 'truckLat'])},'
    '${_readBookingCoordinate(raw, const ['current_lng', 'currentLng', 'truck_lng', 'truckLng'])}',
  );
  return TrackingDemoShipment(
    packageName: booking.displayTitle,
    trackingId: booking.bookingRef.isEmpty ? booking.id : booking.bookingRef,
    fromLocation: booking.pickupLocation.isEmpty
        ? (l10n?.pickupLocationNotProvided ?? 'Pickup location not provided')
        : booking.pickupLocation,
    toLocation: booking.dropoffLocation.isEmpty
        ? (l10n?.dropOffLocationNotProvided ?? 'Drop-off location not provided')
        : booking.dropoffLocation,
    status: bookingStatusDisplay(l10n, booking.displayStatusLabel),
    customerName: booking.clientName,
    weight: booking.weight.isEmpty ? booking.vehicleType : booking.weight,
    pickupLat: _readBookingCoordinate(raw, const ['pickup_lat', 'pickupLat']),
    pickupLng: _readBookingCoordinate(raw, const ['pickup_lng', 'pickupLng']),
    dropLat: _readBookingCoordinate(raw, const ['drop_lat', 'dropLat']),
    dropLng: _readBookingCoordinate(raw, const ['drop_lng', 'dropLng']),
    liveLat: _readBookingCoordinate(raw, const [
      'current_lat',
      'currentLat',
      'truck_lat',
      'truckLat',
    ]),
    liveLng: _readBookingCoordinate(raw, const [
      'current_lng',
      'currentLng',
      'truck_lng',
      'truckLng',
    ]),
    pickupOtp: booking.pickupOtp,
    pickupOtpVerified: booking.pickupOtpVerified,
    isExpress: booking.isExpress,
    expectedDeliveryHours: booking.expectedDeliveryHours,
    estimatedDeliveryDate: booking.estimatedDeliveryDate,
    estimatedDeliveryDays: booking.estimatedDeliveryDays,
    slaOverageHours: booking.slaOverageHours ?? 0,
    slaOverageCharge: booking.slaOverageCharge ?? 0,
    tripStartedAt: booking.tripStartedAt,
    haltingGraceHours: booking.haltingGraceHours,
    haltingHours: booking.haltingHours,
    haltingCharge: booking.haltingCharge,
    amount: _readMoneyValue(raw, raw),
    amountPaid:
        _readDoubleValue(raw, raw, const [
          'amount_paid',
          'amountPaid',
          'paid_amount',
          'paidAmount',
        ]) ??
        0,
    paymentStatus: formatPaymentStatus(
      _readString(raw, const ['payment_status', 'paymentStatus']).isEmpty
          ? 'pending'
          : _readString(raw, const ['payment_status', 'paymentStatus']),
    ),
    podUrl: _readString(raw, const ['podUrl', 'pod_url']),
    podMedia: _readPodDeliveryMedia(raw),
    podStatus: _readPodStatus(raw),
    podRejectionReason: _readPodRejectionReason(raw),
    ratingStars: _readRatingStars(raw),
    tripId: _readTripId(raw),
    bookingId: booking.id,
    bookingStatus: status,
    stops: tripRouteStopsFromSource(raw),
    assignedDriverName: booking.raw['driver'] is Map
        ? _readString(
            (booking.raw['driver'] as Map).cast<String, dynamic>(),
            const ['name'],
          )
        : _readString(raw, const ['driverName', 'driver_name']),
    assignedDriverPhone: booking.raw['driver'] is Map
        ? _readString(
            (booking.raw['driver'] as Map).cast<String, dynamic>(),
            const ['phone', 'phoneNumber', 'phone_number'],
          )
        : _readString(raw, const ['driverPhone', 'driver_phone']),
    timeline: _timelineForStatus(status, booking, l10n),
  );
}

String? _readPodStatus(Map<String, dynamic> raw) {
  final trip = raw['trip'];
  if (trip is Map) {
    final fromTrip = _readString(trip.cast<String, dynamic>(), const [
      'podStatus',
      'pod_status',
    ]);
    if (fromTrip.isNotEmpty) return fromTrip.toLowerCase();
  }
  final direct = _readString(raw, const [
    'podStatus',
    'pod_status',
    'pod_status_string',
  ]);
  if (direct.isEmpty) return null;
  return direct.toLowerCase();
}

String? _readPodRejectionReason(Map<String, dynamic> raw) {
  final trip = raw['trip'];
  if (trip is Map) {
    final fromTrip = _readString(trip.cast<String, dynamic>(), const [
      'podRejectionReason',
      'pod_rejection_reason',
      'podRejectReason',
    ]);
    if (fromTrip.isNotEmpty) return fromTrip;
  }
  final direct = _readString(raw, const [
    'podRejectionReason',
    'pod_rejection_reason',
    'podRejectReason',
    'pod_reject_reason',
  ]);
  if (direct.isEmpty) return null;
  return direct;
}

String _readTripId(Map<String, dynamic> raw) {
  final trip = raw['trip'];
  if (trip is Map) {
    final nested = _readString(trip.cast<String, dynamic>(), const [
      'id',
      'tripId',
      'trip_id',
    ]);
    if (nested.isNotEmpty) return nested;
  }
  return _readString(raw, const [
    'tripId',
    'trip_id',
    'tripID',
    'activeTripId',
    'active_trip_id',
  ]);
}

int? _readRatingStars(Map<String, dynamic> raw) {
  // Backend (web parity: BookingDetail.jsx `booking.rating`) returns the
  // rating as a nested object `{ stars, review }`, not a top-level int.
  for (final key in const ['rating', 'userRating', 'user_rating']) {
    final nested = raw[key];
    if (nested is Map) {
      final stars = _readIntValue(
        nested.cast<String, dynamic>(),
        const <String, dynamic>{},
        const ['stars', 'rating', 'value', 'score'],
      );
      if (stars != null) return stars;
    } else if (nested is num) {
      return nested.toInt();
    }
  }
  final trip = raw['trip'];
  if (trip is Map) {
    final fromTrip = _readRatingStars(trip.cast<String, dynamic>());
    if (fromTrip != null) return fromTrip;
  }
  return _readIntValue(raw, raw, const [
    'ratingStars',
    'rating_stars',
    'stars',
    'ratingValue',
    'rating_value',
  ]);
}

List<PodDeliveryMedia> _readPodDeliveryMedia(Map<String, dynamic> raw) {
  final trip = raw['trip'];
  final candidates = <Object?>[
    raw['podMedia'],
    raw['pod_media'],
    if (trip is Map) trip.cast<String, dynamic>()['podMedia'],
    if (trip is Map) trip.cast<String, dynamic>()['pod_media'],
    if (trip is Map) trip.cast<String, dynamic>()['podPhotos'],
    raw['podPhotos'],
    raw['pod_photos'],
  ];
  for (final media in candidates) {
    if (media is Iterable) {
      final items = media
          .map((item) {
            if (item is Map) {
              final json = item.cast<String, dynamic>();
              final url = _readString(json, const ['url', 'src', 'path']);
              if (url.isEmpty) return null;
              final type = _readString(json, const ['type', 'mediaType']);
              return PodDeliveryMedia(
                url: url,
                type: type.trim().toLowerCase() == 'video' ? 'video' : 'image',
              );
            }
            final url = item.toString().trim();
            if (url.isEmpty || url.toLowerCase() == 'null') return null;
            return PodDeliveryMedia(url: url, type: 'image');
          })
          .whereType<PodDeliveryMedia>()
          .toList(growable: false);
      if (items.isNotEmpty) return items;
    }
  }

  final podUrl = _readString(raw, const ['podUrl', 'pod_url']);
  if (podUrl.isEmpty) {
    if (trip is Map) {
      final tripPodUrl = _readString(trip.cast<String, dynamic>(), const [
        'podUrl',
        'pod_url',
      ]);
      if (tripPodUrl.isEmpty) return const [];
      return [PodDeliveryMedia(url: tripPodUrl, type: 'image')];
    }
    return const [];
  }
  return [PodDeliveryMedia(url: podUrl, type: 'image')];
}

List<TrackingTimelineStep> _timelineForStatus(
  String status,
  ClientBooking booking,
  AppLocalizations? l10n,
) {
  final origin = booking.pickupLocation.isEmpty
      ? (l10n?.pickupLocationNotProvided ?? 'Pickup location not provided')
      : booking.pickupLocation;
  final destination = booking.dropoffLocation.isEmpty
      ? (l10n?.dropOffLocationNotProvided ?? 'Drop-off location not provided')
      : booking.dropoffLocation;

  String text(String? localized, String fallback) => localized ?? fallback;

  final created = text(l10n?.trackingTimelineBookingCreated, 'Booking created');
  final assigned = text(l10n?.assigned, 'Assigned');
  final inTransit = text(l10n?.inTransit, 'In transit');
  final delivered = text(l10n?.delivered, 'Delivered');
  final cancelled = text(l10n?.statusCancelled, 'Cancelled');
  final pending = text(l10n?.statusPending, 'Pending');
  final confirmed = text(l10n?.statusConfirmed, 'Confirmed');
  final vehicleAssigned = text(
    l10n?.trackingTimelineVehicleAssigned,
    'Vehicle assigned',
  );
  final driverAssigned = text(
    l10n?.trackingTimelineDriverAssigned,
    'Driver assigned',
  );
  final completedSuccessfully = text(
    l10n?.trackingTimelineCompletedSuccessfully,
    'Completed successfully',
  );
  final waitingForAssignment = text(
    l10n?.trackingTimelineWaitingForAssignment,
    'Waiting for assignment',
  );
  final bookingWasCancelled = text(
    l10n?.trackingTimelineBookingCancelled,
    'Booking was cancelled',
  );
  final waitingForConfirmation = text(
    l10n?.truckSearchWaitingConfirm,
    'Waiting for confirmation',
  );

  switch (status) {
    case 'completed':
    case 'delivered':
      return [
        TrackingTimelineStep(title: created, subtitle: origin, completed: true),
        TrackingTimelineStep(
          title: assigned,
          subtitle: vehicleAssigned,
          completed: true,
        ),
        TrackingTimelineStep(
          title: inTransit,
          subtitle: destination,
          completed: true,
        ),
        TrackingTimelineStep(
          title: delivered,
          subtitle: completedSuccessfully,
          completed: true,
        ),
      ];
    case 'assigned':
      return [
        TrackingTimelineStep(title: created, subtitle: origin, completed: true),
        TrackingTimelineStep(
          title: assigned,
          subtitle: driverAssigned,
          completed: true,
        ),
        TrackingTimelineStep(
          title: inTransit,
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: delivered,
          subtitle: pending,
          completed: false,
        ),
      ];
    case 'en_route_pickup':
    case 'picked_up':
    case 'in_transit':
      return [
        TrackingTimelineStep(title: created, subtitle: origin, completed: true),
        TrackingTimelineStep(
          title: assigned,
          subtitle: driverAssigned,
          completed: true,
        ),
        TrackingTimelineStep(
          title: inTransit,
          subtitle: destination,
          completed: true,
        ),
        TrackingTimelineStep(
          title: delivered,
          subtitle: pending,
          completed: false,
        ),
      ];
    case 'confirmed':
      return [
        TrackingTimelineStep(title: created, subtitle: origin, completed: true),
        TrackingTimelineStep(
          title: confirmed,
          subtitle: waitingForAssignment,
          completed: true,
        ),
        TrackingTimelineStep(
          title: inTransit,
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: delivered,
          subtitle: pending,
          completed: false,
        ),
      ];
    case 'cancelled':
      return [
        TrackingTimelineStep(title: created, subtitle: origin, completed: true),
        TrackingTimelineStep(
          title: cancelled,
          subtitle: bookingWasCancelled,
          completed: true,
        ),
        TrackingTimelineStep(
          title: inTransit,
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: delivered,
          subtitle: cancelled,
          completed: false,
        ),
      ];
    case 'pending':
    default:
      return [
        TrackingTimelineStep(title: created, subtitle: origin, completed: true),
        TrackingTimelineStep(
          title: pending,
          subtitle: waitingForConfirmation,
          completed: false,
        ),
        TrackingTimelineStep(
          title: inTransit,
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: delivered,
          subtitle: pending,
          completed: false,
        ),
      ];
  }
}

class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LocationArc extends StatelessWidget {
  const LocationArc({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(AppIcons.location_on_rounded, color: scheme.primary, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.locationArcPickUpFrom,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mumbai, Maharashtra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              AppIcons.arrow_forward_ios_rounded,
              size: 12,
              color: context.colors.textSecondary.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerCard extends StatelessWidget {
  const BannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: const AspectRatio(
        aspectRatio: 2,
        child: Image(
          image: AssetImage('assets/client/test.png'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

Future<void> showTripTypeSheet(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  onOpen?.call();
  try {
    final tripType =
        initialTripType ??
        await showModalBottomSheet<TripType>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TripTypeSheet(),
        );
    if (tripType == null || !context.mounted) return;

    final bookingData = await Navigator.of(context, rootNavigator: true)
        .push<BookingData>(
          MaterialPageRoute(
            builder: (context) => BookingLocationScreen(
              tripType: tripType,
              initialVehicleIndex: initialVehicleIndex ?? 0,
            ),
          ),
        );
    if (bookingData == null || !context.mounted) return;

    final vehicle = await Navigator.of(context, rootNavigator: true)
        .push<VehicleOption>(
          MaterialPageRoute(
            builder: (context) => SelectVehicleScreen(
              bookingData: bookingData,
              initialIndex: initialVehicleIndex ?? 0,
            ),
          ),
        );
    if (vehicle == null || !context.mounted) return;
  } finally {
    onClose?.call();
  }
}

Future<void> showQuickBookingFlow(
  BuildContext context, {
  required TripType tripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  onOpen?.call();
  try {
    final pickup = await Navigator.of(context, rootNavigator: true)
        .push<GooglePlaceSelection>(
          MaterialPageRoute(
            builder: (context) => _LocationDetailsScreen(
              kind: _LocationFieldKind.pickup,
              initialValue: '',
            ),
          ),
        );
    if (pickup == null || !context.mounted) {
      return;
    }

    final drop = await Navigator.of(context, rootNavigator: true)
        .push<GooglePlaceSelection>(
          MaterialPageRoute(
            builder: (context) => _LocationDetailsScreen(
              kind: _LocationFieldKind.drop,
              initialValue: '',
            ),
          ),
        );
    if (drop == null || !context.mounted) {
      return;
    }

    final bookingData = BookingData(
      from: pickup.formattedAddress,
      to: drop.formattedAddress,
      tripType: tripType,
      city: pickup.city.isNotEmpty ? pickup.city : drop.city,
      pickupLat: pickup.latitude,
      pickupLng: pickup.longitude,
      dropLat: drop.latitude,
      dropLng: drop.longitude,
      scheduledDate: DateTime.now().add(const Duration(hours: 3)),
    );

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => BookingLocationScreen(
          tripType: tripType,
          initialVehicleIndex: initialVehicleIndex ?? 0,
          initialBookingData: bookingData,
          skipLocationStep: true,
        ),
      ),
    );
  } finally {
    onClose?.call();
  }
}

Future<void> showBookingFlow(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  await showTripTypeSheet(
    context,
    initialTripType: initialTripType,
    initialVehicleIndex: initialVehicleIndex,
    onOpen: onOpen,
    onClose: onClose,
  );
}

class TrackingMockCard extends StatelessWidget {
  const TrackingMockCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEAF2F8),
                    valueColor: AlwaysStoppedAnimation(accent),
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

class PackageTrackingCard extends StatelessWidget {
  const PackageTrackingCard({super.key, required this.shipment, this.onTap});

  final TrackingDemoShipment shipment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset('assets/package.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.packageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    if (shipment.isExpress) ...[
                      const SizedBox(height: 5),
                      const ExpressBadge(compact: true),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      l10n.packageCardTrackingId(shipment.trackingId),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                icon: Icon(AppIcons.more_horiz_rounded, size: 22),
                color: context.colors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 14,
                child: Column(
                  children: [
                    const SizedBox(height: 3),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: context.colors.brandFill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: context.colors.brandFill,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fromLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      shipment.fromLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.shippingToLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      shipment.toLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.line),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2FA56E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.brokerInvoicesStatus,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shipment.status,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: card,
    );
  }
}

class TruckIllustration extends StatelessWidget {
  const TruckIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            left: 4,
            child: Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FA56E).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                AppIcons.local_shipping_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 16,
            child: Container(
              width: 20,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1F88C9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                AppIcons.inventory_2_outlined,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
          const Positioned(bottom: 10, left: 10, child: Wheel()),
          const Positioned(bottom: 10, right: 10, child: Wheel()),
        ],
      ),
    );
  }
}

class Wheel extends StatelessWidget {
  const Wheel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: context.colors.textPrimary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.fillSubtle,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.colors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF2FA56E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevron_right_rounded,
              color: context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.46,
        minChildSize: 0.36,
        maxChildSize: 0.86,
        expand: false,
        builder: (context, controller) {
          return Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.colors.line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TripTypeSheet extends StatelessWidget {
  const TripTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.tripTypeChooseTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _TripTypeRow(
              imagePath: 'assets/trucks/inter-city.png',
              label: localizedTripTypeLabel(l10n, TripType.interCity),
              helperText: localizedTripTypeHelperText(l10n, TripType.interCity),
              onTap: () => Navigator.of(context).pop(TripType.interCity),
            ),
            const SizedBox(height: 10),
            _TripTypeRow(
              imagePath: 'assets/trucks/intra-city.png',
              label: localizedTripTypeLabel(l10n, TripType.intraCity),
              helperText: localizedTripTypeHelperText(l10n, TripType.intraCity),
              onTap: () => Navigator.of(context).pop(TripType.intraCity),
            ),
          ],
        ),
      ),
    );
  }
}

double _sheetBottomInset(BuildContext context) {
  final viewPadding = MediaQuery.of(context).viewPadding.bottom;
  return viewPadding > 0 ? viewPadding + 28 : 28;
}

class _TripTypeRow extends StatelessWidget {
  const _TripTypeRow({
    required this.imagePath,
    required this.label,
    required this.helperText,
    required this.onTap,
  });

  final String imagePath;
  final String label;
  final String helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: context.colors.fillSubtle,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.line),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 54, height: 54, fit: BoxFit.contain),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
