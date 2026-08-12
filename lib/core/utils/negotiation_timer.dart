Duration? negotiationWindowRemaining({
  required DateTime? anchorAt,
  required bool driverTimedOut,
  DateTime? now,
}) {
  final effectiveAnchor = anchorAt;
  if (effectiveAnchor == null) {
    return null;
  }

  final window = driverTimedOut
      ? const Duration(minutes: 5)
      : const Duration(minutes: 2);
  final target = effectiveAnchor.add(window);
  return target.difference(now ?? DateTime.now());
}

String formatCountdown(Duration remaining) {
  final safeRemaining = remaining.isNegative ? Duration.zero : remaining;
  final totalSeconds = safeRemaining.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String negotiationWindowStatusText({
  required Duration? remaining,
  required bool serverTimedOut,
  required String activeLabel,
  required String expiredLabel,
  required String fallbackLabel,
}) {
  if (serverTimedOut) {
    return expiredLabel;
  }
  if (remaining == null) {
    return fallbackLabel;
  }
  if (remaining <= Duration.zero) {
    return 'Any moment now - waiting for the server handoff.';
  }
  return '$activeLabel ${formatCountdown(remaining)} remaining';
}
