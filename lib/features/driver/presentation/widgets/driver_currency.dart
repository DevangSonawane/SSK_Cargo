String formatDriverAmount(double amount) {
  if (amount <= 0) return '0';
  return amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
}

String formatDriverCurrency(double amount) {
  return '₹${formatDriverAmount(amount)}';
}

/// Compact currency for big earnings: ₹950, ₹1.5k, ₹2.5M, ₹1.2B.
/// Small amounts stay exact; large ones get k/M/B with one decimal.
String formatDriverCurrencyCompact(double amount) {
  final sign = amount < 0 ? '-' : '';
  final abs = amount.abs();
  if (abs < 1000) return '$sign₹${formatDriverAmount(abs)}';
  String compact(double value, String suffix) {
    final rounded = (value * 10).round() / 10;
    final text = rounded % 1 == 0
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    return '$sign₹$text$suffix';
  }

  if (abs < 1000000) return compact(abs / 1000, 'k');
  if (abs < 1000000000) return compact(abs / 1000000, 'M');
  return compact(abs / 1000000000, 'B');
}
