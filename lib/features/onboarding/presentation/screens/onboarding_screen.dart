import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardingData(
      title: 'Book cargo in a few taps',
      description:
          'Find the right truck, confirm locations, and keep the full booking flow simple.',
      icon: Icons.route_rounded,
    ),
    _OnboardingData(
      title: 'Track every movement',
      description:
          'Watch shipments move from pickup to delivery with status updates in one place.',
      icon: Icons.my_location_rounded,
    ),
    _OnboardingData(
      title: 'Built for clients first',
      description:
          'Start with the client journey now, then we can expand to broker and driver flows later.',
      icon: Icons.verified_user_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _RoleBadge(
                    label: 'SSK',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/access'),
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) => setState(() => _index = value),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 152,
                          height: 152,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE6F7FF), Color(0xFFEAFBF1)],
                            ),
                            borderRadius: BorderRadius.circular(44),
                          ),
                          child: Icon(page.icon, size: 72, color: const Color(0xFF1F88C9)),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ...List.generate(
                    _pages.length,
                    (dotIndex) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 8),
                      width: _index == dotIndex ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _index == dotIndex
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFD9E4EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      if (_index < _pages.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                        return;
                      }
                      context.go('/access');
                    },
                    child: Text(_index < _pages.length - 1 ? 'Next' : 'Get started'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
