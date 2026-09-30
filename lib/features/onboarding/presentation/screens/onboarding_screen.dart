import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ssk/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  List<_OnboardingPage> _pagesFor(AppLocalizations l10n) {
    return <_OnboardingPage>[
      _OnboardingPage(
        image: 'assets/images/onboard1.png',
        title: l10n.onboardingSafeTitle,
        subtitle: l10n.onboardingSafeSubtitle,
        accent: Color(0xFF10B981),
      ),
      _OnboardingPage(
        image: 'assets/images/onboard2.png',
        title: l10n.onboardingTrackingTitle,
        subtitle: l10n.onboardingTrackingSubtitle,
        accent: Color(0xFF1F88C9),
      ),
      _OnboardingPage(
        image: 'assets/images/onboard3.png',
        title: l10n.onboardingFastTitle,
        subtitle: l10n.onboardingFastSubtitle,
        accent: Color(0xFF2FA56E),
      ),
    ];
  }

  void _goNext(List<_OnboardingPage> pages) {
    if (_index < pages.length - 1) {
      setState(() => _index += 1);
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _pagesFor(l10n);
    final page = pages[_index];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: Column(
                  children: [
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 360),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(
                              begin: 0.98,
                              end: 1,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        key: ValueKey(page.image),
                        height: 390,
                        width: double.infinity,
                        child: Image.asset(
                          page.image,
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _index == i ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _index == i
                                ? page.accent
                                : const Color(0xFFE3E8EF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        page.title,
                        key: ValueKey(page.title),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          page.subtitle,
                          key: ValueKey(page.subtitle),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.5,
                            color: Colors.grey.shade600,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _goNext(pages),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2FA56E),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _index == pages.length - 1
                              ? l10n.onboardingGetStarted
                              : l10n.onboardingNext,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.go('/login'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          foregroundColor: const Color(0xFF111827),
                        ),
                        child: Text(
                          l10n.onboardingSkip,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String image;
  final String title;
  final String subtitle;
  final Color accent;
}
