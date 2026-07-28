import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GpsWalletBillingScreen extends StatelessWidget {
  const GpsWalletBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Stack(
        children: [
          const _WalletBackdrop(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 108),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: _WalletHeader(
                      compact: compact,
                      onBack: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/gps/dashboard');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _TokenHeroCard(compact: compact),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTabs(),
                            const SizedBox(height: 10),
                            _SearchAndFilterRow(compact: compact),
                            const SizedBox(height: 10),
                            const _TransactionCard(
                              icon: Icons.add_circle_outline_rounded,
                              iconBackground: Color(0xFFEAF8EE),
                              iconColor: Color(0xFF23A852),
                              title: 'Welcome Bonus',
                              subtitle: 'Tokens added',
                              meta: '25 May 2024, 10:30 AM',
                              amount: '+ 50 tokens',
                              amountColor: Color(0xFF23A852),
                              status: 'Completed',
                              statusBackground: Color(0xFFEAF8EE),
                              statusColor: Color(0xFF23A852),
                            ),
                            const SizedBox(height: 6),
                            const _TransactionCard(
                              icon: Icons.shopping_cart_outlined,
                              iconBackground: Color(0xFFEAF1FF),
                              iconColor: Color(0xFF2D6EF2),
                              title: 'Token Purchase',
                              subtitle: 'Via Razorpay',
                              meta: '25 May 2024, 10:30 AM',
                              amount: '+ 100 tokens',
                              amountColor: Color(0xFF23A852),
                              status: 'Completed',
                              statusBackground: Color(0xFFEAF8EE),
                              statusColor: Color(0xFF23A852),
                            ),
                            const SizedBox(height: 6),
                            const _TransactionCard(
                              icon: Icons.remove_circle_outline_rounded,
                              iconBackground: Color(0xFFFFEDEF),
                              iconColor: Color(0xFFFF595D),
                              title: 'Subscription Payment',
                              subtitle: 'Monthly Plan',
                              meta: '24 May 2024, 09:15 AM',
                              amount: '- 50 tokens',
                              amountColor: Color(0xFFFF595D),
                              status: 'Deducted',
                              statusBackground: Color(0xFFFFEEF0),
                              statusColor: Color(0xFFFF595D),
                            ),
                            const SizedBox(height: 6),
                            const _TransactionCard(
                              icon: Icons.schedule_rounded,
                              iconBackground: Color(0xFFFFF5DF),
                              iconColor: Color(0xFFD19A00),
                              title: 'Token Expiry',
                              subtitle: 'Expired tokens removed',
                              meta: '20 May 2024, 11:00 PM',
                              amount: '- 10 tokens',
                              amountColor: Color(0xFFFF595D),
                              status: 'Expired',
                              statusBackground: Color(0xFFFFEEF0),
                              statusColor: Color(0xFFFF595D),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFFE6ECF5),
                                    thickness: 1,
                                    height: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'No more transactions',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF8A96AB),
                                        ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    color: Color(0xFFE6ECF5),
                                    thickness: 1,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _GpsBottomNavBar(),
    );
  }
}

class _WalletBackdrop extends StatelessWidget {
  const _WalletBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1F49), Color(0xFF0B2556), Color(0xFFF4F7FC)],
          stops: [0.0, 0.42, 0.42],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 10,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E68F5).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader({
    required this.compact,
    required this.onBack,
  });

  final bool compact;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Wallet & Billing',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: compact ? 19.5 : 21,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
          ),
        ),
      ],
    );
  }
}

class _TokenHeroCard extends StatelessWidget {
  const _TokenHeroCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF174BBE), Color(0xFF0E2D75), Color(0xFF0D285E)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF8FB4FF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF081633).withValues(alpha: 0.26),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E68F5).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 68 : 72,
                    height: compact ? 68 : 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E68F5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Token Balance',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: compact ? 14 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2BC56A).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF55E07E),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                            const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '0',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    fontSize: compact ? 36 : 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 0.9,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                'tokens',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.82),
                                    ),
                              ),
                            ),
                          ],
                        ),
                            const SizedBox(height: 6),
                        Text(
                          '₹0.00 equivalent',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: compact ? 11 : 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2056D8),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 3,
                    width: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6EF2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Invoices',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF91A0B7),
                        ),
                  ),
                  const SizedBox(height: 9),
                  const SizedBox(height: 3),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE2EAF3)),
      ],
    );
  }
}

class _SearchAndFilterRow extends StatelessWidget {
  const _SearchAndFilterRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: compact ? 46 : 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3EAF4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 20, color: Color(0xFF75849A)),
                const SizedBox(width: 10),
                Expanded(
                            child: Text(
                              'Search transactions...',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A0B5),
                                ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: compact ? 46 : 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EAF4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF75849A)),
              const SizedBox(width: 8),
              Text(
                'Filter',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.amount,
    required this.amountColor,
    required this.status,
    required this.statusBackground,
    required this.statusColor,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String meta;
  final String amount;
  final Color amountColor;
  final String status;
  final Color statusBackground;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF11264C),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5F6F89),
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 9.2,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF71809A),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpsBottomNavBar extends StatelessWidget {
  const _GpsBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.home_rounded,
                      label: 'Dashboard',
                      onTap: () => context.go('/gps/dashboard'),
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.local_shipping_rounded,
                      label: 'Vehicles',
                      onTap: () => context.go('/gps/vehicles'),
                    ),
                  ),
                  const Expanded(child: SizedBox(width: 58)),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.insert_chart_rounded,
                      label: 'Reports',
                      onTap: () => context.go('/gps/reports'),
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      onTap: () => context.go('/gps/profile'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E68F5), Color(0xFF234CC8)],
                  ),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsNavItem extends StatelessWidget {
  const _GpsNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF8692A8)),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8692A8),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
