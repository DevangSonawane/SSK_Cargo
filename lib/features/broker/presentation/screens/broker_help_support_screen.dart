import 'package:flutter/material.dart';

import '../../../shared/presentation/screens/help_support_screen.dart';

class BrokerHelpSupportScreen extends StatelessWidget {
  const BrokerHelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpSupportScreen(audience: SupportAudience.broker);
  }
}
