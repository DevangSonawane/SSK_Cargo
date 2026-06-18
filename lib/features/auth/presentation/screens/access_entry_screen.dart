import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccessEntryScreen extends StatefulWidget {
  const AccessEntryScreen({super.key});

  @override
  State<AccessEntryScreen> createState() => _AccessEntryScreenState();
}

class _AccessEntryScreenState extends State<AccessEntryScreen> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What would you like to do?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF17324D),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a path to continue into SSK.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _ChoiceCard(
                    title: 'Book a vehicle',
                    subtitle: 'Plan a cargo move quickly.',
                    icon: Icons.local_shipping_rounded,
                    accentColor: const Color(0xFF1F88C9),
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceCard(
                    title: 'Register yourself',
                    subtitle: 'Go to the login screen and continue as a client.',
                    icon: Icons.person_add_alt_1_rounded,
                    accentColor: const Color(0xFF2FA56E),
                    selected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  _ChoiceCard(
                    title: 'GPS tracking',
                    subtitle: 'Track live routes and movement updates.',
                    icon: Icons.gps_fixed_rounded,
                    accentColor: const Color(0xFF7A5AF8),
                    selected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _selectedIndex == -1
                        ? const SizedBox(height: 18)
                        : Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  if (_selectedIndex == 1) {
                                    context.go('/login');
                                    return;
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('This option is not ready yet.'),
                                    ),
                                  );
                                },
                                child: const Text('Continue'),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? accentColor : const Color(0xFFE6EDF3);
    final backgroundColor = selected ? accentColor.withValues(alpha: 0.08) : const Color(0xFFF8FBFE);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF17324D),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? accentColor : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
