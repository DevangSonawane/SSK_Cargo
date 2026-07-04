import 'package:flutter/material.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _isOnline
                          ? const Color(0xFF98A2B3)
                          : const Color(0xFFE23A4B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) {
                      setState(() => _isOnline = value);
                    },
                    activeThumbColor: const Color(0xFF2FA56E),
                    activeTrackColor: const Color(
                      0xFF2FA56E,
                    ).withValues(alpha: 0.35),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(
                      0xFFE23A4B,
                    ).withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _isOnline
                          ? const Color(0xFF2FA56E)
                          : const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF2)),
            const SizedBox(height: 18),
            Text(
              'Deliveries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _deliveries.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE8EDF2)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7FAFD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inbox_rounded,
                            color: Color(0xFF98A2B3),
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No deliveries available',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isOnline
                              ? 'New deliveries will appear here when they are assigned.'
                              : 'Go online to receive deliveries.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF667085),
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (final delivery in _deliveries) ...[
                        _DeliveryCard(
                          title: delivery.title,
                          subtitle: delivery.subtitle,
                          accent: delivery.accent,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

const _deliveries = <_DriverDelivery>[];

class _DriverDelivery {
  const _DriverDelivery({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.local_shipping_rounded, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.4,
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
