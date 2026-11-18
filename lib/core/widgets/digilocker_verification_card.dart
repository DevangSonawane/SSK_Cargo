import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/widgets/liquid_segmented_toggle.dart';
import '../kyc/digilocker_return.dart';
import '../kyc/digilocker_webview_screen.dart';
import '../network/api_client.dart';
import '../providers/kyc_status_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';
import 'package:gadidost/l10n/app_localizations.dart';
import 'package:gadidost/core/utils/user_facing_error.dart';

export '../kyc/digilocker_return.dart' show kDigilockerRedirectUrl;

/// Document keys, matching the backend's `verification_results` and the web
/// client's `REQUIRED` map (Onboarding.jsx).
const String kDigiDocAadhaar = 'aadhaar';
const String kDigiDocPan = 'pan';
const String kDigiDocDrivingLicense = 'drivingLicense';
const String kDigiDocGst = 'gst';

/// Per-document result status. Mirrors the web `docs` map values.
const String kDigiStatusIdle = 'idle';
const String kDigiStatusLoading = 'loading';
const String kDigiStatusVerified = 'verified';
const String kDigiStatusMissing = 'missing';
const String kDigiStatusFailed = 'failed';
const String kDigiStatusError = 'error';

/// Which side of the broker/client "Aadhaar + PAN" / "GST" toggle is active
/// (KYC guide Pt2: either path alone is enough). Drivers are always
/// [KycPath.identity].
enum KycPath { identity, gst }

/// Documents one DigiLocker session covers, per role (guide + web client).
List<String> digilockerRequiredDocs(String role) {
  if (role.trim().toLowerCase() == 'driver') {
    return const [kDigiDocAadhaar, kDigiDocPan, kDigiDocDrivingLicense];
  }
  return const [kDigiDocAadhaar, kDigiDocPan];
}

/// Every document key this role can verify — the DigiLocker set plus GST for
/// broker/client (the GST alternative path).
List<String> kycTrackedDocs(String role) {
  if (role.trim().toLowerCase() == 'driver') {
    return digilockerRequiredDocs(role);
  }
  return const [kDigiDocAadhaar, kDigiDocPan, kDigiDocGst];
}

/// Backend `isKycSatisfied`: driver needs Aadhaar + PAN + DL verified;
/// broker/client need (Aadhaar and PAN) verified, or GST verified alone.
bool isKycSatisfied(String role, Map<String, String> statuses) {
  bool ok(String key) => statuses[key] == kDigiStatusVerified;
  if (role.trim().toLowerCase() == 'driver') {
    return ok(kDigiDocAadhaar) && ok(kDigiDocPan) && ok(kDigiDocDrivingLicense);
  }
  return (ok(kDigiDocAadhaar) && ok(kDigiDocPan)) || ok(kDigiDocGst);
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
    final status = entry is Map ? entry['status']?.toString() : null;
    if (status != null && status.trim().isNotEmpty) {
      known[key] = status.trim().toLowerCase();
    }
  }
  return known;
}

/// Web `needsFallback` for a single status value: the photo upload shows
/// only for these.
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

/// Snapshot emitted to the hosting KYC screen whenever values, statuses or
/// the selected path change, so it can build the finish payload and the
/// Finish / Submit-for-review label without owning any of this flow's state.
class DigilockerVerificationSnapshot {
  const DigilockerVerificationSnapshot({
    required this.values,
    required this.statuses,
    this.path = KycPath.identity,
    this.satisfied = false,
  });

  /// Typed field values keyed like the backend documents map
  /// (`pan_number`, `license_number`, `date_of_birth`, `aadhaar_number`,
  /// `gst_number`, `vehicle_registration_number`, …).
  final Map<String, String> values;

  /// Per-document result status keyed by document (`aadhaar` / `pan` /
  /// `drivingLicense` / `gst`).
  final Map<String, String> statuses;

  /// Active toggle side (broker/client). Always identity for drivers.
  final KycPath path;

  /// [isKycSatisfied] for this role and [statuses].
  final bool satisfied;
}

/// KYC verification for every role (KYC guide Pt2):
///
/// * **broker / client** — a segmented "Aadhaar + PAN" / "GST" toggle; only
///   the active side renders and either side alone is enough.
///   * Aadhaar + PAN: "Verify with DigiLocker" (one consent session for
///     both), then manual paths — Aadhaar number → Send OTP → OTP → verify,
///     and PAN number → verify.
///   * GST: GSTIN → verify.
/// * **driver** — no toggle: DigiLocker, Aadhaar OTP, PAN, and Driving
///   License (number + date of birth).
///
/// Every field goes through a real verify-* call so the backend's
/// auto-verify can be reached. The DigiLocker `verificationId` is persisted
/// ([DigilockerSessionStore]) and re-checked whenever the app resumes, so
/// the result is never lost if Android kills the app mid-trip.
class DigilockerVerificationCard extends ConsumerStatefulWidget {
  const DigilockerVerificationCard({
    super.key,
    required this.role,
    required this.accessToken,
    this.userName = '',
    this.initialValues = const {},
    this.initialStatuses = const {},
    this.onChanged,
    this.onDigilockerDone,
  });

  /// `'driver'`, `'broker'` or `'client'`.
  final String role;
  final String accessToken;
  final String userName;
  final Map<String, String> initialValues;
  final Map<String, String> initialStatuses;
  final ValueChanged<DigilockerVerificationSnapshot>? onChanged;

  /// Fired after a DigiLocker session resolves or a manual check succeeds,
  /// once [onChanged] has reported the new statuses. `true` when the role's
  /// requirement ([isKycSatisfied]) is now met — the host may submit KYC
  /// straight away.
  final ValueChanged<bool>? onDigilockerDone;

  @override
  ConsumerState<DigilockerVerificationCard> createState() =>
      _DigilockerVerificationCardState();
}

class _DigilockerVerificationCardState
    extends ConsumerState<DigilockerVerificationCard>
    with WidgetsBindingObserver {
  late final List<String> _required;
  late final List<String> _tracked;
  final Map<String, String> _statuses = {};
  final Map<String, String?> _messages = {};
  KycPath _path = KycPath.identity;

  // The DigiLocker session as a whole: idle | loading | error, plus its id
  // so a still-pending one can be re-checked by hand (web `dg` state).
  String _sessionStatus = 'idle';
  String? _sessionMessage;
  String? _verificationId;
  int _pollToken = 0;

  bool _verifyingPan = false;
  bool _verifyingDl = false;
  bool _verifyingGst = false;
  bool _sendingAadhaarOtp = false;
  bool _verifyingAadhaarOtp = false;

  /// `refId` from `aadhaar/send-otp`; non-null while an OTP is outstanding.
  String? _aadhaarRefId;

  late final TextEditingController _aadhaarController;
  late final TextEditingController _aadhaarOtpController;
  late final TextEditingController _panController;
  late final TextEditingController _licenseController;
  late final TextEditingController _dobController;
  late final TextEditingController _vehicleRegController;
  late final TextEditingController _vehicleInsuranceController;
  late final TextEditingController _gstController;
  late final TextEditingController _bankAccountController;
  late final TextEditingController _businessRegController;

  String get _roleKey => widget.role.trim().toLowerCase();
  bool get _isDriver => _roleKey == 'driver';
  bool get _isBroker => _roleKey == 'broker';
  bool get _hasPathToggle => !_isDriver;

  /// True between opening DigiLocker and resolving the session: the user is
  /// (or was) away in the browser tab. Drives the resume / return-link check.
  bool _awaitingReturn = false;
  ProviderSubscription<DigilockerReturnEvent?>? _returnSub;

  String get _userId =>
      ref.read(authSessionProvider).valueOrNull?.user.id ?? '';

  @override
  void initState() {
    super.initState();
    _required = digilockerRequiredDocs(widget.role);
    _tracked = kycTrackedDocs(widget.role);
    for (final key in _tracked) {
      final initial = widget.initialStatuses[key]?.trim().toLowerCase();
      _statuses[key] = initial?.isNotEmpty == true ? initial! : 'idle';
    }
    String initial(String key) => widget.initialValues[key] ?? '';
    _aadhaarController = TextEditingController(text: initial('aadhaar_number'));
    _aadhaarOtpController = TextEditingController();
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
    // Resume on the GST side when that's the path already verified (or the
    // only one started).
    if (_hasPathToggle) {
      final identityVerified =
          _statuses[kDigiDocAadhaar] == kDigiStatusVerified &&
          _statuses[kDigiDocPan] == kDigiStatusVerified;
      final gstStarted =
          _statuses[kDigiDocGst] == kDigiStatusVerified ||
          (initial('gst_number').isNotEmpty &&
              initial('pan_number').isEmpty &&
              initial('aadhaar_number').isEmpty);
      if (!identityVerified && gstStarted) _path = KycPath.gst;
    }
    WidgetsBinding.instance.addObserver(this);
    // The App Link fired: DigiLocker is done on its side. Close the browser
    // tab (iOS; Android's Custom Tab is closed by the OS returning to us) and
    // resolve right away.
    _returnSub = ref.listenManual<DigilockerReturnEvent?>(
      digilockerReturnProvider,
      (previous, next) {
        if (next == null) return;
        _onReturnedFromDigilocker(next.verificationId);
      },
    );
    // Report the prefilled state so the host screen starts in sync, then pick
    // up any session left unresolved by an earlier run of the app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emit();
      _resumePendingSession();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the browser tab without the link firing (iOS Done button,
    // user switched apps, link not verified yet): check anyway.
    if (state == AppLifecycleState.resumed &&
        _awaitingReturn &&
        _verificationId != null &&
        _sessionStatus != 'loading') {
      _checkDigilocker(_verificationId!, 0);
    }
  }

  Future<void> _onReturnedFromDigilocker(String? linkVerificationId) async {
    if (!mounted) return;
    try {
      if (await supportsCloseForLaunchMode(LaunchMode.inAppBrowserView)) {
        await closeInAppWebView();
      }
    } catch (_) {}
    if (!mounted) return;
    final id = (linkVerificationId != null && linkVerificationId.isNotEmpty)
        ? linkVerificationId
        : _verificationId;
    if (id == null || id.isEmpty) return;
    await _checkDigilocker(id, 0);
  }

  Future<void> _resumePendingSession() async {
    if (_identityVerified || _verificationId != null) return;
    final pending = await DigilockerSessionStore.load(
      userId: _userId,
      role: widget.role,
    );
    if (!mounted || pending == null || _verificationId != null) return;
    _awaitingReturn = true;
    await _checkDigilocker(pending.verificationId, 0);
  }

  void _clearPending() {
    _awaitingReturn = false;
    DigilockerSessionStore.clear(userId: _userId, role: widget.role);
  }

  @override
  void dispose() {
    // Invalidate any in-flight poll chain.
    _pollToken++;
    WidgetsBinding.instance.removeObserver(this);
    _returnSub?.close();
    _aadhaarController.dispose();
    _aadhaarOtpController.dispose();
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
      'pan_number': _panController.text.trim().toUpperCase(),
      'license_number': _licenseController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
      'vehicle_registration_number': _vehicleRegController.text.trim(),
      'vehicle_insurance_number': _vehicleInsuranceController.text.trim(),
      'gst_number': _gstController.text.trim().toUpperCase(),
      'bank_account_number': _bankAccountController.text.trim(),
      'business_registration_number': _businessRegController.text.trim(),
    };
  }

  bool get _satisfied => isKycSatisfied(widget.role, _statuses);

  void _emit() {
    widget.onChanged?.call(
      DigilockerVerificationSnapshot(
        values: _currentValues(),
        statuses: Map<String, String>.of(_statuses),
        path: _path,
        satisfied: _satisfied,
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

  /// A manual check just succeeded: tell the host whether the requirement is
  /// now met so driver/broker can submit straight away.
  void _afterManualCheck(String key) {
    if (_statuses[key] == kDigiStatusVerified) {
      widget.onDigilockerDone?.call(_satisfied);
    }
  }

  void _setPath(KycPath path) {
    if (path == _path) return;
    FocusScope.of(context).unfocus();
    setState(() => _path = path);
    _emit();
  }

  bool _isVerified(String key) => _statuses[key] == kDigiStatusVerified;

  /// Every document the DigiLocker session covers for this role verified.
  bool get _identityVerified => _required.every(_isVerified);

  /// 503 from a verify-* call means the provider is down, not that the
  /// user's document is wrong (guide §7).
  String _verifyError(Object error) {
    if (error is ApiException && error.statusCode == 503) {
      return 'Verification is temporarily unavailable. Please try again shortly.';
    }
    return userFacingError(error);
  }

  // One DigiLocker sign-in covers every document this role needs (a browser
  // round trip, not inline entry): start → DigiLocker opens in an in-app
  // WebView → its redirect brings the user back (or the app resumes) →
  // status resolves it. The verification id is persisted so the result is
  // never lost.
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
      // Persist first: if Android kills the app while the user is in
      // DigiLocker, the next launch can still read the result.
      await DigilockerSessionStore.save(
        userId: _userId,
        role: widget.role,
        verificationId: verificationId,
      );
      if (!mounted) return;
      // In-app WebView: the app sees DigiLocker's redirect itself, so the
      // user comes straight back with no App Link / backend setup needed.
      // While it's open the app stays resumed, so the resume check is off.
      _awaitingReturn = false;
      setState(() => _verificationId = verificationId);
      final result = await DigilockerWebViewScreen.open(context, url);
      if (!mounted) return;
      _awaitingReturn = true;
      final id =
          (result.verificationId != null && result.verificationId!.isNotEmpty)
          ? result.verificationId!
          : verificationId;
      if (result.reachedRedirect) {
        await _checkDigilocker(id, 0);
      } else {
        // Closed early: one quick look in case they did finish; otherwise
        // this leaves the "Check status" retry in place.
        await _checkDigilocker(id, 4);
        if (mounted && _sessionStatus == 'error' && _verificationId != null) {
          setState(() => _sessionMessage = l10n.coreDigilockerAwaitingReturn);
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionStatus = 'error';
        _sessionMessage = _verifyError(error);
        _verificationId = null;
      });
    }
  }

  // 'pending' means the user hasn't finished in DigiLocker yet (or the
  // provider is still processing) — poll 4 × 3 s, then hand the retry to a
  // manual button rather than spinning forever. Web `checkDigilocker`.
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
      if (kDebugMode) {
        debugPrint('SSK.KYC status poll #$attempt → $status ($message)');
      }
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
        _clearPending();
        setState(() {
          _sessionStatus = 'error';
          _sessionMessage = (message != null && message.trim().isNotEmpty)
              ? message
              : l10n.coreDigilockerNotComplete;
          _verificationId = null;
        });
        return;
      }
      // Done: verified documents are settled; missing ones are left for the
      // manual checks below the DigiLocker button.
      _clearPending();
      final documents = data['documents'];
      final docsMap = documents is Map<String, dynamic> ? documents : const {};
      var resolvedAny = false;
      String? firstProblem;
      setState(() {
        for (final key in _required) {
          final entry = docsMap[key];
          if (entry is! Map<String, dynamic>) continue;
          final docStatus = entry['status']?.toString().trim().toLowerCase();
          final details = entry['details'];
          final detailMessage = details is Map<String, dynamic>
              ? details['message']?.toString()
              : null;
          if (docStatus == 'verified') {
            _statuses[key] = 'verified';
            _messages[key] = null;
            resolvedAny = true;
          } else if (docStatus == 'missing') {
            _statuses[key] = 'missing';
            _messages[key] = detailMessage;
            resolvedAny = true;
          } else if (docStatus != null && docStatus.isNotEmpty) {
            _statuses[key] = 'failed';
            _messages[key] =
                (detailMessage != null && detailMessage.trim().isNotEmpty)
                ? detailMessage
                : l10n.coreDigilockerNotComplete;
            firstProblem ??= _messages[key];
            resolvedAny = true;
          }
        }
        if (!resolvedAny) {
          _sessionStatus = 'error';
          _sessionMessage = (message != null && message.trim().isNotEmpty)
              ? message
              : l10n.coreDigilockerNotComplete;
        } else {
          _sessionStatus = firstProblem == null ? 'idle' : 'error';
          _sessionMessage = firstProblem;
        }
        _verificationId = null;
      });
      ref.invalidate(kycStatusProvider);
      _emit();
      widget.onDigilockerDone?.call(_satisfied);
    } catch (error) {
      if (!mounted || token != _pollToken) return;
      setState(() {
        _sessionStatus = 'error';
        _sessionMessage = _verifyError(error);
        _verificationId = verificationId;
      });
    }
  }

  // ── Manual checks (guide §2) ─────────────────────────────────────────

  Future<void> _sendAadhaarOtp() async {
    final aadhaar = _aadhaarController.text.replaceAll(' ', '').trim();
    if (_sendingAadhaarOtp) return;
    if (!RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
      _setDoc(kDigiDocAadhaar, 'error', 'Enter your 12-digit Aadhaar number.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sendingAadhaarOtp = true;
      _messages[kDigiDocAadhaar] = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .sendAadhaarOtp(
            accessToken: widget.accessToken,
            aadhaarNumber: aadhaar,
          );
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final refId = (data['refId'] ?? data['ref_id'])?.toString() ?? '';
      if (refId.isEmpty) {
        final details = data['details'];
        _setDoc(
          kDigiDocAadhaar,
          'failed',
          details is Map ? details['message']?.toString() : null,
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _aadhaarRefId = refId;
        _aadhaarOtpController.clear();
        _statuses[kDigiDocAadhaar] = 'idle';
        _messages[kDigiDocAadhaar] = null;
      });
    } catch (error) {
      _setDoc(kDigiDocAadhaar, 'error', _verifyError(error));
    } finally {
      if (mounted) setState(() => _sendingAadhaarOtp = false);
    }
  }

  Future<void> _verifyAadhaarOtp() async {
    final refId = _aadhaarRefId;
    final otp = _aadhaarOtpController.text.trim();
    if (refId == null || _verifyingAadhaarOtp) return;
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _setDoc(kDigiDocAadhaar, 'error', 'Enter the 6-digit OTP.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _verifyingAadhaarOtp = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .verifyAadhaarOtp(
            accessToken: widget.accessToken,
            refId: refId,
            otp: otp,
          );
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final details = data['details'];
      final status = data['status']?.toString().toLowerCase() ?? 'failed';
      if (status == kDigiStatusVerified && mounted) {
        setState(() => _aadhaarRefId = null);
      }
      _setDoc(
        kDigiDocAadhaar,
        status,
        details is Map ? details['message']?.toString() : null,
      );
      ref.invalidate(kycStatusProvider);
      _afterManualCheck(kDigiDocAadhaar);
    } catch (error) {
      _setDoc(kDigiDocAadhaar, 'error', _verifyError(error));
    } finally {
      if (mounted) setState(() => _verifyingAadhaarOtp = false);
    }
  }

  Future<void> _verifyPan() async {
    final pan = _panController.text.trim().toUpperCase();
    if (_verifyingPan) return;
    if (!RegExp(r'^[A-Z]{5}\d{4}[A-Z]$').hasMatch(pan)) {
      _setDoc(kDigiDocPan, 'error', 'Enter a valid 10-character PAN.');
      return;
    }
    FocusScope.of(context).unfocus();
    _setDoc(kDigiDocPan, 'loading', null);
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
        kDigiDocPan,
        data['status']?.toString().toLowerCase() ?? 'failed',
        details is Map ? details['message']?.toString() : null,
      );
      ref.invalidate(kycStatusProvider);
      _afterManualCheck(kDigiDocPan);
    } catch (error) {
      _setDoc(kDigiDocPan, 'error', _verifyError(error));
    } finally {
      if (mounted) setState(() => _verifyingPan = false);
    }
  }

  Future<void> _verifyGst() async {
    final gstin = _gstController.text.trim().toUpperCase();
    if (_verifyingGst) return;
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch(gstin)) {
      _setDoc(kDigiDocGst, 'error', 'Enter a valid 15-character GSTIN.');
      return;
    }
    FocusScope.of(context).unfocus();
    _setDoc(kDigiDocGst, 'loading', null);
    if (!mounted) return;
    setState(() => _verifyingGst = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .verifyGst(accessToken: widget.accessToken, gstin: gstin);
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final details = data['details'];
      _setDoc(
        kDigiDocGst,
        data['status']?.toString().toLowerCase() ?? 'failed',
        details is Map ? details['message']?.toString() : null,
      );
      ref.invalidate(kycStatusProvider);
      _afterManualCheck(kDigiDocGst);
    } catch (error) {
      _setDoc(kDigiDocGst, 'error', _verifyError(error));
    } finally {
      if (mounted) setState(() => _verifyingGst = false);
    }
  }

  Future<void> _verifyDrivingLicense() async {
    final dlNumber = _licenseController.text.trim();
    final dob = _dobController.text.trim();
    if (_verifyingDl) return;
    if (dlNumber.isEmpty || dob.isEmpty) {
      _setDoc(
        kDigiDocDrivingLicense,
        'error',
        'Enter your licence number and date of birth.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _setDoc(kDigiDocDrivingLicense, 'loading', null);
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
        kDigiDocDrivingLicense,
        data['status']?.toString().toLowerCase() ?? 'failed',
        details is Map ? details['message']?.toString() : null,
      );
      ref.invalidate(kycStatusProvider);
      _afterManualCheck(kDigiDocDrivingLicense);
    } catch (error) {
      _setDoc(kDigiDocDrivingLicense, 'error', _verifyError(error));
    } finally {
      if (mounted) setState(() => _verifyingDl = false);
    }
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final current = DateTime.tryParse(_dobController.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 90),
      lastDate: DateTime(now.year - 16, now.month, now.day),
    );
    if (picked == null || !mounted) return;
    _dobController.text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
    _emit();
  }

  // ── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showGst = _hasPathToggle && _path == KycPath.gst;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasPathToggle) ...[
          LiquidSegmentedToggle(
            labels: const ['Aadhaar + PAN', 'GST'],
            icons: const [AppIcons.fingerprint_rounded, AppIcons.receipt_long_rounded],
            selectedIndex: _path.index,
            activeColor: AppColors.brand,
            onChanged: (i) => _setPath(KycPath.values[i]),
          ),
          const SizedBox(height: 10),
          Text(
            showGst
                ? 'Verify your business GSTIN. GST alone is enough — no Aadhaar or PAN needed.'
                : 'Verify Aadhaar and PAN together. Use DigiLocker for one-tap verification, or verify each one below.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ] else
          Text(
            'Aadhaar, PAN and Driving Licence are all required. Use DigiLocker for one-tap verification, or verify each one below.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(showGst),
            child: showGst ? _gstSection() : _identitySection(),
          ),
        ),
        if (_isDriver || _isBroker) ...[
          const SizedBox(height: 16),
          _OptionalDetailsSection(
            isDriver: _isDriver,
            vehicleRegController: _vehicleRegController,
            vehicleInsuranceController: _vehicleInsuranceController,
            bankAccountController: _bankAccountController,
            businessRegController: _businessRegController,
            onChanged: (_) => _emit(),
          ),
        ],
      ],
    );
  }

  Widget _identitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_identityVerified) ...[
          _digilockerBlock(),
          const SizedBox(height: 14),
          const _OrDivider(label: 'or verify manually'),
          const SizedBox(height: 14),
        ],
        _DocumentRow(
          docKey: kDigiDocAadhaar,
          status: _statuses[kDigiDocAadhaar] ?? 'idle',
          message: _messages[kDigiDocAadhaar],
          fallback: _isVerified(kDigiDocAadhaar) ? null : _aadhaarManual(),
        ),
        const SizedBox(height: 10),
        _DocumentRow(
          docKey: kDigiDocPan,
          status: _statuses[kDigiDocPan] ?? 'idle',
          message: _messages[kDigiDocPan],
          fallback: _isVerified(kDigiDocPan) ? null : _panManual(),
        ),
        if (_isDriver) ...[
          const SizedBox(height: 10),
          _DocumentRow(
            docKey: kDigiDocDrivingLicense,
            status: _statuses[kDigiDocDrivingLicense] ?? 'idle',
            message: _messages[kDigiDocDrivingLicense],
            fallback: _isVerified(kDigiDocDrivingLicense)
                ? null
                : _licenseManual(),
          ),
        ],
      ],
    );
  }

  Widget _gstSection() {
    return _DocumentRow(
      docKey: kDigiDocGst,
      status: _statuses[kDigiDocGst] ?? 'idle',
      message: _messages[kDigiDocGst],
      fallback: _isVerified(kDigiDocGst)
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FallbackField(
                  controller: _gstController,
                  hintText: '27ABCDE1234F1Z5',
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  onChanged: (_) {
                    setState(() {});
                    _emit();
                  },
                ),
                const SizedBox(height: 8),
                _FallbackVerifyButton(
                  label: 'Verify GST',
                  loading: _verifyingGst,
                  onPressed: _gstController.text.trim().isNotEmpty
                      ? _verifyGst
                      : null,
                ),
              ],
            ),
    );
  }

  Widget _digilockerBlock() {
    final l10n = AppLocalizations.of(context)!;
    final loading = _sessionStatus == 'loading';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: loading ? null : _startDigilocker,
            icon: loading
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
              loading
                  ? l10n.coreDigilockerWorking
                  : 'Open with DigiLocker',
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
        const SizedBox(height: 6),
        Text(
          _isDriver
              ? 'Fetches Aadhaar, PAN and Driving Licence in one go.'
              : 'Fetches Aadhaar and PAN in one go.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
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
                    style: const TextStyle(
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
    );
  }

  Widget _aadhaarManual() {
    final otpSent = _aadhaarRefId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _FallbackField(
                controller: _aadhaarController,
                hintText: 'Aadhaar number',
                keyboardType: TextInputType.number,
                enabled: !otpSent,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                onChanged: (_) {
                  setState(() {});
                  _emit();
                },
              ),
            ),
            const SizedBox(width: 8),
            _FallbackVerifyButton(
              label: otpSent ? 'Resend' : 'Send OTP',
              loading: _sendingAadhaarOtp,
              onPressed:
                  _aadhaarController.text.replaceAll(' ', '').length == 12
                  ? _sendAadhaarOtp
                  : null,
            ),
          ],
        ),
        if (otpSent) ...[
          const SizedBox(height: 8),
          Text(
            'Enter the OTP sent to the mobile number linked with this Aadhaar.',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _FallbackField(
                  controller: _aadhaarOtpController,
                  hintText: '6-digit OTP',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              _FallbackVerifyButton(
                label: 'Verify OTP',
                loading: _verifyingAadhaarOtp,
                onPressed: _aadhaarOtpController.text.length == 6
                    ? _verifyAadhaarOtp
                    : null,
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _verifyingAadhaarOtp
                  ? null
                  : () => setState(() {
                      _aadhaarRefId = null;
                      _aadhaarOtpController.clear();
                    }),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Change Aadhaar number'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _panManual() {
    return Row(
      children: [
        Expanded(
          child: _FallbackField(
            controller: _panController,
            hintText: 'ABCDE1234F',
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) {
              setState(() {});
              _emit();
            },
          ),
        ),
        const SizedBox(width: 8),
        _FallbackVerifyButton(
          label: 'Verify',
          loading: _verifyingPan,
          onPressed: _panController.text.trim().length == 10
              ? _verifyPan
              : null,
        ),
      ],
    );
  }

  Widget _licenseManual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FallbackField(
          controller: _licenseController,
          hintText: 'Licence number, e.g. MH1220190012345',
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) {
            setState(() {});
            _emit();
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: _FallbackField(
                    controller: _dobController,
                    hintText: 'Date of birth (YYYY-MM-DD)',
                    keyboardType: TextInputType.datetime,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _FallbackVerifyButton(
              label: 'Verify',
              loading: _verifyingDl,
              onPressed:
                  _licenseController.text.trim().isNotEmpty &&
                      _dobController.text.trim().isNotEmpty
                  ? _verifyDrivingLicense
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      ],
    );
  }
}

String _docLabel(String key, AppLocalizations l10n) {
  return switch (key) {
    'aadhaar' => l10n.coreDigilockerDocAadhaar,
    'pan' => l10n.coreDigilockerDocPan,
    'drivingLicense' => l10n.coreDigilockerDocLicense,
    'gst' => 'GSTIN',
    _ => key,
  };
}

IconData _docIcon(String key) {
  return switch (key) {
    'aadhaar' => AppIcons.fingerprint_rounded,
    'pan' => AppIcons.account_balance_rounded,
    'drivingLicense' => AppIcons.credit_card_rounded,
    'gst' => AppIcons.receipt_long_rounded,
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
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
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
        fillColor: enabled ? Colors.white : AppColors.fillSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
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
    required this.bankAccountController,
    required this.businessRegController,
    required this.onChanged,
  });

  final bool isDriver;
  final TextEditingController vehicleRegController;
  final TextEditingController vehicleInsuranceController;
  final TextEditingController bankAccountController;
  final TextEditingController businessRegController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = isDriver
        ? [
            (vehicleRegController, l10n.coreDigilockerVehicleRegHint),
            (
              vehicleInsuranceController,
              l10n.coreDigilockerVehicleInsuranceHint,
            ),
          ]
        : [
            (bankAccountController, l10n.coreDigilockerBankAccountHint),
            (businessRegController, l10n.coreDigilockerBusinessRegHint),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isDriver
              ? l10n.coreDigilockerVehicleDetails
              : l10n.coreDigilockerBusinessDetails,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          // Broker: bank account + business registration are required on
          // either path (`POST /api/kyc/broker`).
          isDriver
              ? l10n.coreDigilockerOptionalNote
              : 'Required to submit your KYC, whichever option you verify with.',
          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
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
