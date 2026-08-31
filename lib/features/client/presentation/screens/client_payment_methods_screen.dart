import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ClientPaymentMethodsScreen extends ConsumerStatefulWidget {
  const ClientPaymentMethodsScreen({super.key});

  @override
  ConsumerState<ClientPaymentMethodsScreen> createState() =>
      _ClientPaymentMethodsScreenState();
}

class _ClientPaymentMethodsScreenState
    extends ConsumerState<ClientPaymentMethodsScreen> {
  final List<_SavedPaymentMethod> _methods = [];
  bool _loading = true;
  bool _error = false;
  String? _deletingId;
  String? _defaultingId;

  static const List<String> _banks = [
    'SBI',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Bank',
    'Other Banks',
  ];

  static const List<String> _wallets = [
    'Paytm',
    'Amazon Pay',
    'Mobikwik',
    'Freecharge',
    'PayPal',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = false;
        _methods.clear();
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }

    try {
      final response = await ref.read(apiClientProvider).getSavedPaymentMethods(
            accessToken: session.tokens.accessToken,
          );
      final methods = _parseMethods(response);
      if (!mounted) return;
      setState(() {
        _methods
          ..clear()
          ..addAll(methods);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PaymentMethodEditorSheet(
          banks: _banks,
          wallets: _wallets,
          onSave: (draft) async {
            final api = ref.read(apiClientProvider);
            final response = await api.createSavedPaymentMethod(
              accessToken: session.tokens.accessToken,
              methodType: draft.methodType,
              label: draft.label,
              details: draft.details,
            );
            final saved = _SavedPaymentMethod.fromJson(
              _pickItem(response, 'paymentMethod'),
            );
            if (saved.id.isNotEmpty && mounted) {
              setState(() {
                _methods.insert(0, saved);
              });
            } else {
              await _load();
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method saved.')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _setDefault(_SavedPaymentMethod method) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _defaultingId == method.id) return;

    setState(() {
      _defaultingId = method.id;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .setDefaultSavedPaymentMethod(
            accessToken: session.tokens.accessToken,
            id: method.id,
          );
      final updated = _SavedPaymentMethod.fromJson(
        _pickItem(response, 'paymentMethod'),
      );
      if (!mounted) return;
      setState(() {
        if (updated.id.isNotEmpty) {
          for (var i = 0; i < _methods.length; i++) {
            _methods[i] = _methods[i].copyWith(isDefault: _methods[i].id == method.id);
          }
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _defaultingId = null;
        });
      }
    }
  }

  Future<void> _deleteMethod(_SavedPaymentMethod method) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _deletingId == method.id) return;

    setState(() {
      _deletingId = method.id;
    });

    try {
      await ref.read(apiClientProvider).deleteSavedPaymentMethod(
            accessToken: session.tokens.accessToken,
            id: method.id,
          );
      if (!mounted) return;
      setState(() {
        _methods.removeWhere((item) => item.id == method.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment method removed.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            onPressed: _openEditor,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add payment method',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2FA56E),
        onRefresh: _load,
        child: session == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: const [
                  _EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sign in to manage payment methods',
                    subtitle: 'We need an active client session before we can load your saved methods.',
                  ),
                ],
              )
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        children: [
                          _EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Could not load payment methods',
                            subtitle: 'Pull to refresh or try again in a moment.',
                            actionLabel: 'Retry',
                            onAction: _load,
                          ),
                        ],
                      )
                    : _methods.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            children: [
                              _EmptyState(
                                icon: Icons.credit_card_outlined,
                                title: 'No saved payment methods yet',
                                subtitle: 'Save a UPI ID, card, bank, or wallet so checkout can remember it next time.',
                                actionLabel: 'Add Method',
                                onAction: _openEditor,
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            itemCount: _methods.length + 1,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == _methods.length) {
                                return _AddTile(onTap: _openEditor);
                              }
                              final method = _methods[index];
                              return _PaymentMethodCard(
                                method: method,
                                isDefaulting: _defaultingId == method.id,
                                isDeleting: _deletingId == method.id,
                                onSetDefault: method.isDefault
                                    ? null
                                    : () => _setDefault(method),
                                onDelete: () => _deleteMethod(method),
                              );
                            },
                          ),
      ),
    );
  }
}

class _PaymentMethodEditorSheet extends StatefulWidget {
  const _PaymentMethodEditorSheet({
    required this.banks,
    required this.wallets,
    required this.onSave,
  });

  final List<String> banks;
  final List<String> wallets;
  final Future<void> Function(_PaymentMethodDraft draft) onSave;

  @override
  State<_PaymentMethodEditorSheet> createState() =>
      _PaymentMethodEditorSheetState();
}

class _PaymentMethodEditorSheetState extends State<_PaymentMethodEditorSheet> {
  late final TextEditingController _upiController;
  late final TextEditingController _brandController;
  late final TextEditingController _last4Controller;
  late final TextEditingController _bankSearchController;
  late final TextEditingController _walletSearchController;
  String _methodType = 'upi';
  String _selectedBank = '';
  String _selectedWallet = '';
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _upiController = TextEditingController();
    _brandController = TextEditingController();
    _last4Controller = TextEditingController();
    _bankSearchController = TextEditingController();
    _walletSearchController = TextEditingController();
    _selectedBank = widget.banks.first;
    _selectedWallet = widget.wallets.first;
  }

  @override
  void dispose() {
    _upiController.dispose();
    _brandController.dispose();
    _last4Controller.dispose();
    _bankSearchController.dispose();
    _walletSearchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final draft = _buildDraft();
    if (draft == null) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(draft);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException ? error.message : error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  _PaymentMethodDraft? _buildDraft() {
    switch (_methodType) {
      case 'upi':
        final upiId = _upiController.text.trim();
        if (!RegExp(r'^[\w.-]+@[\w.-]+$').hasMatch(upiId)) {
          setState(() {
            _errorMessage = 'Enter a valid UPI ID, such as name@okhdfc.';
          });
          return null;
        }
        return _PaymentMethodDraft(
          methodType: 'upi',
          label: upiId,
          details: {'upi_id': upiId},
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
        return _PaymentMethodDraft(
          methodType: 'card',
          label: '$brand •••• $last4',
          details: {'brand': brand, 'last4': last4},
        );
      case 'netbanking':
        final bank = _selectedBank.trim();
        if (bank.isEmpty) {
          setState(() {
            _errorMessage = 'Choose a bank.';
          });
          return null;
        }
        return _PaymentMethodDraft(
          methodType: 'netbanking',
          label: bank,
          details: {'bank': bank},
        );
      case 'wallet':
        final wallet = _selectedWallet.trim();
        if (wallet.isEmpty) {
          setState(() {
            _errorMessage = 'Choose a wallet.';
          });
          return null;
        }
        return _PaymentMethodDraft(
          methodType: 'wallet',
          label: wallet,
          details: {'wallet': wallet},
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset + 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E5EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Payment Method',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _TypeChip(
                    label: 'UPI',
                    icon: Icons.smartphone_rounded,
                    selected: _methodType == 'upi',
                    onTap: () => setState(() => _methodType = 'upi'),
                  ),
                  _TypeChip(
                    label: 'Card',
                    icon: Icons.credit_card_rounded,
                    selected: _methodType == 'card',
                    onTap: () => setState(() => _methodType = 'card'),
                  ),
                  _TypeChip(
                    label: 'Bank',
                    icon: Icons.account_balance_rounded,
                    selected: _methodType == 'netbanking',
                    onTap: () => setState(() => _methodType = 'netbanking'),
                  ),
                  _TypeChip(
                    label: 'Wallet',
                    icon: Icons.account_balance_wallet_rounded,
                    selected: _methodType == 'wallet',
                    onTap: () => setState(() => _methodType = 'wallet'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_methodType == 'upi') ...[
                _FieldLabel(text: 'UPI ID'),
                const SizedBox(height: 8),
                _CardField(
                  child: TextField(
                    controller: _upiController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'name@okhdfc',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ] else if (_methodType == 'card') ...[
                _FieldLabel(text: 'Brand / Bank name'),
                const SizedBox(height: 8),
                _CardField(
                  child: TextField(
                    controller: _brandController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'HDFC Bank',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FieldLabel(text: 'Last 4 digits'),
                const SizedBox(height: 8),
                _CardField(
                  child: TextField(
                    controller: _last4Controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    textInputAction: TextInputAction.done,
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
                _FieldLabel(text: 'Bank'),
                const SizedBox(height: 8),
                _CardField(
                  child: TextField(
                    controller: _bankSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search bank name...',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.banks
                      .where(
                        (bank) => bank.toLowerCase().contains(
                              _bankSearchController.text.trim().toLowerCase(),
                            ),
                      )
                      .map(
                        (bank) => ChoiceChip(
                          label: Text(bank),
                          selected: _selectedBank == bank,
                          onSelected: (_) => setState(() {
                            _selectedBank = bank;
                          }),
                        ),
                      )
                      .toList(growable: false),
                ),
              ] else if (_methodType == 'wallet') ...[
                _FieldLabel(text: 'Wallet'),
                const SizedBox(height: 8),
                _CardField(
                  child: TextField(
                    controller: _walletSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search wallet name...',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.wallets
                      .where(
                        (wallet) => wallet.toLowerCase().contains(
                              _walletSearchController.text.trim().toLowerCase(),
                            ),
                      )
                      .map(
                        (wallet) => ChoiceChip(
                          label: Text(wallet),
                          selected: _selectedWallet == wallet,
                          onSelected: (_) => setState(() {
                            _selectedWallet = wallet;
                          }),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _InlineError(message: _errorMessage!),
              ],
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.isDefaulting,
    required this.isDeleting,
    required this.onSetDefault,
    required this.onDelete,
  });

  final _SavedPaymentMethod method;
  final bool isDefaulting;
  final bool isDeleting;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final icon = _methodIcon(method.methodType);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF2FA56E)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            method.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF101828),
                                ),
                          ),
                        ),
                        if (method.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F4E8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Default',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF2FA56E),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      method.secondaryLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (onSetDefault != null)
                TextButton.icon(
                  onPressed: isDefaulting ? null : onSetDefault,
                  icon: isDefaulting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.star_outline_rounded, size: 18),
                  label: const Text('Set default'),
                ),
              const Spacer(),
              IconButton(
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFB8DCC7),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4E8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF2FA56E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF2FA56E), size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                  height: 1.4,
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2FA56E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedPaymentMethod {
  const _SavedPaymentMethod({
    required this.id,
    required this.methodType,
    required this.label,
    required this.details,
    required this.isDefault,
  });

  final String id;
  final String methodType;
  final String label;
  final Map<String, dynamic> details;
  final bool isDefault;

  factory _SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    return _SavedPaymentMethod(
      id: _readString(json, const ['id']),
      methodType: _readString(json, const ['methodType', 'method_type']),
      label: _readString(json, const ['label']),
      details: details is Map<String, dynamic> ? details : const <String, dynamic>{},
      isDefault: _readBool(json, const ['isDefault', 'is_default']),
    );
  }

  _SavedPaymentMethod copyWith({
    String? methodType,
    String? label,
    Map<String, dynamic>? details,
    bool? isDefault,
  }) {
    return _SavedPaymentMethod(
      id: id,
      methodType: methodType ?? this.methodType,
      label: label ?? this.label,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get secondaryLabel {
    switch (methodType) {
      case 'upi':
        final upiId = _readString(details, const ['upi_id']);
        return upiId.isNotEmpty ? upiId : 'UPI';
      case 'card':
        final brand = _readString(details, const ['brand']);
        final last4 = _readString(details, const ['last4']);
        if (brand.isNotEmpty && last4.isNotEmpty) {
          return '$brand •••• $last4';
        }
        return 'Card';
      case 'netbanking':
        final bank = _readString(details, const ['bank']);
        return bank.isNotEmpty ? bank : 'Netbanking';
      case 'wallet':
        final wallet = _readString(details, const ['wallet']);
        return wallet.isNotEmpty ? wallet : 'Wallet';
      default:
        return methodType.isNotEmpty ? methodType : 'Payment method';
    }
  }
}

class _PaymentMethodDraft {
  const _PaymentMethodDraft({
    required this.methodType,
    required this.label,
    required this.details,
  });

  final String methodType;
  final String label;
  final Map<String, dynamic> details;
}

List<_SavedPaymentMethod> _parseMethods(Map<String, dynamic> response) {
  final payload = response['data'];
  final data = payload is Map<String, dynamic> ? payload : response;
  final raw = data['paymentMethods'] ?? data['items'] ?? data['results'] ?? data['rows'] ?? data['data'];
  final list = raw is List ? raw : const <dynamic>[];
  return list
      .whereType<Map<String, dynamic>>()
      .map(_SavedPaymentMethod.fromJson)
      .where((method) => method.id.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _pickItem(Map<String, dynamic> response, String key) {
  final payload = response['data'];
  final data = payload is Map<String, dynamic> ? payload : response;
  final item = data[key];
  if (item is Map<String, dynamic>) {
    return item;
  }
  return const <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
  }
  return false;
}

IconData _methodIcon(String methodType) {
  switch (methodType) {
    case 'upi':
      return Icons.smartphone_rounded;
    case 'card':
      return Icons.credit_card_rounded;
    case 'netbanking':
      return Icons.account_balance_rounded;
    case 'wallet':
      return Icons.account_balance_wallet_rounded;
    default:
      return Icons.payment_rounded;
  }
}
