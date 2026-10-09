import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ssk/l10n/app_localizations.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_dashboard_models.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  bool _kycApproved = false;
  bool _loadingKyc = true;
  bool _openingBrokerChat = false;
  String? _activeUserId;
  bool _sessionSyncQueued = false;

  @override
  void initState() {
    super.initState();
    _activeUserId = ref.read(authSessionProvider).valueOrNull?.user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKycStatus();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loadingKyc = true);
    ref.invalidate(driverDashboardProvider);
    await _loadKycStatus();
    // Dashboard refetch surfaces through the watcher; await it so the
    // spinner doesn't vanish before fresh data lands.
    try {
      await ref.read(driverDashboardProvider.future);
    } catch (_) {
      // Errors surface through the watcher; the refresh still ends.
    }
  }

  Future<void> _openBrokerChat() async {
    if (_openingBrokerChat) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _openingBrokerChat = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBrokerDirectChatThread(accessToken: session.tokens.accessToken);
      final data = response['data'];
      final thread = data is Map<String, dynamic>
          ? (data['thread'] is Map
                ? (data['thread'] as Map).cast<String, dynamic>()
                : data)
          : response['thread'] is Map
          ? (response['thread'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final threadId = thread['id']?.toString().trim().isNotEmpty == true
          ? thread['id'].toString().trim()
          : thread['threadId']?.toString().trim() ?? '';
      if (!mounted) return;
      if (threadId.isEmpty) {
        throw StateError('Chat thread unavailable.');
      }
      context.push('/driver/chats/direct/$threadId');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingBrokerChat = false);
      }
    }
  }

  bool _isApprovedStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('verified') ||
        normalized.contains('approved') ||
        normalized.contains('complete');
  }

  Future<void> _loadKycStatus() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _kycApproved = false;
        _loadingKyc = false;
      });
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getKycStatus(accessToken: session.tokens.accessToken);
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final status = data['kyc_status']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _kycApproved = _isApprovedStatus(status);
        _loadingKyc = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _kycApproved = false;
        _loadingKyc = false;
      });
    }
  }

  void _syncKycStateForSession(String? userId) {
    _sessionSyncQueued = false;
    _activeUserId = userId;
    setState(() {
      _kycApproved = false;
      _loadingKyc = true;
    });

    if (userId == null) {
      setState(() {
        _loadingKyc = false;
      });
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
    final dashboard = ref.watch(driverDashboardProvider).valueOrNull;
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    final user = session?.user;
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
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/driver/home'),
                  icon: const Icon(AppIcons.arrow_back_rounded, size: 18),
                  label: Text(l10n.back),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _ProfileCard(
                user: user,
                kycApproved: !_loadingKyc && _kycApproved,
                truckType: _truckTypeLabel(dashboard?.assignedTruck),
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
                    title: l10n.kycRegistration,
                    subtitle: _loadingKyc
                        ? l10n.checkingVerificationStatus
                        : _kycApproved
                        ? l10n.verified
                        : l10n.completeDriverVerification,
                    icon: _kycApproved
                        ? AppIcons.verified_rounded
                        : AppIcons.verified_user_outlined,
                    accent: _kycApproved
                        ? AppColors.brand
                        : AppColors.warningText,
                    highlighted: !_loadingKyc && !_kycApproved,
                    onTap: () => context.push('/driver/kyc-registration'),
                  ),
                  _ProfileMenuTile(
                    title: l10n.earnings,
                    subtitle: l10n.driverEarningsSubtitle,
                    icon: AppIcons.trending_up_rounded,
                    accent: AppColors.brand,
                    onTap: () => context.go('/driver/earnings'),
                  ),
                  _ProfileMenuTile(
                    title: 'Monthly Hiring',
                    subtitle:
                        'List your truck for monthly hire and manage listings',
                    icon: AppIcons.calendar_month_rounded,
                    accent: AppColors.brand,
                    onTap: () => context.push('/driver/monthly-hiring'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.communication,
                children: [
                  _ProfileMenuTile(
                    title: _openingBrokerChat
                        ? l10n.openingChat
                        : l10n.messageMyBroker,
                    subtitle: l10n.messageMyBrokerSubtitle,
                    icon: AppIcons.chat_bubble_outline_rounded,
                    accent: AppColors.brand,
                    onTap: _openingBrokerChat ? null : _openBrokerChat,
                  ),
                  _ProfileMenuTile(
                    title: l10n.allChats,
                    subtitle: l10n.allChatsSubtitle,
                    icon: AppIcons.forum_outlined,
                    accent: AppColors.brand,
                    onTap: () => context.push('/driver/chats'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _ProfileSection(
                title: 'Payments',
                children: [_DriverPaymentSection()],
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: l10n.security,
                children: [
                  _ProfileMenuTile(
                    title: l10n.changePasswordTitleCase,
                    subtitle: l10n.driverChangePasswordSubtitle,
                    icon: AppIcons.lock_outline_rounded,
                    onTap: () => context.push('/change-password'),
                  ),
                  _ProfileMenuTile(
                    title: l10n.logout,
                    subtitle: l10n.logoutSubtitle,
                    icon: AppIcons.logout_rounded,
                    accent: AppColors.dangerIcon,
                    onTap: () async {
                      await ref.read(authSessionProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
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
  const _ProfileCard({
    required this.user,
    required this.kycApproved,
    required this.truckType,
  });

  final SskUser? user;
  final bool kycApproved;
  final String truckType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : l10n.driverAccount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDark.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
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
            child: SskProfileAvatar(
              imageUrl: user?.profileImage,
              size: 72,
              borderColor: kycApproved
                  ? const Color(0xFFE5EAF0)
                  : AppColors.warningBorder,
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
            user?.phone.trim().isNotEmpty == true
                ? user!.phone
                : user?.email ?? l10n.noAccountConnected,
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileChip(
                icon: kycApproved
                    ? AppIcons.verified_rounded
                    : AppIcons.hourglass_top_rounded,
                label: kycApproved ? l10n.verified : l10n.kycPending,
              ),
              _ProfileChip(
                icon: AppIcons.local_shipping_outlined,
                label: l10n.driver,
              ),
              if (truckType.isNotEmpty)
                _ProfileChip(
                  icon: AppIcons.fire_truck_outlined,
                  label: truckType,
                ),
            ],
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
          const Icon(
            AppIcons.language_rounded,
            size: 21,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.languageSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
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

String _truckTypeLabel(Map<String, dynamic>? truck) {
  if (truck == null || truck.isEmpty) {
    return '';
  }
  return _firstTruckValue(truck, const [
    'category',
    'type',
    'vehicleType',
    'vehicle_type',
    'truckType',
    'truck_type',
    'model',
    'registration',
    'registrationNumber',
    'registration_number',
  ]);
}

String _firstTruckValue(Map<String, dynamic> value, List<String> keys) {
  for (final key in keys) {
    final raw = value[key]?.toString().trim();
    if (raw != null && raw.isNotEmpty && raw.toLowerCase() != 'null') {
      return raw;
    }
  }
  return '';
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
  final VoidCallback? onTap;
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
                      color: AppColors.textTertiary,
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

/// Collection payment settings (web parity: `driver/Profile.jsx` UPI ID +
/// QR code management — `GET/PATCH .../me/upi-id`, `GET/POST/DELETE
/// .../me/qr-code`). Used for trip payment collection.
class _DriverPaymentSection extends ConsumerStatefulWidget {
  const _DriverPaymentSection();

  @override
  ConsumerState<_DriverPaymentSection> createState() =>
      _DriverPaymentSectionState();
}

class _DriverPaymentSectionState extends ConsumerState<_DriverPaymentSection> {
  final _upiController = TextEditingController();
  final _picker = ImagePicker();
  bool _loading = true;
  bool _savingUpi = false;
  bool _uploadingQr = false;
  bool _removingQr = false;
  bool _hasQr = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  Map<String, dynamic> _dataOf(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return data;
    return response;
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        ref
            .read(apiClientProvider)
            .getDriverUpiId(accessToken: session.tokens.accessToken),
        ref
            .read(apiClientProvider)
            .getDriverQrCode(accessToken: session.tokens.accessToken),
      ]);
      if (!mounted) return;
      final upiData = _dataOf(results[0]);
      final qrData = _dataOf(results[1]);
      setState(() {
        _upiController.text = _readString(upiData, const ['upiId', 'upi_id']);
        _hasQr =
            _readString(qrData, const ['qrCodeUrl', 'qr_code_url']).isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveUpi() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    final upiId = _upiController.text.trim();
    if (upiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your UPI ID first.')),
      );
      return;
    }
    setState(() => _savingUpi = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .updateDriverUpiId(
            accessToken: session.tokens.accessToken,
            upiId: upiId,
          );
      if (!mounted) return;
      final saved = _readString(_dataOf(response), const ['upiId', 'upi_id']);
      setState(() => _upiController.text = saved.isNotEmpty ? saved : upiId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingUpi = false);
    }
  }

  Future<void> _uploadQr() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() => _uploadingQr = true);
    try {
      await ref
          .read(apiClientProvider)
          .uploadDriverQrCode(
            accessToken: session.tokens.accessToken,
            filePath: picked.path,
          );
      if (!mounted) return;
      setState(() => _hasQr = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code uploaded.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingQr = false);
    }
  }

  Future<void> _removeQr() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _removingQr = true);
    try {
      await ref
          .read(apiClientProvider)
          .deleteDriverQrCode(accessToken: session.tokens.accessToken);
      if (!mounted) return;
      setState(() => _hasQr = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code removed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _removingQr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _upiController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveUpi(),
            decoration: InputDecoration(
              labelText: 'UPI ID',
              hintText: 'yourname@upi',
              prefixIcon: const Icon(AppIcons.qr_code_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _savingUpi ? null : _saveUpi,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_savingUpi ? 'Saving…' : 'Save UPI ID'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _hasQr ? 'QR code uploaded' : 'No QR code yet',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _uploadingQr ? null : _uploadQr,
                icon: const Icon(AppIcons.upload_rounded, size: 18),
                label: Text(_uploadingQr ? 'Uploading…' : 'Upload'),
              ),
              if (_hasQr)
                TextButton.icon(
                  onPressed: _removingQr ? null : _removeQr,
                  icon: const Icon(AppIcons.delete_outline_rounded, size: 18),
                  label: Text(_removingQr ? 'Removing…' : 'Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.dangerIcon,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
