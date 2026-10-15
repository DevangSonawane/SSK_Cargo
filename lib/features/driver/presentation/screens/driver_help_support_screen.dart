import 'package:flutter/material.dart';

import '../../../shared/presentation/screens/help_support_screen.dart';

class DriverHelpSupportScreen extends StatelessWidget {
  const DriverHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpSupportScreen(audience: SupportAudience.driver);
  }
}
