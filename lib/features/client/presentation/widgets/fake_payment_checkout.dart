import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';

Future<bool> showFakePaymentCheckout({
  required BuildContext context,
  required double amount,
  required String description,
  String? initialMethod,
  String? defaultMethodLabel,
}) async {
  final completed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _FakePaymentCheckout(
      amount: amount,
      description: description,
      initialMethod: initialMethod,
      defaultMethodLabel: defaultMethodLabel,
    ),
  );
  return completed == true;
}

class _FakePaymentCheckout extends StatefulWidget {
  const _FakePaymentCheckout({
    required this.amount,
    required this.description,
    this.initialMethod,
    this.defaultMethodLabel,
  });

  final double amount;
  final String description;
  final String? initialMethod;
  final String? defaultMethodLabel;

  @override
  State<_FakePaymentCheckout> createState() => _FakePaymentCheckoutState();
}

class _FakePaymentCheckoutState extends State<_FakePaymentCheckout> {
  static const methods = <String>[
    'Recommended',
    'UPI',
    'Cards',
    'Netbanking',
    'Wallet',
  ];

  String _selectedMethod = methods.first;
  String _pin = '';
  bool _processing = false;  @override
  void initState() {
    super.initState();
    // Checkout remembers the default saved method (web PaymentMethods
    // parity): preselect its chip when it matches a known category.
    final initial = widget.initialMethod;
    if (initial != null && methods.contains(initial)) {
      _selectedMethod = initial;
    }
  }

  String get _amountLabel =>
      '₹${widget.amount.toStringAsFixed(widget.amount % 1 == 0 ? 0 : 2)}';

  String _checkoutMethodLabel(AppLocalizations l10n, String method) {
    switch (method) {
      case 'Recommended':
        return l10n.clientCheckoutMethodRecommended;
      case 'UPI':
        return l10n.clientCheckoutMethodUpi;
      case 'Cards':
        return l10n.clientCheckoutMethodCards;
      case 'Netbanking':
        return l10n.clientCheckoutMethodNetbanking;
      case 'Wallet':
        return l10n.clientCheckoutMethodWallet;
      default:
        return method;
    }
  }

  void _addDigit(String digit) {
    if (_pin.length >= 4 || _processing) return;
    setState(() => _pin += digit);
  }

  void _removeDigit() {
    if (_pin.isEmpty || _processing) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _complete() async {
    if (_pin.length != 4 || _processing) return;
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 14),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.colors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      AppIcons.lock_outline_rounded,
                      color: Color(0xFF2FA56E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.clientCheckoutTestTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      _amountLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF2FA56E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.clientCheckoutDemoMode(widget.description),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                if ((widget.defaultMethodLabel ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.brandFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.check_circle_rounded,
                          size: 16,
                          color: context.colors.brandEmphasis,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.clientCheckoutDefaultMethod(widget.defaultMethodLabel ?? ''),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.colors.brandEmphasis,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  l10n.clientCheckoutChooseMethod,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final method in methods)
                      ChoiceChip(
                        label: Text(_checkoutMethodLabel(l10n, method)),
                        selected: _selectedMethod == method,
                        onSelected: _processing
                            ? null
                            : (_) => setState(() => _selectedMethod = method),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.clientCheckoutEnterPin,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < 4; index++)
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: index < _pin.length
                              ? const Color(0xFF2FA56E)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: index < _pin.length
                                ? const Color(0xFF2FA56E)
                                : context.colors.textTertiary,
                            width: 2,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _PinPad(
                  onDigit: _addDigit,
                  onDelete: _removeDigit,
                  enabled: !_processing,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _pin.length == 4 && !_processing
                        ? _complete
                        : null,
                    child: _processing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.clientCheckoutPay(_amountLabel)),
                  ),
                ),
                TextButton(
                  onPressed: _processing
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(l10n.clientCheckoutCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onDelete,
    required this.enabled,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final keys = <String>[
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '',
      '0',
      'delete',
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 42,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        return OutlinedButton(
          onPressed: enabled
              ? () => key == 'delete' ? onDelete() : onDigit(key)
              : null,
          child: key == 'delete'
              ? const Icon(AppIcons.backspace_outlined, size: 18)
              : Text(key),
        );
      },
    );
  }
}
