import 'package:flutter/material.dart';
import 'package:gadidost/core/theme/app_icons.dart';

import '../../../../core/theme/app_tokens.dart';

enum ClientInfoPageKind { help, terms }

class ClientStaticInfoScreen extends StatelessWidget {
  const ClientStaticInfoScreen({super.key, required this.kind});

  final ClientInfoPageKind kind;

  _ClientInfoDocument get _document => switch (kind) {
    ClientInfoPageKind.help => _helpDocument,
    ClientInfoPageKind.terms => _termsDocument,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final document = _document;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        title: Text(document.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _InfoHero(document: document),
            const SizedBox(height: 16),
            for (final section in document.sections) ...[
              _InfoSection(section: section),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoHero extends StatelessWidget {
  const _InfoHero({required this.document});

  final _ClientInfoDocument document;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.brandFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(document.icon, color: colors.brandEmphasis, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  document.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Effective date: ${document.effectiveDate}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w700,
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

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.section});

  final _ClientInfoSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in section.items) ...[
            _InfoItem(text: item),
            if (item != section.items.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: colors.brandEmphasis,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientInfoDocument {
  const _ClientInfoDocument({
    required this.title,
    required this.summary,
    required this.effectiveDate,
    required this.icon,
    required this.sections,
  });

  final String title;
  final String summary;
  final String effectiveDate;
  final IconData icon;
  final List<_ClientInfoSection> sections;
}

class _ClientInfoSection {
  const _ClientInfoSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

const _helpDocument = _ClientInfoDocument(
  title: 'Help & Support',
  summary:
      'Guidance for booking trucks, managing shipments, tracking deliveries, payments, and support escalations.',
  effectiveDate: '[Add date]',
  icon: AppIcons.headset_mic_outlined,
  sections: [
    _ClientInfoSection(
      title: 'Contact Support',
      items: [
        'Support phone: [Add support phone]',
        'Support email: [Add support email]',
        'Support hours: [Add support hours]',
        'Registered office: [Add company address]',
        'For urgent shipment issues, contact support from the app and include your booking number.',
      ],
    ),
    _ClientInfoSection(
      title: 'Booking a Shipment',
      items: [
        'Enter pickup and drop locations, choose inter-city or intra-city transport, select a truck type, add package details, review pricing, and confirm the booking.',
        'Keep pickup and drop addresses accurate. Missing contact details, access restrictions, or loading delays may affect timeline and charges.',
        'Truck availability depends on location, route, load type, and active partners.',
      ],
    ),
    _ClientInfoSection(
      title: 'Pricing and Payments',
      items: [
        'Fare estimates may include distance, truck category, transport type, route conditions, availability, express delivery, halting, taxes, and platform charges.',
        'Available payment options may include Pay Now, Advance, To Pay, or To Be Billed, depending on the booking and account rules.',
        'If money is deducted but the booking still shows unpaid, wait a few minutes, refresh, avoid repeated payments, and contact support with the transaction ID.',
      ],
    ),
    _ClientInfoSection(
      title: 'Tracking',
      items: [
        'Live tracking may show route progress, pickup/drop details, lorry owner/truck details, ETA, distance remaining, and shipment status.',
        'Location updates depend on lorry owner GPS permissions, network availability, device connectivity, and backend sync.',
        'Public tracking links can be viewed without login. Share them only with trusted recipients.',
      ],
    ),
    _ClientInfoSection(
      title: 'Cancellations and Refunds',
      items: [
        'Cancellation availability and charges depend on booking status, lorry owner assignment, truck arrival, loading progress, and operational costs.',
        'Approved refunds are usually processed to the original payment method, subject to payment provider and bank timelines.',
      ],
    ),
    _ClientInfoSection(
      title: 'Common Issues',
      items: [
        'If you cannot find a booking, confirm you are logged in with the same account used to create it, then refresh My Bookings.',
        'If lorry owner location is not updating, refresh tracking. Weak GPS, battery settings, network issues, or sync delays can cause temporary gaps.',
        'Fare changes can happen due to route changes, truck availability, halting, express handling, payment stage, taxes, or manual correction.',
      ],
    ),
    _ClientInfoSection(
      title: 'Escalations',
      items: [
        'Escalate when the lorry owner is unreachable, the truck has not arrived after confirmation, payment is deducted but not reflected, shipment status is wrong, goods are damaged or missing, or you suspect fraud.',
        'Support may ask for invoices, photos, delivery proof, chat history, payment references, or identity verification.',
      ],
    ),
  ],
);

const _termsDocument = _ClientInfoDocument(
  title: 'Terms & Privacy',
  summary:
      'Client terms and privacy policy for SSK Logistics services. This draft should be reviewed by legal counsel before public release.',
  effectiveDate: '[Add date]',
  icon: AppIcons.description_outlined,
  sections: [
    _ClientInfoSection(
      title: 'Company Details',
      items: [
        'Company name: [Add legal company name]',
        'Brand/platform name: SSK Logistics',
        'Support email: [Add support email]',
        'Registered office: [Add company address]',
      ],
    ),
    _ClientInfoSection(
      title: 'Terms of Use',
      items: [
        'By creating an account, booking a shipment, making a payment, tracking a shipment, or using the platform, you agree to these terms.',
        'SSK Logistics provides a technology platform to request goods transport, connect with lorry owners, brokers, or logistics partners, track shipments, communicate about bookings, and manage payments.',
        'Service availability may vary by location, truck type, route, partner availability, and operational conditions.',
      ],
    ),
    _ClientInfoSection(
      title: 'Account and Shipment Responsibilities',
      items: [
        'You must provide accurate account, contact, shipment, pickup/drop, payment, and document information.',
        'You are responsible for activity under your account and for keeping credentials, OTPs, devices, and public tracking links secure.',
        'Illegal, prohibited, stolen, unsafe, hazardous, restricted, undeclared, or improperly packed goods may be refused, cancelled, held, inspected, or reported.',
      ],
    ),
    _ClientInfoSection(
      title: 'Bookings, Pricing, and Payments',
      items: [
        'A booking request may depend on vehicle availability, lorry owner or broker acceptance, payment status, location accuracy, route feasibility, and operational review.',
        'Final charges may differ from estimates if booking details change, routes change, extra waiting time is incurred, or taxes and fees apply.',
        'Payment options may include online payment, advance payment, to-pay collection, to-be-billed settlement, UPI, cards, wallets, net banking, or other supported methods.',
      ],
    ),
    _ClientInfoSection(
      title: 'Tracking and Communication',
      items: [
        'Tracking is approximate and depends on GPS, network availability, device permissions, and backend systems.',
        'Anyone with a public tracking link may view limited shipment information, so share links carefully.',
        'The platform may send service messages through app notifications, SMS, email, WhatsApp, calls, or in-app chat.',
      ],
    ),
    _ClientInfoSection(
      title: 'Privacy',
      items: [
        'We may collect account, booking, location, tracking, payment, communication, device, usage, security, and diagnostic information.',
        'Information is used to manage accounts, process bookings, assign partners, estimate prices, enable payments, provide tracking, send notifications, support users, prevent fraud, improve service, and meet legal obligations.',
        'Necessary information may be shared with lorry owners, brokers, fleet partners, payment providers, map/location providers, support teams, legal authorities, and service providers needed to complete the service.',
      ],
    ),
    _ClientInfoSection(
      title: 'Your Choices',
      items: [
        'You may update profile details, manage saved addresses and payment methods where available, change your password, and control device notification permissions.',
        'For account deletion, correction, access, or privacy requests, contact [Add privacy/support email]. Identity verification may be required.',
      ],
    ),
  ],
);
