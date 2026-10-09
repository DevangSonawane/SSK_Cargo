import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// A monthly-hire vehicle listing (broker/driver side — web
/// `MonthlyHiring.jsx` parity: list own listings, pause/resume, delete).
class MonthlyHiringListing {
  const MonthlyHiringListing({
    required this.id,
    this.truckRegistration = '',
    this.truckCategory = '',
    this.truckType = '',
    this.pricingType = '',
    this.rateAmount = 0,
    this.availabilityNotes = '',
    this.status = 'active',
    this.createdAt,
  });

  factory MonthlyHiringListing.fromJson(Map<String, dynamic> json) {
    String str(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.toLowerCase() == 'null' ? '' : text;
    }

    double rate = 0;
    final raw = json['rateAmount'] ?? json['rate_amount'] ?? json['rate'];
    if (raw is num) {
      rate = raw.toDouble();
    } else if (raw != null) {
      rate = double.tryParse(raw.toString()) ?? 0;
    }
    return MonthlyHiringListing(
      id: str(json['id']),
      truckRegistration: str(
        json['truckRegistration'] ?? json['truck_registration'],
      ),
      truckCategory: str(json['truckCategory'] ?? json['truck_category']),
      truckType: str(json['truckType'] ?? json['truck_type']),
      pricingType: str(json['pricingType'] ?? json['pricing_type']),
      rateAmount: rate,
      availabilityNotes: str(
        json['availabilityNotes'] ?? json['availability_notes'],
      ),
      status: str(json['status']).isEmpty ? 'active' : str(json['status']),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'])?.toString() ?? '',
      ),
    );
  }

  final String id;
  final String truckRegistration;
  final String truckCategory;
  final String truckType;
  final String pricingType;
  final double rateAmount;
  final String availabilityNotes;
  final String status;
  final DateTime? createdAt;
}

List<MonthlyHiringListing> parseMonthlyHiringListings(
  Map<String, dynamic> response,
) {
  final data = response['data'];
  Object? list = response['listings'];
  if (data is Map<String, dynamic>) {
    list = data['listings'] ?? data['items'] ?? list;
  }
  if (list is! Iterable) return const [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(MonthlyHiringListing.fromJson)
      .where((l) => l.id.isNotEmpty)
      .toList(growable: false);
}

/// Monthly vehicle hiring list — shared by brokers (`/broker/monthly-hiring`)
/// and drivers (`/driver/monthly-hiring`), exactly like the web's shared
/// `MonthlyHiring.jsx`. List a truck and the team follows up on enquiries.
class BrokerMonthlyHiringScreen extends ConsumerStatefulWidget {
  const BrokerMonthlyHiringScreen({super.key});

  @override
  ConsumerState<BrokerMonthlyHiringScreen> createState() =>
      _BrokerMonthlyHiringScreenState();
}

class _BrokerMonthlyHiringScreenState
    extends ConsumerState<BrokerMonthlyHiringScreen> {
  List<MonthlyHiringListing> _listings = const [];
  bool _loading = true;
  bool _error = false;
  String? _actingId;

  bool get _isBroker {
    final role = ref
        .read(authSessionProvider)
        .valueOrNull
        ?.user
        .role
        .trim()
        .toLowerCase();
    return role == 'broker';
  }

  String get _basePath =>
      _isBroker ? '/broker/monthly-hiring' : '/driver/monthly-hiring';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .getMonthlyHiringListings(accessToken: session.tokens.accessToken);
      if (!mounted) return;
      setState(() => _listings = parseMonthlyHiringListings(response));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(MonthlyHiringListing listing) async {
    if (_actingId != null) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    final next = listing.status.toLowerCase() == 'active'
        ? 'inactive'
        : 'active';
    setState(() => _actingId = listing.id);
    try {
      await ref
          .read(apiClientProvider)
          .updateMonthlyHiringListing(
            accessToken: session.tokens.accessToken,
            id: listing.id,
            status: next,
          );
      if (!mounted) return;
      setState(() {
        _listings = _listings
            .map(
              (l) => l.id == listing.id
                  ? MonthlyHiringListing(
                      id: l.id,
                      truckRegistration: l.truckRegistration,
                      truckCategory: l.truckCategory,
                      truckType: l.truckType,
                      pricingType: l.pricingType,
                      rateAmount: l.rateAmount,
                      availabilityNotes: l.availabilityNotes,
                      status: next,
                      createdAt: l.createdAt,
                    )
                  : l,
            )
            .toList(growable: false);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  Future<void> _remove(MonthlyHiringListing listing) async {
    if (_actingId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove listing?'),
        content: Text(
          'Stop listing ${listing.truckRegistration.isEmpty ? 'this truck' : listing.truckRegistration} for monthly hire?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerIcon,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _actingId = listing.id);
    try {
      await ref
          .read(apiClientProvider)
          .deleteMonthlyHiringListing(
            accessToken: session.tokens.accessToken,
            id: listing.id,
          );
      if (!mounted) return;
      setState(
        () => _listings = _listings
            .where((l) => l.id != listing.id)
            .toList(growable: false),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(AppIcons.arrow_back_rounded),
          ),
          title: const Text(
            'Monthly Vehicle Hiring',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final created = await context.push<bool>('$_basePath/new');
            if (created == true && mounted) _load();
          },
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          icon: const Icon(AppIcons.add_rounded),
          label: const Text('New Listing'),
        ),
        body: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 92),
            children: [
              const Text(
                'List your truck as available — our team reaches out when a client enquires.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_error)
                _EmptyState(
                  title: 'Could not load listings',
                  subtitle: 'Pull down to retry.',
                  onRetry: _load,
                )
              else if (_listings.isEmpty)
                _EmptyState(
                  title: 'No monthly hiring listings yet',
                  subtitle: _isBroker
                      ? 'List one of your trucks and our team will follow up when a client enquires.'
                      : 'List your truck and our team will follow up when a client enquires.',
                  actionLabel: 'List Your First Vehicle',
                  onAction: () async {
                    final created = await context.push<bool>(
                      '$_basePath/new',
                    );
                    if (created == true && mounted) _load();
                  },
                )
              else
                ..._listings.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ListingCard(
                      listing: listing,
                      busy: _actingId == listing.id,
                      onToggle: () => _toggleStatus(listing),
                      onRemove: () => _remove(listing),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.busy,
    required this.onToggle,
    required this.onRemove,
  });

  final MonthlyHiringListing listing;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final active = listing.truckCategory.isNotEmpty
        ? listing.truckCategory
        : listing.truckType;
    final activeListing = listing.status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        if (listing.truckRegistration.isNotEmpty)
                          listing.truckRegistration,
                        if (active.isNotEmpty) active,
                      ].join(' · ').ifEmpty('Truck'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        listing.pricingType == 'per_km'
                            ? 'Per KM'
                            : 'Fixed Rate',
                        if (listing.rateAmount > 0)
                          '₹${listing.rateAmount.toStringAsFixed(listing.rateAmount % 1 == 0 ? 0 : 2)}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (listing.availabilityNotes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        listing.availabilityNotes,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: activeListing
                      ? const Color(0xFFE0F4E8)
                      : AppColors.fillSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  activeListing ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: activeListing
                        ? AppColors.brand
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onToggle,
                  icon: const Icon(AppIcons.toggle_on_rounded, size: 16),
                  label: Text(
                    activeListing ? 'Mark Inactive' : 'Mark Active',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: busy ? null : onRemove,
                icon: const Icon(AppIcons.delete_outline_rounded),
                color: AppColors.dangerIcon,
                tooltip: 'Remove',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.onRetry,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              AppIcons.local_shipping_outlined,
              color: AppColors.brand,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
              ),
              child: Text(actionLabel!),
            ),
          ] else if (onRetry != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
              ),
              child: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
