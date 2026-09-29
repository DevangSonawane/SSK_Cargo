import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import '../widgets/broker_flow_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ssk/l10n/app_localizations.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class BrokerProfileScreen extends ConsumerStatefulWidget {
  const BrokerProfileScreen({super.key});

  @override
  ConsumerState<BrokerProfileScreen> createState() =>
      _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends ConsumerState<BrokerProfileScreen> {
  bool _kycApproved = false;
  bool _loadingKyc = true;
  String? _activeUserId;
  bool _sessionSyncQueued = false;

  @override
  void initState() {
    super.initState();
    _activeUserId = ref.read(authSessionProvider).valueOrNull?.user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadKycStatus());
  }

  Future<void> _loadKycStatus() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() => _loadingKyc = false);
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getKycStatusForUser(
            accessToken: session.tokens.accessToken,
            userId: session.user.id,
          );
      final data = _asMap(response['data']);
      final status = data['kyc_status']?.toString().toLowerCase() ?? '';
      if (!mounted) return;
      setState(() {
        _kycApproved =
            status.contains('verified') ||
            status.contains('approved') ||
            status.contains('complete');
        _loadingKyc = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingKyc = false);
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loadingKyc = true);
    await _loadKycStatus();
  }

  void _syncKycStateForSession(String? userId) {
    _sessionSyncQueued = false;
    _activeUserId = userId;
    setState(() {
      _kycApproved = false;
      _loadingKyc = true;
    });

    if (userId == null) {
      setState(() => _loadingKyc = false);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadKycStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.user;
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = user?.id;
    if (currentUserId != _activeUserId && !_sessionSyncQueued) {
      _sessionSyncQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncKycStateForSession(currentUserId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              BrokerBackButton(onTap: () => context.go('/broker/home')),
              const SizedBox(height: 10),
              _ProfileCard(
                user: user,
                kycApproved: !_loadingKyc && _kycApproved,
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.preferences,
                children: [
                  _LanguageTile(
                    selected: locale.languageCode,
                    onChanged: (languageCode) {
                      ref
                          .read(localeProvider.notifier)
                          .setLanguageCode(languageCode);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.account,
                children: [
                  _ProfileMenuTile(
                    title: l10n.manageAccountTitleCase,
                    subtitle: l10n.driverManageAccountSubtitle,
                    icon: AppIcons.person_outline_rounded,
                    onTap: () => context.push('/manage-account'),
                  ),
                  _ProfileMenuTile(
                    title: l10n.earnings,
                    subtitle: l10n.brokerEarningsSubtitle,
                    icon: AppIcons.trending_up_rounded,
                    accent: AppColors.brand,
                    onTap: () => context.push('/broker/earnings'),
                  ),
                  _ProfileMenuTile(
                    title: l10n.kycRegistration,
                    subtitle: _loadingKyc
                        ? l10n.checkingVerificationStatus
                        : _kycApproved
                        ? l10n.verified
                        : l10n.completeBrokerVerification,
                    icon: _kycApproved
                        ? AppIcons.verified_rounded
                        : AppIcons.verified_user_outlined,
                    accent: _kycApproved
                        ? AppColors.brand
                        : AppColors.warningText,
                    highlighted: !_loadingKyc && !_kycApproved,
                    onTap: () => context.push('/broker/kyc-registration'),
                  ),
                  _ProfileMenuTile(
                    title: l10n.changePasswordTitleCase,
                    subtitle: l10n.driverChangePasswordSubtitle,
                    icon: AppIcons.lock_outline_rounded,
                    onTap: () => context.push('/change-password'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.support,
                children: [
                  _ProfileMenuTile(
                    title: l10n.helpSupport,
                    subtitle: l10n.brokerHelpSubtitle,
                    icon: AppIcons.support_agent_rounded,
                    accent: AppColors.brand,
                    onTap: () {},
                  ),
                  _ProfileMenuTile(
                    title: l10n.logout,
                    subtitle: l10n.logoutSubtitle,
                    icon: AppIcons.logout_rounded,
                    accent: AppColors.dangerIcon,
                    onTap: () async {
                      await ref.read(authSessionProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user, required this.kycApproved});

  final SskUser? user;
  final bool kycApproved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : l10n.brokerAccount;
    final initial = displayName.isEmpty ? 'B' : displayName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandBright],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kycApproved
                  ? AppColors.brand.withValues(alpha: 0.25)
                  : AppColors.warningFill,
              border: Border.all(
                color: kycApproved
                    ? Colors.white.withValues(alpha: 0.32)
                    : AppColors.warningBorder,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: kycApproved ? Colors.white : AppColors.warningText,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user?.email ?? l10n.noEmailConnected,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Text(
              l10n.standardPlan,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              AppIcons.language_rounded,
              color: AppColors.brand,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.languageSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 132,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.75)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                icon: const Icon(
                  AppIcons.keyboard_arrow_down_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.fromLTRB(14, 11, 10, 11),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                items: [
                  DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                  DropdownMenuItem(value: 'hi', child: Text(l10n.hindi)),
                ],
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 62,
                    color: AppColors.line,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.brand,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: highlighted
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
            : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.warningFill : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: highlighted
              ? Border.all(color: AppColors.warningBorder)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              AppIcons.chevron_right_rounded,
              color: AppColors.line,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : const <String, dynamic>{};
}
