import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'client_payment_methods_shared.dart';

class ClientPaymentMethodsScreen extends ConsumerStatefulWidget {
  const ClientPaymentMethodsScreen({super.key});

  @override
  ConsumerState<ClientPaymentMethodsScreen> createState() =>
      _ClientPaymentMethodsScreenState();
}

class _ClientPaymentMethodsScreenState
    extends ConsumerState<ClientPaymentMethodsScreen> {
  final List<SavedPaymentMethod> _methods = [];
  bool _loading = true;
  bool _error = false;
  String? _deletingId;
  String? _defaultingId;

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
      if (!mounted) return;
      setState(() {
        _methods
          ..clear()
          ..addAll(parseSavedPaymentMethods(response));
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

  Future<void> _openAddPage() async {
    final result = await context.push<bool>('/client/payment-methods/add');
    if (result == true && mounted) {
      await _load();
    }
  }

  Future<void> _setDefault(SavedPaymentMethod method) async {
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
      final updated = SavedPaymentMethod.fromJson(
        pickResponseItem(response, 'paymentMethod'),
      );
      if (!mounted) return;
      setState(() {
        if (updated.id.isNotEmpty) {
          for (var i = 0; i < _methods.length; i++) {
            _methods[i] = _methods[i].copyWith(
              isDefault: _methods[i].id == method.id,
            );
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

  Future<void> _deleteMethod(SavedPaymentMethod method) async {
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
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2FA56E),
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Manage your saved cards and payment options for billing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
            ),
            const SizedBox(height: 18),
            if (session == null)
              const _EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to manage payment methods',
                subtitle:
                    'We need an active client session before we can load your saved methods.',
              )
            else if (_loading)
              const _LoadingGrid()
            else if (_error)
              _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load payment methods',
                subtitle: 'Pull to refresh or try again in a moment.',
                actionLabel: 'Retry',
                onAction: _load,
              )
            else if (_methods.isEmpty)
              _EmptyState(
                icon: Icons.credit_card_outlined,
                title: 'No saved payment methods yet',
                subtitle:
                    'Save a UPI ID, card, bank, or wallet so checkout can remember it next time.',
                actionLabel: 'Add Method',
                onAction: _openAddPage,
              )
            else
              _MethodsGrid(
                methods: _methods,
                onAdd: _openAddPage,
                onSetDefault: _setDefault,
                onDelete: _deleteMethod,
                deletingId: _deletingId,
                defaultingId: _defaultingId,
              ),
          ],
        ),
      ),
    );
  }
}

class _MethodsGrid extends StatelessWidget {
  const _MethodsGrid({
    required this.methods,
    required this.onAdd,
    required this.onSetDefault,
    required this.onDelete,
    required this.deletingId,
    required this.defaultingId,
  });

  final List<SavedPaymentMethod> methods;
  final VoidCallback onAdd;
  final Future<void> Function(SavedPaymentMethod method) onSetDefault;
  final Future<void> Function(SavedPaymentMethod method) onDelete;
  final String? deletingId;
  final String? defaultingId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 650
                ? 2
                : 1;
        final mainAxisExtent = crossAxisCount == 1 ? 150.0 : 144.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: methods.length + 1,
          itemBuilder: (context, index) {
            if (index == methods.length) {
              return _AddTile(onTap: onAdd);
            }
            final method = methods[index];
            return _PaymentMethodCard(
              method: method,
              isDefaulting: defaultingId == method.id,
              isDeleting: deletingId == method.id,
              onSetDefault: method.isDefault ? null : () => onSetDefault(method),
              onDelete: () => onDelete(method),
            );
          },
        );
      },
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

  final SavedPaymentMethod method;
  final bool isDefaulting;
  final bool isDeleting;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = _methodTheme(method.methodType);
    final note = _noteText(method);

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: theme.accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.iconBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: paymentMethodIcon(method),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    method.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: const Color(0xFF101828),
                                        ),
                                  ),
                                ),
                                if (method.isDefault)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: theme.defaultBadgeBackground,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'DEFAULT',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: theme.defaultBadgeForeground,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.25,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MethodChip(
                        label: _methodTypeLabel(method.methodType),
                        backgroundColor: theme.chipBackground,
                        foregroundColor: theme.chipForeground,
                      ),
                      if (method.methodType == 'card')
                        _MethodChip(
                          label: _readDetail(method.details, 'last4').isNotEmpty
                              ? '•••• ${_readDetail(method.details, 'last4')}'
                              : 'Card saved',
                          backgroundColor: const Color(0xFFEAF1FF),
                          foregroundColor: const Color(0xFF2D6EF2),
                        ),
                      if (method.methodType == 'netbanking')
                        if (_readDetail(method.details, 'ifsc').isNotEmpty)
                          _MethodChip(
                            label: _readDetail(method.details, 'ifsc'),
                            backgroundColor: const Color(0xFFE0F4E8),
                            foregroundColor: const Color(0xFF2FA56E),
                          ),
                      if (method.methodType == 'upi')
                        _MethodChip(
                          label: _readDetail(method.details, 'upi_id').isNotEmpty
                              ? _readDetail(method.details, 'upi_id')
                              : 'UPI ID',
                          backgroundColor: const Color(0xFFEAF1FF),
                          foregroundColor: const Color(0xFF2D6EF2),
                        ),
                      if (method.methodType == 'wallet')
                        _MethodChip(
                          label: _readDetail(method.details, 'wallet').isNotEmpty
                              ? _readDetail(method.details, 'wallet')
                              : 'Wallet',
                          backgroundColor: const Color(0xFFF2E8FF),
                          foregroundColor: const Color(0xFF7A4FD6),
                        ),
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF98A2B3),
                            fontSize: 11.5,
                          ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      if (onSetDefault != null)
                        TextButton.icon(
                          onPressed: isDefaulting ? null : onSetDefault,
                          icon: isDefaulting
                              ? const SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  Icons.star_outline_rounded,
                                  size: 16,
                                  color: theme.accent,
                                ),
                          label: Text(
                            'Set default',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: theme.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        onPressed: isDeleting ? null : onDelete,
                        icon: isDeleting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline_rounded, size: 18),
                        color: const Color(0xFF98A2B3),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFB8DCC7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
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
                    fontSize: 14.5,
                    color: const Color(0xFF101828),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Credit, Debit, or Bank Transfer',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
      ),
    );
  }
}

class _MethodCardTheme {
  const _MethodCardTheme({
    required this.surface,
    required this.border,
    required this.shadow,
    required this.accent,
    required this.iconBackground,
    required this.chipBackground,
    required this.chipForeground,
    required this.defaultBadgeBackground,
    required this.defaultBadgeForeground,
  });

  final Color surface;
  final Color border;
  final Color shadow;
  final Color accent;
  final Color iconBackground;
  final Color chipBackground;
  final Color chipForeground;
  final Color defaultBadgeBackground;
  final Color defaultBadgeForeground;
}

_MethodCardTheme _methodTheme(String methodType) {
  switch (methodType) {
    case 'card':
      return const _MethodCardTheme(
        surface: Color(0xFFF8FBFF),
        border: Color(0xFFDCE8FF),
        shadow: Color(0x1A2D6EF2),
        accent: Color(0xFF2D6EF2),
        iconBackground: Color(0xFFEAF1FF),
        chipBackground: Color(0xFFEAF1FF),
        chipForeground: Color(0xFF2D6EF2),
        defaultBadgeBackground: Color(0xFFEAF1FF),
        defaultBadgeForeground: Color(0xFF2D6EF2),
      );
    case 'wallet':
      return const _MethodCardTheme(
        surface: Color(0xFFFCF9FF),
        border: Color(0xFFE7DBFF),
        shadow: Color(0x1A7A4FD6),
        accent: Color(0xFF7A4FD6),
        iconBackground: Color(0xFFF2E8FF),
        chipBackground: Color(0xFFF2E8FF),
        chipForeground: Color(0xFF7A4FD6),
        defaultBadgeBackground: Color(0xFFF2E8FF),
        defaultBadgeForeground: Color(0xFF7A4FD6),
      );
    case 'upi':
    case 'netbanking':
    default:
      return const _MethodCardTheme(
        surface: Color(0xFFF8FCFA),
        border: Color(0xFFDDF2E5),
        shadow: Color(0x1A2FA56E),
        accent: Color(0xFF2FA56E),
        iconBackground: Color(0xFFE0F4E8),
        chipBackground: Color(0xFFE0F4E8),
        chipForeground: Color(0xFF2FA56E),
        defaultBadgeBackground: Color(0xFFE0F4E8),
        defaultBadgeForeground: Color(0xFF2FA56E),
      );
  }
}

String _methodTypeLabel(String methodType) {
  switch (methodType) {
    case 'card':
      return 'Card';
    case 'netbanking':
      return 'Bank';
    case 'wallet':
      return 'Wallet';
    case 'upi':
      return 'UPI';
    default:
      return 'Method';
  }
}

String _readDetail(Map<String, dynamic> details, String key) {
  final value = details[key];
  if (value is String) {
    return value.trim();
  }
  return value?.toString().trim() ?? '';
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 650
                ? 2
                : 1;
        final mainAxisExtent = crossAxisCount == 1 ? 164.0 : 156.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
          ),
        );
      },
    );
  }
}

String _noteText(SavedPaymentMethod method) {
  final note = readString(method.details, const ['note']);
  return note;
}
