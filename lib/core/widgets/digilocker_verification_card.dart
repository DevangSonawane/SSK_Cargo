import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/api_client.dart';
import '../providers/kyc_status_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';
import 'package:ssk/l10n/app_localizations.dart';

/// Document keys, matching the backend's `verification_results` and the web
/// client's `REQUIRED` map (Onboarding.jsx).
const String kDigiDocAadhaar = 'aadhaar';
const String kDigiDocPan = 'pan';
const String kDigiDocDrivingLicense = 'drivingLicense';

/// Per-document result status. Mirrors the web `docs` map values.
const String kDigiStatusIdle = 'idle';
const String kDigiStatusLoading = 'loading';
const String kDigiStatusVerified = 'verified';
const String kDigiStatusMissing = 'missing';
const String kDigiStatusFailed = 'failed';
const String kDigiStatusError = 'error';

/// Documents one DigiLocker session covers, per role (guide + web client).
List<String> digilockerRequiredDocs(String role) {
  if (role.trim().toLowerCase() == 'driver') {
    return const [kDigiDocAadhaar, kDigiDocPan, kDigiDocDrivingLicense];
  }
  return const [kDigiDocAadhaar, kDigiDocPan];
}

/// Pulls already-known per-document results out of a
/// `GET /api/kyc/status` submission (`verification_results`), limited to this
/// role's required docs — exactly like the web prefill effect.
Map<String, String> parseVerificationStatuses(
  Map<String, dynamic>? verificationResults,
  List<String> required,
) {
  final known = <String, String>{};
  if (verificationResults == null) return known;
  for (final key in required) {
    final entry = verificationResults[key];
    final status = entry is Map<String, dynamic>
        ? entry['status']?.toString()
        : null;
    if (status != null && status.trim().isNotEmpty) {
      known[key] = status.trim().toLowerCase();
    }
  }
  return known;
}

/// Web `needsFallback` for a single status value: the number-entry fallback
/// (and its photo upload) shows only for these.
bool digiNeedsFallback(String? status) {
  return const {'missing', 'failed', 'error', 'loading'}.contains(status);
}

/// Maps a photo-upload document key (e.g. `'pan_photo_url'`) to its
/// DigiLocker document key (`'pan'`). Photo uploads render only for documents
/// that actually need the manual-review fallback — web parity (Onboarding.jsx
/// renders `KycDocumentUpload` inside each doc's own fallback block, so a
/// verified document never shows a "Not uploaded" card).
String? digiDocKeyForUploadKey(String uploadKey) {
  switch (uploadKey) {
    case 'pan_photo_url':
      return 'pan';
    case 'license_photo_url':
      return 'drivingLicense';
    case 'aadhaar_photo_url':
      return 'aadhaar';
    default:
      return null;
  }
}
/// change, so it can build the finish payload and the Finish / Submit-for-
/// review label without owning any of this flow's state.
/// Snapshot emitted to the hosting KYC screen whenever values or statuses
/// change, so it can build the finish payload and the Finish / Submit-for-
/// review label without owning any of this flow's state.
class DigilockerVerificationSnapshot {
  const DigilockerVerificationSnapshot({
    required this.values,
    required this.statuses,
  });

  /// Typed field values keyed like the backend documents map
  /// (`pan_number`, `license_number`, `date_of_birth`, `aadhaar_number`,
  /// `vehicle_registration_number`, …).
  final Map<String, String> values;

  /// Per-document result status keyed by document (`aadhaar` / `pan` /
  /// `drivingLicense`).
  final Map<String, String> statuses;
}

/// Where DigiLocker sends the user afterwards. Must be https (the backend
/// 422s anything else). The app can't receive the redirect itself — no app
/// link is registered — so this is the backend's onboarding page: the user
/// finishes in the browser, comes back to the app manually, and taps
/// "Check status" (the verification id is already held in memory).
const String kDigilockerRedirectUrl =
    'https://apigadidosti.asynk.in/onboarding';

/// One DigiLocker sign-in covers every document this role needs, with
/// number-entry fallbacks only for documents DigiLocker couldn't supply —
/// a faithful port of the web client's Onboarding.jsx flow:
///
/// start → browser → back in app → status (pending: 4 × 3 s poll, then a
/// manual "Check status" button; failed: message + start again;
/// done: verified settles, missing falls back to entering the number).
class DigilockerVerificationCard extends ConsumerStatefulWidget {
  const DigilockerVerificationCard({
    super.key,
    required this.role,
    required this.accessToken,
    this.userName = '',
    this.initialValues = const {},
    this.initialStatuses = const {},
    this.onChanged,
  });

  /// `'driver'` or `'broker'`.
  final String role;
  final String accessToken;
  final String userName;
  final Map<String, String> initialValues;
  final Map<String, String> initialStatuses;
  final ValueChanged<DigilockerVerificationSnapshot>? onChanged;

  @override
  ConsumerState<DigilockerVerificationCard> createState() =>
      _DigilockerVerificationCardState();
}

class _DigilockerVerificationCardState
    extends ConsumerState<DigilockerVerificationCard> {
  late final List<String> _required;
  final Map<String, String> _statuses = {};
  final Map<String, String?> _messages = {};

  // The DigiLocker session as a whole: idle | loading | error, plus its id
  // so a still-pending one can be re-checked by hand (web `dg` state).
  String _sessionStatus = 'idle';
  String? _sessionMessage;
  String? _verificationId;
  int _pollToken = 0;

  bool _verifyingPan = false;
  bool _verifyingDl = false;

  late final TextEditingController _aadhaarController;
  late final TextEditingController _panController;
  late final TextEditingController _licenseController;
  late final TextEditingController _dobController;
  late final TextEditingController _vehicleRegController;
  late final TextEditingController _vehicleInsuranceController;
  late final TextEditingController _gstController;
  late final TextEditingController _bankAccountController;
  late final TextEditingController _businessRegController;

  bool get _isDriver => widget.role.trim().toLowerCase() == 'driver';

  @override
  void initState() {
    super.initState();
    _required = digilockerRequiredDocs(widget.role);
    for (final key in _required) {
      final initial = widget.initialStatuses[key]?.trim().toLowerCase();
      _statuses[key] = initial?.isNotEmpty == true ? initial! : 'idle';
    }
    String initial(String key) => widget.initialValues[key] ?? '';
    _aadhaarController = TextEditingController(text: initial('aadhaar_number'));
    _panController = TextEditingController(text: initial('pan_number'));
    _licenseController = TextEditingController(
      text: initial('license_number'),
    );
    _dobController = TextEditingController(text: initial('date_of_birth'));
    _vehicleRegController = TextEditingController(
      text: initial('vehicle_registration_number'),
    );
    _vehicleInsuranceController = TextEditingController(
      text: initial('vehicle_insurance_number'),
    );
    _gstController = TextEditingController(text: initial('gst_number'));
    _bankAccountController = TextEditingController(
      text: initial('bank_account_number'),
    );
    _businessRegController = TextEditingController(
      text: initial('business_registration_number'),
    );
    // Report the prefilled state so the host screen starts in sync.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emit();
    });
  }

  @override
  void dispose() {
    // Invalidate any in-flight poll chain.
    _pollToken++;
    _aadhaarController.dispose();
    _panController.dispose();
    _licenseController.dispose();
    _dobController.dispose();
    _vehicleRegController.dispose();
    _vehicleInsuranceController.dispose();
    _gstController.dispose();
    _bankAccountController.dispose();
    _businessRegController.dispose();
    super.dispose();
  }

  Map<String, String> _currentValues() {
    return {
      'aadhaar_number': _aadhaarController.text.replaceAll(' ', '').trim(),
      'pan_number': _panController.text.trim(),
      'license_number': _licenseController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
      'vehicle_registration_number': _vehicleRegController.text.trim(),
      'vehicle_insurance_number': _vehicleInsuranceController.text.trim(),
      'gst_number': _gstController.text.trim(),
      'bank_account_number': _bankAccountController.text.trim(),
      'business_registration_number': _businessRegController.text.trim(),
    };
  }

  void _emit() {
    widget.onChanged?.call(
      DigilockerVerificationSnapshot(
        values: _currentValues(),
        statuses: Map<String, String>.of(_statuses),
      ),
    );
  }

  void _setDoc(String key, String status, [String? message]) {
    if (!mounted) return;
    setState(() {
      _statuses[key] = status;
      _messages[key] = message;
    });
    _emit();
  }

  /// A document shows its number-entry fallback once DigiLocker couldn't
  /// supply it (or a number check on it just failed) — never up front, so
  /// the normal path has nothing to type at all. ("loading" is only ever set
  /// by these fallback checks themselves, so the fields stay visible through
  /// it instead of vanishing mid-check.) Web `needsFallback`, verbatim.
  bool _needsFallback(String key) {
    return const {'missing', 'failed', 'error', 'loading'}.contains(
      _statuses[key],
    );
  }

  bool get _allVerified =>
      _required.every((key) => _statuses[key] == 'verified');

  // One DigiLocker sign-in covers every document this role needs (a browser
  // round trip, not inline entry): start → the user leaves for DigiLocker →
  // they come back to the app manually → Check status resolves it. Typed
  // fallback values live in these controllers, which survive the trip since
  // the app itself is never torn down (web stashes them in sessionStorage
  // because a redirect reloads the page — no equivalent hazard here).
  Future<void> _startDigilocker() async {
    if (_sessionStatus == 'loading') return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _sessionStatus = 'loading';
      _sessionMessage = null;
      _verificationId = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .startDigilockerVerification(
            accessToken: widget.accessToken,
            redirectUrl: kDigilockerRedirectUrl,
          );
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final url = data['url']?.toString() ?? '';
      final verificationId = data['verificationId']?.toString() ?? '';
      if (url.isEmpty || verificationId.isEmpty) {
        throw ApiException(l10n.coreDigilockerNoLoginLink);
      }
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        setState(() {
          _sessionStatus = 'error';
          _sessionMessage = l10n.coreDigilockerOpenBrowserFailed;
          _verificationId = null;
        });
        return;
      }
      setState(() => _verificationId = verificationId);
      // Same poll the web client runs on return: a few quick tries, then a
      // manual button rather than spinning forever.
      await _checkDigilocker(verificationId, 0);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionStatus = 'error';
        _sessionMessage = error.message;
        _verificationId = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionStatus = 'error';
        _sessionMessage = error.toString().replaceFirst('Exception: ', '');
        _verificationId = null;
      });
    }
  }

  // 'pending' means the user hasn't finished in DigiLocker yet (or Cashfree
  // is still processing) — poll briefly, then hand the retry to a manual
  // button rather than spinning forever. Web `checkDigilocker`, verbatim.
  Future<void> _checkDigilocker(String verificationId, int attempt) async {
    final token = ++_pollToken;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _sessionStatus = 'loading';
      _sessionMessage = null;
      _verificationId = verificationId;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .getDigilockerStatus(
            accessToken: widget.accessToken,
            verificationId: verificationId,
          );
      if (!mounted || token != _pollToken) return;
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final status = data['status']?.toString().trim().toLowerCase() ?? '';
      final message = data['message']?.toString();
      if (status == 'pending') {
        if (attempt < 4) {
          await Future<void>.delayed(const Duration(seconds: 3));
          if (!mounted || token != _pollToken) return;
          await _checkDigilocker(verificationId, attempt + 1);
          return;
        }
        setState(() {
          _sessionStatus = 'error';
          _sessionMessage = l10n.coreDigilockerPendingRetry;
          _verificationId = verificationId;
        });
        return;
      }
      if (status == 'failed') {
        setState(() {
          _sessionStatus = 'error';
          _sessionMessage =
              (message != null && message.trim().isNotEmpty)
              ? message
              : l10n.coreDigilockerNotComplete;
          _verificationId = null;
        });
        return;
      }
      // Done: verified documents are settled; missing ones fall back to
      // entering the number.
      final documents = data['documents'];
      final docsMap = documents is Map<String, dynamic> ? documents : const {};
      setState(() {
        for (final key in _required) {
          final entry = docsMap[key];
          final docStatus = entry is Map<String, dynamic>
              ? entry['status']?.toString().trim().toLowerCase()
              : null;
          if (docStatus == 'verified') {
            _statuses[key] = 'verified';
            _messages[key] = null;
          } else if (docStatus == 'missing') {
            _statuses[key] = 'missing';
            final details = entry['details'];
            final detailMessage = details is Map<String, dynamic>
                ? details['message']?.toString()
                : null;
            _messages[key] = detailMessage;
          }
        }
        _sessionStatus = 'idle';
        _sessionMessage = null;
        _verificationId = null;
      });
      _emit();
    } on ApiException catch (error) {
      if (!mounted || token != _pollToken) return;
      setState(() {
        _sessionStatus = 'error';
        _sessionMessage = error.message;
        _verificationId = verificationId;
      });
    } catch (error) {
      if (!mounted || token != _pollToken) return;
      setState(() {
        _sessionStatus = 'error';
        _sessionMessage = error.toString().replaceFirst('Exception: ', '');
        _verificationId = verificationId;
      });
    }
  }

  // Fallbacks for a document that isn't in the user's DigiLocker — verify
  // just that one by number. Web `verifyPan` / `verifyDl`, verbatim.
  Future<void> _verifyPan() async {
    final pan = _panController.text.trim();
    if (pan.isEmpty || _verifyingPan) return;
    _setDoc('pan', 'loading', null);
    if (!mounted) return;
    setState(() => _verifyingPan = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .verifyPan(
            accessToken: widget.accessToken,
            pan: pan,
            name: widget.userName,
          );
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final details = data['details'];
      _setDoc(
        'pan',
        data['status']?.toString() ?? 'failed',
        details is Map<String, dynamic> ? details['message']?.toString() : null,
      );
      ref.invalidate(kycStatusProvider);
    } on ApiException catch (error) {
      _setDoc('pan', 'error', error.message);
    } finally {
      if (mounted) setState(() => _verifyingPan = false);
    }
  }

  Future<void> _verifyDrivingLicense() async {
    final dlNumber = _licenseController.text.trim();
    final dob = _dobController.text.trim();
    if (dlNumber.isEmpty || dob.isEmpty || _verifyingDl) return;
    _setDoc('drivingLicense', 'loading', null);
    if (!mounted) return;
    setState(() => _verifyingDl = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .verifyDrivingLicense(
            accessToken: widget.accessToken,
            dlNumber: dlNumber,
            dob: dob,
          );
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final details = data['details'];
      _setDoc(
        'drivingLicense',
        data['status']?.toString() ?? 'failed',
        details is Map<String, dynamic> ? details['message']?.toString() : null,
      );
      ref.invalidate(kycStatusProvider);
    } on ApiException catch (error) {
      _setDoc('drivingLicense', 'error', error.message);
    } finally {
      if (mounted) setState(() => _verifyingDl = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isDriver
              ? l10n.coreDigilockerDriverIntro
              : l10n.coreDigilockerBrokerIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _required.length; i++) ...[
          _DocumentRow(
            docKey: _required[i],
            status: _statuses[_required[i]] ?? 'idle',
            message: _messages[_required[i]],
            fallback: _needsFallback(_required[i])
                ? _fallbackFor(_required[i])
                : null,
          ),
          if (i != _required.length - 1) const SizedBox(height: 10),
        ],
        if (!_allVerified) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _sessionStatus == 'loading' ? null : _startDigilocker,
              icon: _sessionStatus == 'loading'
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(AppIcons.verified_user_outlined, size: 18),
              label: Text(
                _sessionStatus == 'loading'
                    ? l10n.coreDigilockerWorking
                    : l10n.coreDigilockerVerifyButton,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_sessionStatus == 'error' && _sessionMessage != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  AppIcons.gpp_maybe_rounded,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _sessionMessage!,
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                if (_verificationId != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _checkDigilocker(_verificationId!, 0),
                    child: Text(
                      l10n.coreDigilockerCheckStatus,
                      style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
        const SizedBox(height: 16),
        _OptionalDetailsSection(
          isDriver: _isDriver,
          vehicleRegController: _vehicleRegController,
          vehicleInsuranceController: _vehicleInsuranceController,
          gstController: _gstController,
          bankAccountController: _bankAccountController,
          businessRegController: _businessRegController,
          onChanged: (_) => _emit(),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              AppIcons.info_outline_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.coreDigilockerInfoNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _fallbackFor(String key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case 'aadhaar':
        // Aadhaar has no number-check fallback (OTP isn't enabled on this
        // account) — the typed number goes to manual review with the finish
        // submission.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.coreDigilockerAadhaarFallbackNote,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
            ),
            const SizedBox(height: 8),
            _FallbackField(
              controller: _aadhaarController,
              hintText: 'XXXX XXXX XXXX',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              onChanged: (_) => _emit(),
            ),
          ],
        );
      case 'pan':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FallbackField(
              controller: _panController,
              hintText: 'ABCDE1234F',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 8),
            _FallbackVerifyButton(
              label: l10n.coreDigilockerVerifyPan,
              loading: _verifyingPan,
              onPressed: _panController.text.trim().isNotEmpty && !_verifyingPan
                  ? _verifyPan
                  : null,
            ),
          ],
        );
      case 'drivingLicense':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FallbackField(
              controller: _licenseController,
              hintText: 'MH-2020123456789',
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 8),
            _FallbackField(
              controller: _dobController,
              hintText: 'YYYY-MM-DD',
              keyboardType: TextInputType.datetime,
              onChanged: (_) => _emit(),
            ),
            const SizedBox(height: 8),
            _FallbackVerifyButton(
              label: l10n.coreDigilockerVerifyLicense,
              loading: _verifyingDl,
              onPressed:
                  _licenseController.text.trim().isNotEmpty &&
                      _dobController.text.trim().isNotEmpty &&
                      !_verifyingDl
                  ? _verifyDrivingLicense
                  : null,
            ),
          ],
        );
      default:
        return null;
    }
  }
}

String _docLabel(String key, AppLocalizations l10n) {
  return switch (key) {
    'aadhaar' => l10n.coreDigilockerDocAadhaar,
    'pan' => l10n.coreDigilockerDocPan,
    'drivingLicense' => l10n.coreDigilockerDocLicense,
    _ => key,
  };
}

IconData _docIcon(String key) {
  return switch (key) {
    'aadhaar' => AppIcons.fingerprint_rounded,
    'pan' => AppIcons.account_balance_rounded,
    'drivingLicense' => AppIcons.credit_card_rounded,
    _ => AppIcons.badge_outlined,
  };
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.docKey,
    required this.status,
    this.message,
    this.fallback,
  });

  final String docKey;
  final String status;
  final String? message;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_docIcon(docKey), size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _docLabel(docKey, l10n),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _DocBadge(status: status, message: message),
            ],
          ),
          if (fallback != null) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.divider),
            const SizedBox(height: 10),
            fallback!,
          ],
        ],
      ),
    );
  }
}

/// Web `Badge` component, same statuses and copy.
class _DocBadge extends StatelessWidget {
  const _DocBadge({required this.status, this.message});

  final String status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const base = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    switch (status.trim().toLowerCase()) {
      case 'loading':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 5),
            Text(
              l10n.coreDigilockerChecking,
              style: base.copyWith(color: AppColors.textTertiary),
            ),
          ],
        );
      case 'verified':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.verified_rounded,
              size: 14,
              color: AppColors.successText,
            ),
            const SizedBox(width: 5),
            Text(l10n.coreDigilockerVerified, style: base.copyWith(color: AppColors.successText)),
          ],
        );
      case 'missing':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.gpp_maybe_rounded,
              size: 14,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                message?.trim().isNotEmpty == true
                    ? message!.trim()
                    : l10n.coreDigilockerNotFound,
                style: base.copyWith(color: const Color(0xFFD97706)),
              ),
            ),
          ],
        );
      case 'failed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.error_outline_rounded,
              size: 14,
              color: AppColors.dangerText,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                message?.trim().isNotEmpty == true
                    ? message!.trim()
                    : l10n.coreDigilockerDidntMatch,
                style: base.copyWith(color: AppColors.dangerText),
              ),
            ),
          ],
        );
      case 'error':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.gpp_maybe_rounded,
              size: 14,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                message?.trim().isNotEmpty == true
                    ? message!.trim()
                    : l10n.coreDigilockerUnreachable,
                style: base.copyWith(color: const Color(0xFFD97706)),
              ),
            ),
          ],
        );
      default:
        return Text(
          l10n.coreDigilockerNotVerifiedYet,
          style: base.copyWith(color: AppColors.textTertiary),
        );
    }
  }
}

class _FallbackField extends StatelessWidget {
  const _FallbackField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FallbackVerifyButton extends StatelessWidget {
  const _FallbackVerifyButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _OptionalDetailsSection extends StatelessWidget {
  const _OptionalDetailsSection({
    required this.isDriver,
    required this.vehicleRegController,
    required this.vehicleInsuranceController,
    required this.gstController,
    required this.bankAccountController,
    required this.businessRegController,
    required this.onChanged,
  });

  final bool isDriver;
  final TextEditingController vehicleRegController;
  final TextEditingController vehicleInsuranceController;
  final TextEditingController gstController;
  final TextEditingController bankAccountController;
  final TextEditingController businessRegController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = isDriver
        ? [
            (vehicleRegController, l10n.coreDigilockerVehicleRegHint),
            (vehicleInsuranceController, l10n.coreDigilockerVehicleInsuranceHint),
          ]
        : [
            (gstController, l10n.coreDigilockerGstHint),
            (bankAccountController, l10n.coreDigilockerBankAccountHint),
            (businessRegController, l10n.coreDigilockerBusinessRegHint),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isDriver ? l10n.coreDigilockerVehicleDetails : l10n.coreDigilockerBusinessDetails,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          l10n.coreDigilockerOptionalNote,
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < fields.length; i++) ...[
          _FallbackField(
            controller: fields[i].$1,
            hintText: fields[i].$2,
            textCapitalization: TextCapitalization.characters,
            onChanged: onChanged,
          ),
          if (i != fields.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
