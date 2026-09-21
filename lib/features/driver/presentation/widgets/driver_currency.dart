String formatDriverAmount(double amount) {
  if (amount <= 0) return '0';
  return amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2);
}

String formatDriverCurrency(double amount) {
  return '₹${formatDriverAmount(amount)}';
}
