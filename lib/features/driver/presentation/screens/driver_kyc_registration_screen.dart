import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/kyc_status_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/digilocker_verification_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

enum _KycStep { details, documents, review, submitted }

class DriverKycRegistrationScreen extends ConsumerStatefulWidget {
  const DriverKycRegistrationScreen({super.key});

  @override
  ConsumerState<DriverKycRegistrationScreen> createState() =>
      _DriverKycRegistrationScreenState();
}

class _DriverKycRegistrationScreenState
    extends ConsumerState<DriverKycRegistrationScreen> {
  final _confirmCheckboxController = ValueNotifier<bool>(false);
  final _picker = ImagePicker();

  final _panController = TextEditingController();
  final _dobController = TextEditingController();
  final _licenseController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _vehicleRegController = TextEditingController();
  final _vehicleInsuranceController = TextEditingController();

  Timer? _refreshTimer;

  _KycStep _step = _KycStep.details;
  bool _initialLoading = true;
  bool _saving = false;
  String? _errorMessage;
  String? _statusLabel;
  String? _rejectionReason;
  DateTime? _submittedAt;
  DateTime? _reviewedAt;
  String? _submissionId;
  bool _hasSubmission = false;
  // Live DigiLocker state, mirrored out of DigilockerVerificationCard: typed
  // fallback numbers + per-document result statuses. Drives the finish
  // payload, the Finish / Submit-for-review label, and whether the photo
  // uploads (manual-review fallback only) are shown at all.
  Map<String, String> _digiValues = {};
  Map<String, String> _digiStatuses = {};
  final Map<String, _KycAttachment> _attachments = {
    for (final doc in _kycDocuments) doc.key: const _KycAttachment(),
  };

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_step == _KycStep.submitted) {
        _loadKycStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _confirmCheckboxController.dispose();
    _panController.dispose();
    _dobController.dispose();
    _licenseController.dispose();
    _aadhaarController.dispose();
    _vehicleRegController.dispose();
    _vehicleInsuranceController.dispose();
    super.dispose();
  }

  static const _kycDocuments = <_KycDocument>[
    _KycDocument(
      key: 'pan_photo_url',
      title: 'PAN Card',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
    _KycDocument(
      key: 'license_photo_url',
      title: 'Driving License',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
    _KycDocument(
      key: 'aadhaar_photo_url',
      title: 'Aadhaar Card',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
  ];

  bool _isApprovedStatus(String status) {
    return status.contains('verified') ||
        status.contains('approved') ||
        status.contains('complete');
  }

  bool _isRejectedStatus(String status) {
    return status.contains('reject') || status.contains('declin');
  }

  /// Web `allVerified`: every required document verified through DigiLocker
  /// or a fallback number check.
  bool get _digiAllVerified => digilockerRequiredDocs(
    'driver',
  ).every((key) => _digiStatuses[key] == 'verified');

  /// Web `needsFallback` (any): photo uploads are only useful for the
  /// manual-review fallback, so the uploads card stays hidden until a
  /// document actually needs it.
  bool get _digiNeedsFallback => digilockerRequiredDocs('driver').any(
    (key) => const {
      'missing',
      'failed',
      'error',
      'loading',
    }.contains(_digiStatuses[key]),
  );

  void _onDigiChanged(DigilockerVerificationSnapshot snapshot) {
    _digiValues = snapshot.values;
    _digiStatuses = snapshot.statuses;
    // Mirror typed values into the inline controllers (same no-loop note as
    // the broker screen) so review/submitted cards show live values.
    _setControllerText(_panController, snapshot.values['pan_number']);
    _setControllerText(_dobController, snapshot.values['date_of_birth']);
    _setControllerText(_licenseController, snapshot.values['license_number']);
    _setControllerText(_aadhaarController, snapshot.values['aadhaar_number']);
    _setControllerText(
      _vehicleRegController,
      snapshot.values['vehicle_registration_number'],
    );
    _setControllerText(
      _vehicleInsuranceController,
      snapshot.values['vehicle_insurance_number'],
    );
    if (mounted) setState(() {});
  }

  void _setControllerText(TextEditingController controller, String? value) {
    if (value == null) return;
    if (controller.text != value) {
      controller.text = value;
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _prefillControllers(Map<String, String> documents) {
    _panController.text = documents['pan_number'] ?? _panController.text;
    _dobController.text = documents['date_of_birth'] ?? _dobController.text;
    _licenseController.text =
        documents['license_number'] ?? _licenseController.text;
    _aadhaarController.text =
        documents['aadhaar_number'] ?? _aadhaarController.text;
    _vehicleRegController.text =
        documents['vehicle_registration_number'] ?? _vehicleRegController.text;
    _vehicleInsuranceController.text =
        documents['vehicle_insurance_number'] ??
        _vehicleInsuranceController.text;
  }

  Map<String, dynamic> _documentsPayload() {
    final payload = <String, dynamic>{
      'license_number': _licenseController.text.trim(),
      'pan_number': _panController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
      'aadhaar_number': _aadhaarController.text.replaceAll(' ', '').trim(),
      'vehicle_registration_number': _vehicleRegController.text.trim(),
      'vehicle_insurance_number': _vehicleInsuranceController.text.trim(),
    };

    // DigiLocker-card values win over the (now secondary) inline fields, and
    // — web parity — only non-empty numbers are sent: verified documents
    // need no number at all, unverified ones 422 without it.
    _digiValues.forEach((key, value) {
      final text = value.trim();
      if (text.isEmpty) {
        payload.remove(key);
      } else {
        payload[key] = key == 'aadhaar_number'
            ? text.replaceAll(' ', '')
            : text;
      }
    });
    payload.removeWhere(
      (key, value) => value is String && value.trim().isEmpty,
    );

    final panAttachment = _attachments['pan_photo_url'];
    final licenseAttachment = _attachments['license_photo_url'];
    final aadhaarAttachment = _attachments['aadhaar_photo_url'];
    if (panAttachment?.url != null && panAttachment!.url!.isNotEmpty) {
      payload['pan_photo_url'] = panAttachment.url;
    }
    if (licenseAttachment?.url != null && licenseAttachment!.url!.isNotEmpty) {
      payload['license_photo_url'] = licenseAttachment.url;
    }
    if (aadhaarAttachment?.url != null && aadhaarAttachment!.url!.isNotEmpty) {
      payload['aadhaar_photo_url'] = aadhaarAttachment.url;
    }

    return payload;
  }

  Map<String, String> _documentsFromMap(Map<String, dynamic>? input) {
    if (input == null) {
      return const {};
    }
    return input.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  void _applyUploadedDocumentsFromSubmission(Map<String, String> documents) {
    final panUrl = documents['pan_photo_url'];
    if (panUrl != null && panUrl.isNotEmpty) {
      _attachments['pan_photo_url'] = _KycAttachment(
        fileName: 'PAN Card',
        sourceLabel: 'Submitted URL',
        url: panUrl,
      );
    }

    final licenseUrl = documents['license_photo_url'];
    if (licenseUrl != null && licenseUrl.isNotEmpty) {
      _attachments['license_photo_url'] = _KycAttachment(
        fileName: 'Driving License',
        sourceLabel: 'Submitted URL',
        url: licenseUrl,
      );
    }

    final aadhaarUrl = documents['aadhaar_photo_url'];
    if (aadhaarUrl != null && aadhaarUrl.isNotEmpty) {
      _attachments['aadhaar_photo_url'] = _KycAttachment(
        fileName: 'Aadhaar Card',
        sourceLabel: 'Submitted URL',
        url: aadhaarUrl,
      );
    }
  }

  void _resetAttachments() {
    for (final doc in _kycDocuments) {
      _attachments[doc.key] = const _KycAttachment();
    }
  }

  void _goBack() {
    if (_step == _KycStep.documents) {
      setState(() => _step = _KycStep.details);
      return;
    }
    if (_step == _KycStep.review) {
      setState(() => _step = _KycStep.documents);
      return;
    }
    if (_step == _KycStep.submitted) {
      context.pop();
      return;
    }
    context.pop();
  }

  Future<void> _loadKycStatus({bool silent = false}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) {
        setState(() {
          _initialLoading = false;
          _errorMessage = 'No active session found.';
        });
      }
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getKycStatus(accessToken: session.tokens.accessToken);
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final submission = data['submission'] as Map<String, dynamic>?;
      final documents = _documentsFromMap(
        submission?['documents'] as Map<String, dynamic>?,
      );
      final hasSubmission = submission != null && submission.isNotEmpty;
      final status = data['kyc_status']?.toString();

      if (mounted) {
        setState(() {
          _hasSubmission = hasSubmission;
          _statusLabel = status;
          _submissionId = submission?['id']?.toString();
          _rejectionReason = submission?['rejection_reason']?.toString();
          _submittedAt = DateTime.tryParse(
            submission?['submitted_at']?.toString() ?? '',
          );
          _reviewedAt = DateTime.tryParse(
            submission?['reviewed_at']?.toString() ?? '',
          );
          _resetAttachments();

          if (hasSubmission && documents.isNotEmpty) {
            _prefillControllers(documents);
          }
          _applyUploadedDocumentsFromSubmission(documents);

          // Prefill already-verified rows so the card shows them instead of
          // asking again (web prefill effect). Only on first load — never
          // clobber a session the user already interacted with.
          if (_digiStatuses.isEmpty) {
            _digiStatuses = parseVerificationStatuses(
              submission?['verification_results'] as Map<String, dynamic>?,
              digilockerRequiredDocs('driver'),
            );
          }

          if (!_hasSubmission) {
            _step = _KycStep.details;
          } else if (status != null && _isRejectedStatus(status)) {
            _step = _KycStep.details;
          } else {
            _step = _KycStep.submitted;
          }

          _errorMessage = null;
          _initialLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        if (!silent) {
          _errorMessage = error is ApiException
              ? error.message
              : error.toString();
        }
      });
    }
  }

  Future<void> _submitKyc() async {
    if (!(_confirmCheckboxController.value)) {
      setState(() {
        _step = _KycStep.review;
        _errorMessage = 'Please confirm that all information is accurate.';
      });
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.driverKycSignInToSubmit),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .submitDriverKyc(
            accessToken: session.tokens.accessToken,
            documents: _documentsPayload(),
          );
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      _hasSubmission = true;
      _submittedAt = DateTime.now();
      _statusLabel = data['kyc_status']?.toString() ?? 'submitted';
      _rejectionReason = null;
      _step = _KycStep.submitted;
      ref.invalidate(kycStatusProvider);
      await _loadKycStatus(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _statusLabel == 'verified'
                  ? "You're verified - full access unlocked."
                  : 'KYC submitted for review.',
            ),
            backgroundColor: AppColors.brand,
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDocument(_KycDocument document, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return;

      final session = ref.read(authSessionProvider).valueOrNull;
      if (session == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.driverKycSignInToUpload,
            ),
            backgroundColor: AppColors.dangerIcon,
          ),
        );
        return;
      }

      final dio = ref.read(dioProvider);
      final filename = picked.path.split(RegExp(r'[\\/]+')).last;
      final response = await dio.post<Map<String, dynamic>>(
        '/api/kyc/documents/upload',
        data: FormData.fromMap({
          'file': MultipartFile.fromFileSync(picked.path, filename: filename),
          'document_key': document.key,
        }),
        options: Options(
          headers: {'Authorization': 'Bearer ${session.tokens.accessToken}'},
        ),
      );
      final data =
          (response.data?['data'] as Map<String, dynamic>?) ?? const {};
      final uploadedDocument =
          (data['document'] as Map<String, dynamic>?) ?? const {};
      final uploadedName = uploadedDocument['filename']?.toString();
      final uploadedUrl = uploadedDocument['url']?.toString();
      if (!mounted) return;
      setState(() {
        _attachments[document.key] = _KycAttachment(
          fileName: uploadedName != null && uploadedName.isNotEmpty
              ? uploadedName
              : picked.name,
          sourceLabel: source == ImageSource.camera ? 'Camera' : 'Gallery',
          path: picked.path,
          url: uploadedUrl,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.driverKycPickFailed),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    }
  }

  void _showUploadOptions(_KycDocument document) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _driverKycDocumentTitle(l10n, document),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.driverKycChooseHowYouWantToUploadThisDocument,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SheetAction(
                      icon: AppIcons.photo_camera_rounded,
                      label: l10n.driverKycCamera,
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickDocument(document, ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 10),
                    _SheetAction(
                      icon: AppIcons.photo_library_rounded,
                      label: l10n.driverKycGallery,
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickDocument(document, ImageSource.gallery);
                      },
                    ),
                    const SizedBox(height: 10),
                    _SheetAction(
                      icon: AppIcons.close_rounded,
                      label: l10n.driverKycCancel,
                      onTap: () => Navigator.of(context).pop(),
                      muted: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentPreview(String key) {
    final attachment = _attachments[key];
    if (attachment == null || !attachment.isUploaded) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          AppIcons.document_scanner_rounded,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.driverKycDocumentPreview,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.brandTint,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              AppIcons.insert_drive_file_rounded,
                              color: AppColors.brand,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment.fileName ??
                                      l10n.driverKycUploadedFile,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  attachment.sourceLabel ??
                                      l10n.driverKycUpload,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.driverKycClose,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildStepper() {
    final l10n = AppLocalizations.of(context)!;
    final stepLabels = <String>[
      l10n.driverKycStepDetails,
      l10n.driverKycStepDocuments,
      l10n.driverKycStepReview,
      l10n.driverKycStepSubmit,
    ];
    final activeIndex = switch (_step) {
      _KycStep.details => 0,
      _KycStep.documents => 1,
      _KycStep.review => 2,
      _KycStep.submitted => 3,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final stepWidth = constraints.maxWidth / stepLabels.length;
        final lineInset = stepWidth / 2;

        return SizedBox(
          height: 92,
          child: Stack(
            children: [
              Positioned(
                left: lineInset,
                right: lineInset,
                top: 22,
                child: Row(
                  children: [
                    for (var i = 0; i < stepLabels.length - 1; i++) ...[
                      Expanded(
                        child: Container(
                          height: 2,
                          color: activeIndex > i
                              ? AppColors.brand
                              : AppColors.line,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < stepLabels.length; i++) ...[
                    Expanded(
                      child: _StepperItem(
                        label: stepLabels[i],
                        index: i,
                        activeIndex: activeIndex,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentsStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Upload Documents',
          subtitle: 'Upload clear photos of the following documents.',
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _kycDocuments.length; i++) ...[
          _KycUploadCard(
            document: _kycDocuments[i],
            attachment:
                _attachments[_kycDocuments[i].key] ?? const _KycAttachment(),
            onUpload: () => _showUploadOptions(_kycDocuments[i]),
            onCamera: () => _pickDocument(_kycDocuments[i], ImageSource.camera),
            onGallery: () =>
                _pickDocument(_kycDocuments[i], ImageSource.gallery),
            onView: () => _showAttachmentPreview(_kycDocuments[i].key),
            onReplace: () => _showUploadOptions(_kycDocuments[i]),
          ),
          if (i != _kycDocuments.length - 1) const SizedBox(height: 12),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 14),
          _WarningCard(message: _errorMessage!),
        ],
      ],
    );
  }

  Widget _buildReviewStep(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uploadedItems = _kycDocuments
        .map(
          (doc) =>
              MapEntry(doc, _attachments[doc.key] ?? const _KycAttachment()),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: l10n.driverKycReviewYourInformation,
          subtitle: l10n.driverKycPleaseVerifyEverythingBeforeSubmitting,
        ),
        const SizedBox(height: 16),
        _CardSection(
          title: l10n.driverKycDriverInformation,
          child: Column(
            children: [
              _ReviewFieldRow(
                label: l10n.driverKycPANNumber,
                value: _panController.text.trim().isEmpty
                    ? l10n.driverKycNotProvided
                    : _panController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: l10n.driverKycDateOfBirth,
                value: _dobController.text.trim().isEmpty
                    ? l10n.driverKycNotProvided
                    : _dobController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: l10n.driverKycLicenseNumber,
                value: _licenseController.text.trim().isEmpty
                    ? l10n.driverKycNotProvided
                    : _licenseController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: l10n.driverKycAadhaarNumber,
                value: _aadhaarController.text.trim().isEmpty
                    ? l10n.driverKycNotProvided
                    : _aadhaarController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: l10n.driverKycVehicleRegistrationNumber,
                value: _vehicleRegController.text.trim().isEmpty
                    ? l10n.driverKycNotProvided
                    : _vehicleRegController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: l10n.driverKycVehicleInsuranceNumber,
                value: _vehicleInsuranceController.text.trim().isEmpty
                    ? l10n.driverKycNotProvided
                    : _vehicleInsuranceController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CardSection(
          title: l10n.driverKycUploadedDocuments,
          child: Column(
            children: [
              for (var i = 0; i < uploadedItems.length; i++) ...[
                _ReviewDocumentRow(
                  document: uploadedItems[i].key,
                  title: _driverKycDocumentTitle(l10n, uploadedItems[i].key),
                  attachment: uploadedItems[i].value,
                  onView: () =>
                      _showAttachmentPreview(uploadedItems[i].key.key),
                  onReplace: () => _showUploadOptions(uploadedItems[i].key),
                ),
                if (i != uploadedItems.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _WarningCard(
          message:
              'Please verify all information carefully. Incorrect information may delay KYC approval.',
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<bool>(
          valueListenable: _confirmCheckboxController,
          builder: (context, checked, _) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: checked,
              activeColor: AppColors.brand,
              onChanged: (value) {
                _confirmCheckboxController.value = value ?? false;
                setState(() {});
              },
              title: Text(
                'I confirm that all the information provided is accurate.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmittedStep(BuildContext context) {
    final isApproved =
        _statusLabel != null && _isApprovedStatus(_statusLabel!.toLowerCase());
    final title = isApproved
        ? 'KYC Verification Complete'
        : 'KYC Submitted Successfully';
    final badgeLabel = isApproved ? 'VERIFIED' : 'SUBMITTED';
    final description = isApproved
        ? 'Your KYC has been verified. Your driver account is now active.'
        : 'Your KYC has been successfully submitted. Our verification team will review your documents. This usually takes 24-48 hours.';
    final currentStatus = isApproved ? 'Verified' : 'Pending Review';
    final statusColor = isApproved ? AppColors.brand : AppColors.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 34, 20, 34),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: isApproved ? AppColors.brandTint : AppColors.brandTint,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: isApproved ? AppColors.brandBright : AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isApproved
                        ? AppIcons.check_rounded
                        : AppIcons.hourglass_top_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 38,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isApproved ? AppColors.brandBright : AppColors.brand,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textHeading,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _KycIconBadge(
                    icon: AppIcons.assignment_outlined,
                    color: AppColors.brand,
                    background: AppColors.brandTint,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    AppLocalizations.of(context)!.driverKycVerificationDetails,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textHeading,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _verificationInfoRow(
                icon: AppIcons.verified_rounded,
                iconColor: AppColors.brandBright,
                iconBackground: AppColors.brandTint,
                label: AppLocalizations.of(context)!.driverKycCurrentStatus,
                value: currentStatus,
                valueColor: statusColor,
                valueBadge: isApproved,
              ),
              _verificationInfoRow(
                icon: AppIcons.calendar_month_outlined,
                iconColor: AppColors.brand,
                iconBackground: AppColors.brandTint,
                label: AppLocalizations.of(context)!.driverKycSubmittedDate,
                value: _submittedAt != null
                    ? _formatDateTime(_submittedAt!)
                    : AppLocalizations.of(context)!.driverKycNotAvailable,
              ),
              _verificationInfoRow(
                icon: AppIcons.badge_outlined,
                iconColor: AppColors.brand,
                iconBackground: AppColors.brandTint,
                label: AppLocalizations.of(context)!.driverKycSubmissionID,
                value:
                    _submissionId ??
                    AppLocalizations.of(context)!.driverKycNotAvailable,
              ),
              if (_reviewedAt != null)
                _verificationInfoRow(
                  icon: AppIcons.schedule_outlined,
                  iconColor: AppColors.warningText,
                  iconBackground: AppColors.warningFill,
                  label: AppLocalizations.of(context)!.driverKycReviewedAt,
                  value: _formatDateTime(_reviewedAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _goBack,
          icon: const Icon(AppIcons.arrow_back_rounded, size: 23),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.brand,
            minimumSize: const Size.fromHeight(60),
            side: const BorderSide(color: AppColors.brand, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          label: const Expanded(
            child: Text(
              'Go Back',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _verificationInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBadge = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          _KycIconBadge(
            icon: icon,
            color: iconColor,
            background: iconBackground,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: valueBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            color: valueColor ?? AppColors.brandBright,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          AppIcons.check_rounded,
                          color: valueColor ?? AppColors.brandBright,
                          size: 18,
                        ),
                      ],
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? AppColors.textHeading,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _bottomBar(BuildContext context) {
    if (_step == _KycStep.submitted) {
      return const SizedBox.shrink();
    }

    final label = _step == _KycStep.review ? 'Submit KYC' : 'Continue';
    final action = _step == _KycStep.details
        ? () {
            setState(() {
              _errorMessage = null;
              _step = _KycStep.documents;
            });
          }
        : _step == _KycStep.documents
        ? () {
            setState(() {
              _errorMessage = null;
              _step = _KycStep.review;
            });
          }
        : _submitKyc;

    return SafeArea(
      top: false,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
        ),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _saving ? null : action,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _stepBody(BuildContext context) {
    // Legacy wizard shell (superseded by _buildReactStyleContent below): the
    // old details step no longer exists — verification lives in the
    // DigiLocker card — so its arm points at the documents step.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (_step) {
        _KycStep.details => _buildDocumentsStep(context),
        _KycStep.documents => _buildDocumentsStep(context),
        _KycStep.review => _buildReviewStep(context),
        _KycStep.submitted => _buildSubmittedStep(context),
      },
    );
  }

  Widget _buildReactStyleContent(BuildContext context) {
    final status = (_statusLabel ?? 'pending').trim().toLowerCase();
    final showForm =
        !_hasSubmission ||
        _isRejectedStatus(status) ||
        _step != _KycStep.submitted;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        _KycStatusSummaryCard(
          status: status,
          rejectionReason: _rejectionReason,
        ),
        if (showForm) ...[
          const SizedBox(height: 16),
          _CardSection(
            title: 'Verify Your Identity',
            child: Builder(
              builder: (context) {
                final session = ref.watch(authSessionProvider).valueOrNull;
                return DigilockerVerificationCard(
                  role: 'driver',
                  accessToken: session?.tokens.accessToken ?? '',
                  userName: session?.user.name ?? '',
                  initialValues: {
                    'pan_number': _panController.text,
                    'date_of_birth': _dobController.text,
                    'license_number': _licenseController.text,
                    'aadhaar_number': _aadhaarController.text,
                    'vehicle_registration_number': _vehicleRegController.text,
                    'vehicle_insurance_number':
                        _vehicleInsuranceController.text,
                  },
                  initialStatuses: _digiStatuses,
                  onChanged: _onDigiChanged,
                );
              },
            ),
          ),
          if (_digiNeedsFallback) ...[
            const SizedBox(height: 16),
            _CardSection(
              title: 'Upload Documents',
              child: Builder(
                builder: (context) {
                  // Web parity: only the documents DigiLocker couldn't
                  // confirm show a photo card — verified ones never show a
                  // "Not uploaded" row.
                  final fallbackDocs = _kycDocuments
                      .where((doc) {
                        final key = digiDocKeyForUploadKey(doc.key);
                        return key != null &&
                            digiNeedsFallback(_digiStatuses[key]);
                      })
                      .toList(growable: false);
                  return Column(
                    children: [
                      for (var i = 0; i < fallbackDocs.length; i++) ...[
                        _KycUploadCard(
                          document: fallbackDocs[i],
                          attachment:
                              _attachments[fallbackDocs[i].key] ??
                              const _KycAttachment(),
                          onUpload: () => _showUploadOptions(fallbackDocs[i]),
                          onCamera: () => _pickDocument(
                            fallbackDocs[i],
                            ImageSource.camera,
                          ),
                          onGallery: () => _pickDocument(
                            fallbackDocs[i],
                            ImageSource.gallery,
                          ),
                          onView: () =>
                              _showAttachmentPreview(fallbackDocs[i].key),
                          onReplace: () => _showUploadOptions(fallbackDocs[i]),
                        ),
                        if (i != fallbackDocs.length - 1)
                          const SizedBox(height: 12),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        _WarningCard(message: _errorMessage!),
                      ],
                    ],
                  );
                },
              ),
            ),
          ] else if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _WarningCard(message: _errorMessage!),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _saving
                  ? null
                  : () {
                      _confirmCheckboxController.value = true;
                      _submitKyc();
                    },
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(AppIcons.file_upload_outlined, size: 18),
              label: Text(
                _digiAllVerified
                    ? 'Finish'
                    : (_isRejectedStatus(status)
                          ? 'Resubmit for Review'
                          : 'Submit for Review'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              // Web parity: the summary lists only documents that went
              // through the manual-review fallback — verified ones never
              // show a "Not uploaded" row.
              final submittedDocs = _kycDocuments
                  .where((doc) {
                    final key = digiDocKeyForUploadKey(doc.key);
                    return key != null && digiNeedsFallback(_digiStatuses[key]);
                  })
                  .toList(growable: false);
              return _SubmittedDocumentsCard(
                licenseNumber: _licenseController.text.trim(),
                aadhaarNumber: _aadhaarController.text.trim(),
                vehicleRegistration: _vehicleRegController.text.trim(),
                insuranceNumber: _vehicleInsuranceController.text.trim(),
                documents: submittedDocs,
                attachments: _attachments,
                onEdit: () => setState(() => _step = _KycStep.details),
                onView: _showAttachmentPreview,
              );
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillSubtle,
      appBar: AppBar(
        backgroundColor: AppColors.fillSubtle,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        leadingWidth: 72,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                AppIcons.chevron_left_rounded,
                color: AppColors.brand,
                size: 30,
              ),
            ),
          ),
        ),
        title: Text(
          'Driver KYC',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textHeading,
          ),
        ),
      ),
      body: SafeArea(
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildReactStyleContent(context),
      ),
    );
  }
}

class _KycIconBadge extends StatelessWidget {
  const _KycIconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _KycStatusSummaryCard extends StatelessWidget {
  const _KycStatusSummaryCard({
    required this.status,
    required this.rejectionReason,
  });

  final String status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visuals = _kycStatusVisuals(status, l10n);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: visuals.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visuals.icon, color: visuals.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visuals.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visuals.subtitle,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: visuals.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: visuals.color.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  visuals.badge,
                  style: TextStyle(
                    color: visuals.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (rejectionReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            _WarningCard(message: rejectionReason!.trim()),
          ],
        ],
      ),
    );
  }
}

class _SubmittedDocumentsCard extends StatelessWidget {
  const _SubmittedDocumentsCard({
    required this.licenseNumber,
    required this.aadhaarNumber,
    required this.vehicleRegistration,
    required this.insuranceNumber,
    required this.documents,
    required this.attachments,
    required this.onEdit,
    required this.onView,
  });

  final String licenseNumber;
  final String aadhaarNumber;
  final String vehicleRegistration;
  final String insuranceNumber;
  final List<_KycDocument> documents;
  final Map<String, _KycAttachment> attachments;
  final VoidCallback onEdit;
  final ValueChanged<String> onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    AppIcons.fact_check_outlined,
                    color: AppColors.brand,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Submitted Documents',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(AppIcons.edit_outlined, size: 15),
                  label: Text(AppLocalizations.of(context)!.driverKycEdit),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    _SubmittedFieldTile(
                      label: AppLocalizations.of(
                        context,
                      )!.driverKycDrivingLicense,
                      icon: AppIcons.credit_card_rounded,
                      value: licenseNumber,
                    ),
                    _SubmittedFieldTile(
                      label: AppLocalizations.of(
                        context,
                      )!.driverKycAadhaarNumber,
                      icon: AppIcons.fingerprint_rounded,
                      value: aadhaarNumber,
                    ),
                    _SubmittedFieldTile(
                      label: AppLocalizations.of(
                        context,
                      )!.driverKycVehicleRegShort,
                      icon: AppIcons.local_shipping_outlined,
                      value: vehicleRegistration,
                    ),
                    _SubmittedFieldTile(
                      label: AppLocalizations.of(context)!.driverKycInsurance,
                      icon: AppIcons.shield_outlined,
                      value: insuranceNumber,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < documents.length; i++) ...[
                  _SubmittedDocumentTile(
                    document: documents[i],
                    attachment:
                        attachments[documents[i].key] ?? const _KycAttachment(),
                    onView: () => onView(documents[i].key),
                  ),
                  if (i != documents.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedFieldTile extends StatelessWidget {
  const _SubmittedFieldTile({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textTertiary, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmittedDocumentTile extends StatelessWidget {
  const _SubmittedDocumentTile({
    required this.document,
    required this.attachment,
    required this.onView,
  });

  final _KycDocument document;
  final _KycAttachment attachment;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uploaded = attachment.isUploaded;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            uploaded
                ? AppIcons.check_circle_rounded
                : AppIcons.pending_outlined,
            color: uploaded ? AppColors.brand : AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.driverKycDocumentPhoto(
                    _driverKycDocumentTitle(l10n, document),
                  ),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  uploaded ? l10n.driverKycUploaded : l10n.driverKycNotUploaded,
                  style: TextStyle(
                    color: uploaded
                        ? AppColors.brandDark
                        : AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (uploaded)
            TextButton.icon(
              onPressed: onView,
              icon: const Icon(AppIcons.visibility_outlined, size: 14),
              label: Text(AppLocalizations.of(context)!.driverKycView),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brand,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
        ],
      ),
    );
  }
}

class _KycStatusVisuals {
  const _KycStatusVisuals({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final Color background;
}

_KycStatusVisuals _kycStatusVisuals(String status, AppLocalizations l10n) {
  if (status.contains('verified') ||
      status.contains('approved') ||
      status.contains('complete')) {
    return _KycStatusVisuals(
      title: l10n.driverKycVerifiedTitle,
      subtitle: l10n.driverKycVerifiedSubtitle,
      badge: l10n.driverKycVerifiedBadge,
      icon: AppIcons.verified_rounded,
      color: AppColors.brandDark,
      background: AppColors.brandTint,
    );
  }
  if (status.contains('reject') || status.contains('declin')) {
    return _KycStatusVisuals(
      title: l10n.driverKycRejectedTitle,
      subtitle: l10n.driverKycRejectedSubtitle,
      badge: l10n.driverKycRejectedBadge,
      icon: AppIcons.error_outline_rounded,
      color: AppColors.dangerText,
      background: AppColors.dangerFill,
    );
  }
  if (status.contains('submit') || status.contains('review')) {
    return _KycStatusVisuals(
      title: l10n.driverKycUnderReviewTitle,
      subtitle: l10n.driverKycUnderReviewSubtitle,
      badge: l10n.driverKycSubmittedBadge,
      icon: AppIcons.hourglass_top_rounded,
      color: AppColors.brand,
      background: AppColors.brandTint,
    );
  }
  return _KycStatusVisuals(
    title: l10n.driverKycCompleteTitle,
    subtitle: l10n.driverKycCompleteSubtitle,
    badge: l10n.driverKycPendingBadge,
    icon: AppIcons.badge_outlined,
    color: AppColors.warningText,
    background: AppColors.warningFill,
  );
}

class _KycDocument {
  const _KycDocument({
    required this.key,
    required this.title,
    required this.requiredLabel,
    required this.formats,
    required this.maxSize,
  });

  final String key;
  final String title;
  final String requiredLabel;
  final String formats;
  final String maxSize;
}

String _driverKycDocumentTitle(AppLocalizations l10n, _KycDocument document) {
  return switch (document.key) {
    'pan_photo_url' => l10n.driverKycPanCard,
    'license_photo_url' => l10n.driverKycDrivingLicense,
    'aadhaar_photo_url' => l10n.driverKycAadhaarCard,
    _ => document.title,
  };
}

class _KycAttachment {
  const _KycAttachment({this.fileName, this.sourceLabel, this.path, this.url});

  final String? fileName;
  final String? sourceLabel;
  final String? path;
  final String? url;

  bool get isUploaded => fileName != null;
}

class _StepperItem extends StatelessWidget {
  const _StepperItem({
    required this.label,
    required this.index,
    required this.activeIndex,
  });

  final String label;
  final int index;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final isCompleted = index < activeIndex;
    final isActive = index == activeIndex;
    final textMuted = AppColors.textSecondary;
    final muted = AppColors.line;

    Widget circle;
    if (isCompleted) {
      circle = Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          AppIcons.check_rounded,
          size: 22,
          color: Colors.white,
        ),
      );
    } else if (isActive) {
      circle = Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else {
      circle = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: muted),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(child: circle),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: isCompleted || isActive
                  ? AppColors.textPrimary
                  : textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.info_outline_rounded,
            color: AppColors.warningText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.warningText,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KycUploadCard extends StatelessWidget {
  const _KycUploadCard({
    required this.document,
    required this.attachment,
    required this.onUpload,
    required this.onCamera,
    required this.onGallery,
    required this.onView,
    required this.onReplace,
  });

  final _KycDocument document;
  final _KycAttachment attachment;
  final VoidCallback onUpload;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onView;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uploaded = attachment.isUploaded;
    final borderColor = uploaded ? AppColors.successBorder : AppColors.divider;
    final backgroundColor = uploaded ? AppColors.brandFill : Colors.white;
    final titleColor = uploaded ? AppColors.successText : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
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
                  color: uploaded ? AppColors.brandBorder : AppColors.brandTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  uploaded
                      ? AppIcons.check_circle_rounded
                      : AppIcons.description_rounded,
                  color: uploaded ? AppColors.brand : AppColors.brand,
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
                            _driverKycDocumentTitle(l10n, document),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: titleColor,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TinyTag(
                          label: uploaded
                              ? l10n.driverKycUploaded
                              : l10n.driverKycRequired,
                          uploaded: uploaded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.driverKycSupportedFormats(document.formats),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.driverKycMaxSize10Mb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _MiniIconButton(
                icon: AppIcons.cloud_upload_rounded,
                onPressed: onUpload,
              ),
              const SizedBox(width: 8),
              _MiniIconButton(
                icon: AppIcons.photo_camera_rounded,
                onPressed: onCamera,
              ),
              const SizedBox(width: 8),
              _MiniIconButton(
                icon: AppIcons.photo_library_rounded,
                onPressed: onGallery,
              ),
              if (uploaded) ...[
                const SizedBox(width: 10),
                _MiniIconButton(
                  icon: AppIcons.visibility_rounded,
                  onPressed: onView,
                  filled: true,
                ),
                const SizedBox(width: 8),
                _MiniIconButton(
                  icon: AppIcons.swap_horiz_rounded,
                  onPressed: onReplace,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppColors.brand : Colors.white;
    final iconColor = filled ? Colors.white : AppColors.textSecondary;
    final borderColor = filled ? AppColors.brand : AppColors.line;

    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: background,
          foregroundColor: iconColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.label, required this.uploaded});

  final String label;
  final bool uploaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: uploaded ? AppColors.brandBorder : AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: uploaded ? AppColors.successText : AppColors.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReviewFieldRow extends StatelessWidget {
  const _ReviewFieldRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(AppIcons.edit_rounded),
            color: AppColors.brand,
          ),
        ],
      ),
    );
  }
}

class _ReviewDocumentRow extends StatelessWidget {
  const _ReviewDocumentRow({
    required this.document,
    required this.title,
    required this.attachment,
    required this.onView,
    required this.onReplace,
  });

  final _KycDocument document;
  final String title;
  final _KycAttachment attachment;
  final VoidCallback onView;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uploaded = attachment.isUploaded;
    final hasPreview =
        attachment.path != null && File(attachment.path!).existsSync();
    final subtitle = uploaded
        ? l10n.driverKycUploaded
        : l10n.driverKycWaitingForUpload;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 38,
              height: 38,
              color: uploaded ? AppColors.brandBorder : AppColors.brandTint,
              child: hasPreview
                  ? Image.file(File(attachment.path!), fit: BoxFit.cover)
                  : Icon(
                      uploaded
                          ? AppIcons.check_rounded
                          : AppIcons.insert_drive_file_rounded,
                      color: uploaded ? AppColors.brand : AppColors.brand,
                      size: 18,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: uploaded
                        ? AppColors.successText
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniIconButton(
            icon: AppIcons.visibility_rounded,
            onPressed: onView,
            filled: true,
          ),
          const SizedBox(width: 8),
          _MiniIconButton(
            icon: AppIcons.swap_horiz_rounded,
            onPressed: onReplace,
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: muted ? AppColors.fillSubtle : AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: muted ? AppColors.textSecondary : AppColors.brand,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
