import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _driveController;
  late final Animation<double> _driveCurve;
  late final AnimationController _idleController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _driveCurve = CurvedAnimation(
      parent: _driveController,
      curve: Curves.easeOutCubic,
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _driveController.forward();

    if (!mounted) return;

    _idleController.repeat(reverse: true);

    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/access');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _driveController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final truckWidth = size.width * 0.75;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF2FF),
              Color(0xFFDDFBFB),
              Color(0xFFBDF3F5),
            ],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([
                _driveController,
                _idleController,
              ]),
              builder: (context, child) {
                final startX = -truckWidth;
                final endX = (size.width - truckWidth) / 2;
                final currentX = startX + (endX - startX) * _driveCurve.value;
                final bounce = _driveController.isCompleted
                    ? (_idleController.value - 0.5) * 6
                    : 0.0;

                return Positioned(
                  left: currentX,
                  top: size.height * 0.32 + bounce,
                  child: child!,
                );
              },
              child: Image.asset(
                'assets/ssk_cargo/assets/images/ssk_truck.png',
                width: truckWidth,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
