import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Invoices'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: const [
                  _EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No invoice-ready bookings yet',
                    subtitle:
                        'Completed or delivered bookings will appear here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: bookings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return PackageTrackingCard(
                  shipment: trackingShipmentFromBooking(booking),
                  onTap: () => _openInvoice(booking),
                );
              },
            );
          },
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
