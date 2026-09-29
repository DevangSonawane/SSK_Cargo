import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Monthly vehicle hiring enquiries — web `MonthlyHiring.jsx` parity.
/// Raise an enquiry and the team follows up; the list shows open/contacted/
/// closed status pills.
class MonthlyHiringEnquiry {
  const MonthlyHiringEnquiry({
    required this.id,
    required this.location,
    this.truckCategory = '',
    this.truckCategoryLabel = '',
    this.startDate,
    this.endDate,
    this.pricingType = '',
    this.budgetAmount,
    this.description = '',
    this.status = 'open',
    this.createdAt,
  });

  factory MonthlyHiringEnquiry.fromJson(Map<String, dynamic> json) {
    double? budget;
    final rawBudget =
        json['budgetAmount'] ?? json['budget_amount'] ?? json['budget'];
    if (rawBudget is num) {
      budget = rawBudget.toDouble();
    } else if (rawBudget != null) {
      budget = double.tryParse(rawBudget.toString());
    }
    DateTime? parseDate(Object? value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    String str(Object? value) {
      final text = value?.toString().trim() ?? '';
      return text.toLowerCase() == 'null' ? '' : text;
    }

    final category = str(json['truckCategory'] ?? json['truck_category']);
    return MonthlyHiringEnquiry(
      id: str(json['id']),
      location: str(json['location']),
      truckCategory: category,
      truckCategoryLabel: str(
        json['truckCategoryLabel'] ?? json['truck_category_label'],
      ),
      startDate: parseDate(json['startDate'] ?? json['start_date']),
      endDate: parseDate(json['endDate'] ?? json['end_date']),
      pricingType: str(json['pricingType'] ?? json['pricing_type']),
      budgetAmount: budget,
      description: str(json['description']),
      status: str(json['status']).isEmpty ? 'open' : str(json['status']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  final String id;
  final String location;
  final String truckCategory;
  final String truckCategoryLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final String pricingType;
  final double? budgetAmount;
  final String description;
  final String status;
  final DateTime? createdAt;
}

List<MonthlyHiringEnquiry> parseMonthlyHiringEnquiries(
  Map<String, dynamic> response,
) {
  final data = response['data'];
  Object? list = response['enquiries'];
  if (data is Map<String, dynamic>) {
    list = data['enquiries'] ?? data['items'] ?? list;
  }
  if (list is! Iterable) return const [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(MonthlyHiringEnquiry.fromJson)
      .toList(growable: false);
}

class ClientMonthlyHiringScreen extends ConsumerStatefulWidget {
  const ClientMonthlyHiringScreen({super.key});

  @override
  ConsumerState<ClientMonthlyHiringScreen> createState() =>
      _ClientMonthlyHiringScreenState();
}

class _ClientMonthlyHiringScreenState
    extends ConsumerState<ClientMonthlyHiringScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MonthlyHiringEnquiry> _enquiries = const [];
  bool _loading = true;
  bool _error = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MonthlyHiringEnquiry> get _filteredEnquiries {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _enquiries;
    return _enquiries
        .where((enquiry) {
          return [
            enquiry.location,
            enquiry.truckCategory,
            enquiry.truckCategoryLabel,
            enquiry.pricingType,
            enquiry.description,
            enquiry.status,
          ].any((value) => value.toLowerCase().contains(q));
        })
        .toList(growable: false);
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
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
      final response = await ref
          .read(apiClientProvider)
          .getMonthlyHiringEnquiries(accessToken: session.tokens.accessToken);
      if (!mounted) return;
      setState(() {
        _enquiries = parseMonthlyHiringEnquiries(response);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNew() async {
    final created = await context.push<bool>('/client/monthly-hiring/new');
    if (created == true && mounted) {
      unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final filtered = _filteredEnquiries;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppIcons.arrow_back_rounded),
        ),
        title: const Text('Monthly Vehicle Hiring'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNew,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(AppIcons.add_rounded),
        label: const Text('New Enquiry'),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 92),
          children: [
            if (session == null)
              _MonthlyEmptyState(
                icon: AppIcons.lock_outline_rounded,
                title: 'Sign in to manage enquiries',
                subtitle:
                    'We need an active client session before we can load monthly hiring requests.',
                actionLabel: 'Retry',
                onAction: _load,
              )
            else if (_loading)
              const Column(
                children: [
                  _EnquirySkeleton(),
                  SizedBox(height: 12),
                  _EnquirySkeleton(),
                ],
              )
            else if (_error)
              _MonthlyEmptyState(
                icon: AppIcons.error_outline_rounded,
                title: 'Could not load enquiries',
                subtitle: 'Pull to refresh or try again in a moment.',
                actionLabel: 'Retry',
                onAction: _load,
              )
            else if (_enquiries.isEmpty)
              const _MonthlyEmptyState(
                icon: AppIcons.local_shipping_outlined,
                title: 'No enquiries yet',
                subtitle:
                    'Tell us where and for how long you need a truck, and our team will follow up.',
              )
            else ...[
              _MonthlyHiringSearchField(
                controller: _searchController,
                query: _query,
                onQueryChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const _MonthlyEmptyState(
                  icon: AppIcons.search_off_rounded,
                  title: 'No enquiries match your search',
                  subtitle: 'Try another location, truck type, or status.',
                )
              else
                _EnquiryList(enquiries: filtered, onAdd: _openNew),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthlyHiringSearchField extends StatelessWidget {
  const _MonthlyHiringSearchField({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Icon(
            AppIcons.search_rounded,
            color: context.colors.textTertiary,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              decoration: const InputDecoration(
                hintText: 'Search monthly enquiries...',
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onQueryChanged('');
              },
              icon: const Icon(AppIcons.close_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class _EnquiryList extends StatelessWidget {
  const _EnquiryList({required this.enquiries, required this.onAdd});

  final List<MonthlyHiringEnquiry> enquiries;
  final VoidCallback onAdd;

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

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 168,
          ),
          itemCount: enquiries.length + 1,
          itemBuilder: (context, index) {
            if (index == enquiries.length) {
              return _AddEnquiryTile(onTap: onAdd);
            }
            return _EnquiryCard(enquiry: enquiries[index]);
          },
        );
      },
    );
  }
}

class _AddEnquiryTile extends StatelessWidget {
  const _AddEnquiryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.colors.brandBorder, width: 1.5),
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
              child: const Icon(AppIcons.add_rounded, color: AppColors.brand),
            ),
            const SizedBox(height: 10),
            Text(
              'New Enquiry',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monthly Truck Hiring',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnquirySkeleton extends StatelessWidget {
  const _EnquirySkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: colors.fillSubtle,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({required this.enquiry});

  final MonthlyHiringEnquiry enquiry;

  String get _statusLabel {
    switch (enquiry.status.toLowerCase()) {
      case 'contacted':
        return 'Contacted';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }

  Color _statusBg(BuildContext context) {
    switch (enquiry.status.toLowerCase()) {
      case 'contacted':
        return AppColors.warningFill;
      case 'closed':
        return context.colors.fillSubtle;
      default:
        return context.colors.brandFill;
    }
  }

  Color _statusFg(BuildContext context) {
    switch (enquiry.status.toLowerCase()) {
      case 'contacted':
        return context.colors.warningEmphasis;
      case 'closed':
        return context.colors.textTertiary;
      default:
        return context.colors.brandEmphasis;
    }
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = [
      if (enquiry.truckCategoryLabel.isNotEmpty)
        enquiry.truckCategoryLabel
      else if (enquiry.truckCategory.isNotEmpty)
        enquiry.truckCategory,
      if (enquiry.startDate != null && enquiry.endDate != null)
        '${_formatDate(enquiry.startDate!)} – ${_formatDate(enquiry.endDate!)}',
      enquiry.pricingType == 'per_km' ? 'Per KM' : 'Fixed Rate',
      if (enquiry.budgetAmount != null)
        '₹${enquiry.budgetAmount!.toStringAsFixed(enquiry.budgetAmount! % 1 == 0 ? 0 : 2)}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.brandFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              AppIcons.local_shipping_outlined,
              color: colors.brandEmphasis,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        enquiry.location.isNotEmpty
                            ? enquiry.location
                            : 'Location not specified',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _StatusChip(
                      label: _statusLabel,
                      background: _statusBg(context),
                      foreground: _statusFg(context),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                if (enquiry.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    enquiry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textTertiary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  enquiry.createdAt == null
                      ? 'Submitted recently'
                      : 'Submitted ${_formatDate(enquiry.createdAt!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MonthlyEmptyState extends StatelessWidget {
  const _MonthlyEmptyState({
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.line),
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
            child: Icon(icon, color: AppColors.brand, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
