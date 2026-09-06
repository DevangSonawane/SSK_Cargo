import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF3F8FF),
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
                icon: Icons.receipt_long_rounded,
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
                      icon: Icons.receipt_long_rounded,
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
          colors: [Color(0xFF075FC7), Color(0xFF147FE5)],
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
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Invoices',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
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
        ? const Color(0xFF10A866)
        : const Color(0xFF1769D1);
    final statusBackground = _isCompleted
        ? const Color(0xFFE8F8F0)
        : const Color(0xFFEAF3FF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0EBFA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1769D1).withValues(alpha: 0.08),
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
                    color: Color(0xFFE7F1FF),
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
                          color: Color(0xFF10245B),
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
                          color: Color(0xFF5B6B91),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: const Color(0xFF1769D1),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF3FF),
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
                          color: Color(0xFF5B6B91),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        shipment.fromLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102044),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Shipping to:',
                        style: TextStyle(
                          color: Color(0xFF5B6B91),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        shipment.toLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF102044),
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
            const Divider(height: 1, color: Color(0xFFDCE8F8)),
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
                    _isCompleted ? Icons.check_circle_rounded : Icons.circle,
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
                      color: Color(0xFF102044),
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
                  color: const Color(0xFFE1E5EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              booking.bookingNumber.isEmpty ? 'Invoice' : booking.bookingNumber,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              booking.packageName.isEmpty
                  ? booking.material
                  : booking.packageName,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
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
                  backgroundColor: const Color(0xFF1F88C9),
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
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF667085), size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}
