import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'client_payment_methods_shared.dart';

class ClientPaymentMethodAddScreen extends ConsumerStatefulWidget {
  const ClientPaymentMethodAddScreen({super.key});

  @override
  ConsumerState<ClientPaymentMethodAddScreen> createState() =>
      _ClientPaymentMethodAddScreenState();
}

class _ClientPaymentMethodAddScreenState
    extends ConsumerState<ClientPaymentMethodAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();
  final _brandController = TextEditingController();
  final _last4Controller = TextEditingController();
  final _bankSearchController = TextEditingController();
  final _walletSearchController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _noteController = TextEditingController();

  String _methodType = 'upi';
  String _selectedBank = paymentBankOptions.first.name;
  String _selectedWallet = paymentWalletOptions.first.label;
  bool _setAsDefault = false;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _upiController.dispose();
    _brandController.dispose();
    _last4Controller.dispose();
    _bankSearchController.dispose();
    _walletSearchController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  PaymentMethodDraft? _buildDraft() {
    final note = _noteController.text.trim();

    switch (_methodType) {
      case 'upi':
        final upiId = _upiController.text.trim();
        if (!RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(upiId)) {
          setState(() {
            _errorMessage = 'Enter a valid UPI ID, such as name@okhdfc.';
          });
          return null;
        }
        final details = <String, dynamic>{'upi_id': upiId};
        if (note.isNotEmpty) details['note'] = note;
        return PaymentMethodDraft(
          methodType: 'upi',
          label: upiId,
          details: details,
        );
      case 'card':
        final brand = _brandController.text.trim();
        final last4 = _last4Controller.text.replaceAll(RegExp(r'\D'), '');
        if (brand.isEmpty) {
          setState(() {
            _errorMessage = 'Enter a card or bank brand name.';
          });
          return null;
        }
        if (last4.length != 4) {
          setState(() {
            _errorMessage = 'Enter the last 4 digits only.';
          });
          return null;
        }
        final details = <String, dynamic>{
          'brand': brand,
          'last4': last4,
        };
        if (note.isNotEmpty) details['note'] = note;
        return PaymentMethodDraft(
          methodType: 'card',
          label: '$brand •••• $last4',
          details: details,
        );
      case 'netbanking':
        final bank = _selectedBank.trim();
        final accountNumber = _accountController.text.replaceAll(RegExp(r'\D'), '');
        final ifsc = _ifscController.text.trim().toUpperCase();
        if (bank.isEmpty) {
          setState(() {
            _errorMessage = 'Choose a bank.';
          });
          return null;
        }
        if (accountNumber.length < 9 || accountNumber.length > 18) {
          setState(() {
            _errorMessage = 'Enter a valid account number.';
          });
          return null;
        }
        if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
          setState(() {
            _errorMessage = 'Enter a valid IFSC code, such as HDFC0001234.';
          });
          return null;
        }
        final details = <String, dynamic>{
          'bank': bank,
          'ifsc': ifsc,
          'account_last4': accountNumber.substring(accountNumber.length - 4),
          'account_number': accountNumber,
        };
        if (note.isNotEmpty) details['note'] = note;
        return PaymentMethodDraft(
          methodType: 'netbanking',
          label: bank,
          details: details,
        );
      case 'wallet':
        final wallet = _selectedWallet.trim();
        if (wallet.isEmpty) {
          setState(() {
            _errorMessage = 'Choose a wallet.';
          });
          return null;
        }
        final details = <String, dynamic>{'wallet': wallet};
        if (note.isNotEmpty) details['note'] = note;
        return PaymentMethodDraft(
          methodType: 'wallet',
          label: wallet,
          details: details,
        );
      default:
        return null;
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final draft = _buildDraft();
    if (draft == null) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      setState(() {
        _errorMessage = 'Sign in again to save payment methods.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final navigator = Navigator.of(context);
    try {
      final response = await ref.read(apiClientProvider).createSavedPaymentMethod(
            accessToken: session.tokens.accessToken,
            methodType: draft.methodType,
            label: draft.label,
            details: draft.details,
          );
      final saved = SavedPaymentMethod.fromJson(
        pickResponseItem(response, 'paymentMethod'),
      );
      if (!mounted) return;
      if (saved.id.isNotEmpty && _setAsDefault) {
        try {
          await ref
              .read(apiClientProvider)
              .setDefaultSavedPaymentMethod(
                accessToken: session.tokens.accessToken,
                id: saved.id,
              );
        } catch (_) {
          // Saving succeeded even if the follow-up default call fails.
        }
      }
      navigator.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Add Payment Method'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976FF), Color(0xFF0D3B85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D3B85).withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(7),
                      child: Image.asset(
                        'assets/Logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GadiDost Logistics',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Save cards, UPI IDs, banks, and wallets for faster checkout.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Type',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final columns = width >= 520 ? 4 : 2;
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: columns,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.92,
                            children: [
                              for (final option in paymentMethodTypeOptions)
                                _TypeChip(
                                  label: option.label,
                                  icon: option.icon,
                                  selected: _methodType == option.id,
                                  onTap: () => setState(() {
                                    _methodType = option.id;
                                    _errorMessage = null;
                                  }),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      if (_methodType == 'upi') ...[
                        const _FieldLabel(text: 'UPI ID'),
                        const SizedBox(height: 8),
                        _CardField(
                          child: TextFormField(
                            controller: _upiController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'name@okhdfc',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ] else if (_methodType == 'card') ...[
                        const _FieldLabel(text: 'Brand / Bank name'),
                        const SizedBox(height: 8),
                        _CardField(
                          child: TextFormField(
                            controller: _brandController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'HDFC Bank',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel(text: 'Last 4 digits'),
                        const SizedBox(height: 8),
                        _CardField(
                          child: TextFormField(
                            controller: _last4Controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: '4242',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Only the brand and last 4 digits are stored.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF98A2B3),
                              ),
                        ),
                      ] else if (_methodType == 'netbanking') ...[
                        const _FieldLabel(text: 'Bank'),
                        const SizedBox(height: 8),
                        _CardField(
                          child: TextFormField(
                            controller: _bankSearchController,
                            decoration: const InputDecoration(
                              hintText: 'Search 33 banks...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _BankGrid(
                          banks: paymentBankOptions
                              .where(
                                (bank) => bank.name.toLowerCase().contains(
                                      _bankSearchController.text.trim().toLowerCase(),
                                    ),
                              )
                              .toList(growable: false),
                          selectedBank: _selectedBank,
                          onSelect: (bank) => setState(() {
                            _selectedBank = bank;
                            _errorMessage = null;
                          }),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel(text: 'Account Number'),
                                  const SizedBox(height: 8),
                                  _CardField(
                                    child: TextFormField(
                                      controller: _accountController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(18),
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. 123456789012',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel(text: 'IFSC Code'),
                                  const SizedBox(height: 8),
                                  _CardField(
                                    child: TextFormField(
                                      controller: _ifscController,
                                      textCapitalization: TextCapitalization.characters,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(11),
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[A-Za-z0-9]'),
                                        ),
                                      ],
                                      decoration: const InputDecoration(
                                        hintText: 'HDFC0001234',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else if (_methodType == 'wallet') ...[
                        const _FieldLabel(text: 'Wallet'),
                        const SizedBox(height: 8),
                        _CardField(
                          child: TextFormField(
                            controller: _walletSearchController,
                            decoration: const InputDecoration(
                              hintText: 'Search wallet name...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _WalletGrid(
                          wallets: paymentWalletOptions
                              .where(
                                (wallet) => wallet.label.toLowerCase().contains(
                                      _walletSearchController.text.trim().toLowerCase(),
                                    ),
                              )
                              .toList(growable: false),
                          selectedWallet: _selectedWallet,
                          onSelect: (wallet) => setState(() {
                            _selectedWallet = wallet;
                            _errorMessage = null;
                          }),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const _FieldLabel(
                        text: 'Note',
                      ),
                      const SizedBox(height: 8),
                      _CardField(
                        child: TextFormField(
                          controller: _noteController,
                          maxLength: 60,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Corporate Account, Backup Funding',
                            border: InputBorder.none,
                            counterText: '',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: _setAsDefault,
                        onChanged: (value) {
                          setState(() {
                            _setAsDefault = value ?? false;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Set as default payment method',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF667085),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_errorMessage != null) ...[
                        _InlineError(message: _errorMessage!),
                        const SizedBox(height: 14),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2FA56E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save Payment Method'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We only store display details like your card\'s last 4 digits — never your full number or CVV.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF98A2B3),
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankGrid extends StatelessWidget {
  const _BankGrid({
    required this.banks,
    required this.selectedBank,
    required this.onSelect,
  });

  final List<PaymentBankOption> banks;
  final String selectedBank;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (banks.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 700 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.1,
          children: [
            for (final bank in banks)
              _SelectableLogoTile(
                label: bank.name,
                selected: selectedBank == bank.name,
                onTap: () => onSelect(bank.name),
                logo: Image.asset(
                  bank.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WalletGrid extends StatelessWidget {
  const _WalletGrid({
    required this.wallets,
    required this.selectedWallet,
    required this.onSelect,
  });

  final List<PaymentWalletOption> wallets;
  final String selectedWallet;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 700 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.1,
          children: [
            for (final wallet in wallets)
              _SelectableLogoTile(
                label: wallet.label,
                selected: selectedWallet == wallet.label,
                onTap: () => onSelect(wallet.label),
                logo: Builder(builder: wallet.logoBuilder),
              ),
          ],
        );
      },
    );
  }
}

class _SelectableLogoTile extends StatelessWidget {
  const _SelectableLogoTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.logo,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget logo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF8F2) : const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFE8EDF2),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: logo,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF2FA56E) : const Color(0xFF667085),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F4E8) : const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFE8EDF2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF2FA56E) : const Color(0xFF667085),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected ? const Color(0xFF2FA56E) : const Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF667085),
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: child,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECDD6)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB42318),
            ),
      ),
    );
  }
}
