import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

/// Optional "reason for the counter-offer" — web parity with
/// DriverRequestCard.jsx / JobRequests.jsx (2-line textarea, 500 chars).
/// Sent as `note` on `/counter`; blank notes are omitted by the API client.
class CounterNoteField extends StatelessWidget {
  const CounterNoteField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  static const maxLength = 500;

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: 2,
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.counterNoteHint,
      ),
    );
  }
}
