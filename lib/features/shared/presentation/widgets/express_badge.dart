import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';

class ExpressBadge extends StatelessWidget {
  const ExpressBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.bolt_rounded,
            size: compact ? 13 : 14,
            color: const Color(0xFFEA580C),
          ),
          const SizedBox(width: 3),
          Text(
            'Express',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFC2410C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
