import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const SSkCargoApp());
}

class SSkCargoApp extends StatelessWidget {
  const SSkCargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SSK Cargo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}