import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';

class BrokerInvoicesScreen extends ConsumerStatefulWidget {
  const BrokerInvoicesScreen({super.key});

  @override
  ConsumerState<BrokerInvoicesScreen> createState() =>
      _BrokerInvoicesScreenState();
}

class _BrokerInvoicesScreenState extends ConsumerState<BrokerInvoicesScreen> {
  static const _query = (status: null, page: 1, limit: 50);

  Future<void> _refresh() async {
    ref.invalidate(_bookingsProvider(_query));
    await ref.read(_bookingsProvider(_query).future);
  }

  Future<void> _openInvoice(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || booking.id.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final messenger = ScaffoldMessenger.of(context);
        return _InvoiceActionsSheet(
          booking: booking,
          onDownload: () async {
            try {
              await ref
                  .read(apiClientProvider)
                  .getBookingInvoice(
                    accessToken: session.tokens.accessToken,
                    id: booking.id,
                  );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Invoice fetched for ${booking.bookingNumber}.',
                  ),
                ),
              );
            } catch (error) {
              if (!mounted) return;
              messenger.showSnackBar(SnackBar(content: Text(error.toString())));
            }
          },
          onEmail: () async {
            try {
              await ref
                  .read(apiClientProvider)
                  .emailBookingInvoice(
                    accessToken: session.tokens.accessToken,
                    id: booking.id,
                    to: session.user.email ?? 'broker@ssklogistics.in',
                    subject: 'Invoice for ${booking.bookingNumber}',
                    message:
                        'Please find attached the invoice for ${booking.bookingNumber}.',
                  );
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    'Invoice emailed for ${booking.bookingNumber}.',
                  ),
                ),
              );
            } catch (error) {
              if (!mounted) return;
              messenger.showSnackBar(SnackBar(content: Text(error.toString())));
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(_bookingsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: bookingsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              _InvoicesHeader(),
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _InvoicesHeader(),
              const SizedBox(height: 24),
              _EmptyState(
                icon: AppIcons.receipt_long_rounded,
                title: 'Could not load invoices',
                subtitle: error.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
          data: (page) {
            final bookings = page.bookings;
            if (bookings.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: const [
                  _InvoicesHeader(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: _EmptyState(
                      icon: AppIcons.receipt_long_rounded,
                      title: 'No invoice-ready bookings yet',
                      subtitle:
                          'Completed or delivered bookings will appear here.',
                    ),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                const _InvoicesHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    children: [
                      for (var index = 0; index < bookings.length; index++) ...[
                        _InvoiceBookingCard(
                          shipment: trackingShipmentFromBooking(
                            bookings[index],
                          ),
                          onTap: () => _openInvoice(bookings[index]),
                        ),
                        if (index != bookings.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InvoicesHeader extends StatelessWidget {
  const _InvoicesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        26,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brand, AppColors.brandBright],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              AppIcons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Invoices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceBookingCard extends StatelessWidget {
  const _InvoiceBookingCard({required this.shipment, required this.onTap});

  final TrackingDemoShipment shipment;
  final VoidCallback onTap;

  bool get _isCompleted => shipment.status.toLowerCase() == 'completed';

  @override
  Widget build(BuildContext context) {
    final statusColor = _isCompleted
        ? AppColors.brandInk
        : AppColors.brand;
    final statusBackground = _isCompleted
        ? AppColors.brandFill
        : AppColors.brandFill;


    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.08),
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
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: AppColors.brandFill,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset('assets/package.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.packageName.isEmpty
                            ? 'Booking'
                            : shipment.packageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#Tracking ID: ${shipment.trackingId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(AppIcons.more_horiz_rounded),
                  color: AppColors.brand,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.brandFill,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      _InvoiceRouteDot(color: statusColor),
                      Container(
                        width: 3,
                        height: 36,
                        color: statusColor.withValues(alpha: 0.18),
                      ),
                      _InvoiceRouteDot(color: statusColor),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        shipment.fromLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Shipping to:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        shipment.toLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: statusBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCompleted
                        ? AppIcons.check_circle_rounded
                        : AppIcons.circle,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Status:',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    shipment.status,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
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

class _InvoiceRouteDot extends StatelessWidget {
  const _InvoiceRouteDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

final _bookingsProvider = FutureProvider.autoDispose
    .family<ClientBookingPage, ({String? status, int page, int limit})>((
      ref,
      query,
    ) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getBookings(
            accessToken: session.tokens.accessToken,
            status: query.status,
            page: query.page,
            limit: query.limit,
          );
      return ClientBookingPage.fromJson(response);
    });

class _InvoiceActionsSheet extends StatelessWidget {
  const _InvoiceActionsSheet({
    required this.booking,
    required this.onDownload,
    required this.onEmail,
  });

  final ClientBooking booking;
  final VoidCallback onDownload;
  final VoidCallback onEmail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              booking.bookingNumber.isEmpty ? 'Invoice' : booking.bookingNumber,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              booking.packageName.isEmpty
                  ? booking.material
                  : booking.packageName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDownload();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Fetch invoice'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onEmail();
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Email invoice'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
