import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

enum _KycStep { details, documents, review, submitted }

class BrokerKycRegistrationScreen extends ConsumerStatefulWidget {
  const BrokerKycRegistrationScreen({super.key});

  @override
  ConsumerState<BrokerKycRegistrationScreen> createState() =>
      _BrokerKycRegistrationScreenState();
}

class _BrokerKycRegistrationScreenState extends ConsumerState<BrokerKycRegistrationScreen> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _confirmCheckboxController = ValueNotifier<bool>(false);
  final _picker = ImagePicker();

  final _panController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _gstController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankAccountConfirmController = TextEditingController();
  final _businessRegController = TextEditingController();

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
    _aadhaarController.dispose();
    _gstController.dispose();
    _bankAccountController.dispose();
    _bankAccountConfirmController.dispose();
    _businessRegController.dispose();
    super.dispose();
  }

  static const _kycDocuments = <_KycDocument>[
    _KycDocument(
      key: 'pan_card',
      title: 'PAN Card',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
    _KycDocument(
      key: 'aadhaar_card',
      title: 'Aadhaar Card',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
    _KycDocument(
      key: 'gst_certificate',
      title: 'GST Certificate',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
    _KycDocument(
      key: 'bank_proof',
      title: 'Cancelled Cheque OR Passbook',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
    _KycDocument(
      key: 'business_certificate',
      title: 'Business Registration Certificate',
      requiredLabel: 'Required',
      formats: 'JPG, PNG, PDF',
      maxSize: 'Max 10 MB',
    ),
  ];

  static const _stepLabels = <String>[
    'Details',
    'Documents',
    'Review',
    'Submit',
  ];

  bool _isApprovedStatus(String status) {
    return status.contains('verified') || status.contains('approved') || status.contains('complete');
  }

  bool _isRejectedStatus(String status) {
    return status.contains('reject') || status.contains('declin');
  }

  bool _isPanValid(String value) {
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value.trim());
  }

  bool _isAadhaarValid(String value) {
    return value.replaceAll(' ', '').trim().length == 12 && RegExp(r'^\d{12}$').hasMatch(value.replaceAll(' ', '').trim());
  }

  bool _isGstValid(String value) {
    return value.trim().length >= 10;
  }

  bool _isBankValid(String value) {
    return RegExp(r'^\d{9,18}$').hasMatch(value.trim());
  }

  bool _isBusinessRegValid(String value) {
    return value.trim().length >= 10;
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _prefillControllers(Map<String, String> documents) {
    _panController.text = documents['pan_number'] ?? _panController.text;
    _aadhaarController.text = documents['aadhaar_number'] ?? _aadhaarController.text;
    _gstController.text = documents['gst_number'] ?? _gstController.text;
    _bankAccountController.text = documents['bank_account_number'] ?? _bankAccountController.text;
    _businessRegController.text =
        documents['business_registration_number'] ?? _businessRegController.text;
  }

  Map<String, dynamic> _documentsPayload() {
    return {
      'pan_number': _panController.text.trim(),
      'aadhaar_number': _aadhaarController.text.replaceAll(' ', '').trim(),
      'gst_number': _gstController.text.trim(),
      'bank_account_number': _bankAccountController.text.trim(),
      'business_registration_number': _businessRegController.text.trim(),
    };
  }

  Map<String, String> _documentsFromMap(Map<String, dynamic>? input) {
    if (input == null) {
      return const {};
    }
    return input.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
  }

  bool _hasUploadedAllDocuments() {
    return _attachments.values.every((attachment) => attachment.isUploaded);
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
      final response =
          await ref.read(apiClientProvider).getBrokerKycStatus(accessToken: session.tokens.accessToken);
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final submission = data['submission'] as Map<String, dynamic>?;
      final documents = _documentsFromMap(submission?['documents'] as Map<String, dynamic>?);
      final hasSubmission = submission != null && submission.isNotEmpty;
      final status = data['kyc_status']?.toString();

      if (mounted) {
        setState(() {
          _hasSubmission = hasSubmission;
          _statusLabel = status;
          _submissionId = submission?['id']?.toString();
          _rejectionReason = submission?['rejection_reason']?.toString();
          _submittedAt = DateTime.tryParse(submission?['submitted_at']?.toString() ?? '');
          _reviewedAt = DateTime.tryParse(submission?['reviewed_at']?.toString() ?? '');

          if (hasSubmission && documents.isNotEmpty) {
            _prefillControllers(documents);
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
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        if (!silent) {
          _errorMessage = error is ApiException ? error.message : error.toString();
        }
      });
    }
  }

  Future<void> _submitKyc() async {
    if (!(_detailsFormKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_hasUploadedAllDocuments()) {
      setState(() {
        _step = _KycStep.documents;
        _errorMessage = 'Please upload all required documents before submitting.';
      });
      return;
    }

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
        const SnackBar(
          content: Text('Please sign in again to submit KYC.'),
          backgroundColor: Color(0xFFE23A4B),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(apiClientProvider).submitBrokerKyc(
            accessToken: session.tokens.accessToken,
            documents: _documentsPayload(),
          );
      _hasSubmission = true;
      _submittedAt = DateTime.now();
      _statusLabel = 'submitted';
      _rejectionReason = null;
      _step = _KycStep.submitted;
      await _loadKycStatus(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC submitted for review.'),
            backgroundColor: Color(0xFF2FA56E),
          ),
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickDocument(String key, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _attachments[key] = _KycAttachment(
          fileName: picked.name,
          sourceLabel: source == ImageSource.camera ? 'Camera' : 'Gallery',
          path: picked.path,
        );
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to pick document right now.'),
          backgroundColor: Color(0xFFE23A4B),
        ),
      );
    }
  }

  void _showUploadOptions(_KycDocument document) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SheetContainer(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you want to upload this document.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SheetAction(
                      icon: Icons.photo_camera_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickDocument(document.key, ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 10),
                    _SheetAction(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickDocument(document.key, ImageSource.gallery);
                      },
                    ),
                    const SizedBox(height: 10),
                    _SheetAction(
                      icon: Icons.close_rounded,
                      label: 'Cancel',
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SheetContainer(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.document_scanner_rounded, color: Color(0xFF1F88C9)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Document preview',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF101828),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE8EDF2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F3FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF1F88C9)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment.fileName ?? 'Uploaded file',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF101828),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  attachment.sourceLabel ?? 'Upload',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF667085),
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
                        backgroundColor: const Color(0xFF1F88C9),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
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

  Widget _buildStepper() {
    final activeIndex = switch (_step) {
      _KycStep.details => 0,
      _KycStep.documents => 1,
      _KycStep.review => 2,
      _KycStep.submitted => 3,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final stepWidth = constraints.maxWidth / _stepLabels.length;
        final lineInset = stepWidth / 2;

        return SizedBox(
          height: 54,
          child: Stack(
            children: [
              Positioned(
                left: lineInset,
                right: lineInset,
                top: 14,
                child: Row(
                  children: [
                    for (var i = 0; i < _stepLabels.length - 1; i++) ...[
                      Expanded(
                        child: Container(
                          height: 2,
                          color: activeIndex > i ? const Color(0xFF1F88C9) : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < _stepLabels.length; i++) ...[
                    Expanded(
                      child: _StepperItem(
                        label: _stepLabels[i],
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

  Widget _buildDetailsStep(BuildContext context) {
    final panValid = _isPanValid(_panController.text);
    final aadhaarValid = _isAadhaarValid(_aadhaarController.text);
    final gstValid = _isGstValid(_gstController.text);
    final bankValid = _isBankValid(_bankAccountController.text);
    final businessValid = _isBusinessRegValid(_businessRegController.text);

    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Complete your KYC to verify your brokerage account.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 16),
          _PremiumTextField(
            controller: _panController,
            label: 'PAN Number',
            hintText: 'ABCDE1234F',
            textCapitalization: TextCapitalization.characters,
            valid: panValid,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) return 'PAN number is required';
              if (!panValid) return 'Enter a valid PAN number';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PremiumTextField(
            controller: _aadhaarController,
            label: 'Aadhaar Number',
            hintText: 'XXXX XXXX XXXX',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              _AadhaarSpacingFormatter(),
            ],
            valid: aadhaarValid,
            validator: (value) {
              final raw = (value ?? '').replaceAll(' ', '').trim();
              if (raw.isEmpty) return 'Aadhaar number is required';
              if (!aadhaarValid) return 'Enter a valid Aadhaar number';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PremiumTextField(
            controller: _gstController,
            label: 'GST Number',
            hintText: '27ABCDE1234F1Z5',
            textCapitalization: TextCapitalization.characters,
            valid: gstValid,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) return 'GST number is required';
              if (!gstValid) return 'Enter a valid GST number';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PremiumTextField(
            controller: _bankAccountController,
            label: 'Bank Account Number',
            hintText: '1234567890123',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(18),
            ],
            valid: bankValid,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) return 'Bank account number is required';
              if (!bankValid) return 'Enter a valid bank account number';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PremiumTextField(
            controller: _bankAccountConfirmController,
            label: 'Confirm Account Number',
            hintText: 'Optional',
            requiredField: false,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(18),
            ],
            valid: _bankAccountConfirmController.text.trim().isNotEmpty &&
                _bankAccountConfirmController.text.trim() == _bankAccountController.text.trim(),
            validator: (value) {
              final confirm = value?.trim() ?? '';
              if (confirm.isEmpty) {
                return null;
              }
              if (confirm != _bankAccountController.text.trim()) {
                return 'Account numbers do not match';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PremiumTextField(
            controller: _businessRegController,
            label: 'Business Registration Number',
            hintText: 'U12345MH2020PTC123456',
            textCapitalization: TextCapitalization.characters,
            valid: businessValid,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) return 'Business registration number is required';
              if (!businessValid) return 'Enter a valid business registration number';
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          if (_rejectionReason != null) ...[
            const SizedBox(height: 14),
            _WarningCard(message: _rejectionReason!),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _WarningCard(message: _errorMessage!),
          ],
        ],
      ),
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
            attachment: _attachments[_kycDocuments[i].key] ?? const _KycAttachment(),
            onUpload: () => _showUploadOptions(_kycDocuments[i]),
            onCamera: () => _pickDocument(_kycDocuments[i].key, ImageSource.camera),
            onGallery: () => _pickDocument(_kycDocuments[i].key, ImageSource.gallery),
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
    final uploadedItems = _kycDocuments
        .map((doc) => MapEntry(doc, _attachments[doc.key] ?? const _KycAttachment()))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Review Your Information',
          subtitle: 'Please verify everything before submitting.',
        ),
        const SizedBox(height: 16),
        _CardSection(
          title: 'Business Information',
          child: Column(
            children: [
              _ReviewFieldRow(
                label: 'PAN Number',
                value: _panController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: 'Aadhaar Number',
                value: _aadhaarController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: 'GST Number',
                value: _gstController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: 'Bank Account Number',
                value: _bankAccountController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
              _ReviewFieldRow(
                label: 'Business Registration Number',
                value: _businessRegController.text.trim(),
                onEdit: () => setState(() => _step = _KycStep.details),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CardSection(
          title: 'Uploaded Documents',
          child: Column(
            children: [
              for (var i = 0; i < uploadedItems.length; i++) ...[
                _ReviewDocumentRow(
                  title: uploadedItems[i].key.title,
                  attachment: uploadedItems[i].value,
                  onView: () => _showAttachmentPreview(uploadedItems[i].key.key),
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
              activeColor: const Color(0xFF1F88C9),
              onChanged: (value) {
                _confirmCheckboxController.value = value ?? false;
                setState(() {});
              },
              title: Text(
                'I confirm that all the information provided is accurate.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF101828),
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
    final isApproved = _statusLabel != null && _isApprovedStatus(_statusLabel!.toLowerCase());
    final title = isApproved ? 'KYC Verification Complete' : 'KYC Submitted Successfully';
    final badgeLabel = isApproved ? 'Verified' : 'Submitted for Review';
    final description = isApproved
        ? 'Your KYC has been verified. Your broker account is now active.'
        : 'Your KYC has been successfully submitted. Our verification team will review your documents. This usually takes 24-48 hours.';
    final currentStatus = isApproved ? 'Verified' : 'Pending Review';
    final statusColor = isApproved ? const Color(0xFF2FA56E) : const Color(0xFF1F88C9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: title,
          subtitle: description,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EDF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApproved ? Icons.verified_rounded : Icons.check_circle_rounded,
                  size: 52,
                  color: const Color(0xFF2FA56E),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                badgeLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2FA56E),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                      height: 1.45,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CardSection(
          title: 'Status Card',
          child: Column(
            children: [
              _StatusInfoRow(label: 'Current Status', value: currentStatus, valueColor: statusColor),
              const SizedBox(height: 10),
              _StatusInfoRow(
                label: 'Submitted Date',
                value: _submittedAt != null ? _formatDateTime(_submittedAt!) : 'Not available',
                valueColor: const Color(0xFF101828),
              ),
              const SizedBox(height: 10),
              _StatusInfoRow(
                label: 'Submission ID',
                value: _submissionId ?? 'Not available',
                valueColor: const Color(0xFF101828),
              ),
              if (_reviewedAt != null) ...[
                const SizedBox(height: 10),
                _StatusInfoRow(
                  label: 'Reviewed At',
                  value: _formatDateTime(_reviewedAt!),
                  valueColor: const Color(0xFF101828),
                ),
              ],
            ],
          ),
        ),
        if (isApproved) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _showAllDocuments,
            icon: const Icon(Icons.folder_copy_rounded),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2FA56E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            label: const Text('View my documents', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ],
    );
  }

  void _showAllDocuments() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SheetContainer(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_copy_rounded, color: Color(0xFF1F88C9)),
                        const SizedBox(width: 10),
                        Text(
                          'My documents',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _kycDocuments.length; i++) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EDF2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF1F88C9)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _kycDocuments[i].title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF101828),
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _attachments[_kycDocuments[i].key]?.fileName ?? 'Uploaded file',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF667085),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i != _kycDocuments.length - 1) const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F88C9),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
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

  Widget _bottomBar(BuildContext context) {
    if (_step == _KycStep.submitted) {
      final isApproved = _statusLabel != null && _isApprovedStatus(_statusLabel!.toLowerCase());
      return SafeArea(
        top: false,
        child: Container(
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8EDF2))),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _goBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: const Color(0xFF101828),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Go Back', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isApproved ? _showAllDocuments : () => _loadKycStatus(),
                  style: FilledButton.styleFrom(
                    backgroundColor: isApproved ? const Color(0xFF2FA56E) : const Color(0xFF1F88C9),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    isApproved ? 'View my documents' : 'View KYC Status',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final label = _step == _KycStep.review ? 'Submit KYC' : 'Continue';
    final action = _step == _KycStep.details
        ? () {
            if (!(_detailsFormKey.currentState?.validate() ?? false)) {
              return;
            }
            setState(() {
              _errorMessage = null;
              _step = _KycStep.documents;
            });
          }
        : _step == _KycStep.documents
            ? () {
                if (!_hasUploadedAllDocuments()) {
                  setState(() {
                    _errorMessage = 'Please upload all required documents before continuing.';
                  });
                  return;
                }
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
          border: Border(top: BorderSide(color: Color(0xFFE8EDF2))),
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
              backgroundColor: const Color(0xFF1F88C9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (_step) {
        _KycStep.details => _buildDetailsStep(context),
        _KycStep.documents => _buildDocumentsStep(context),
        _KycStep.review => _buildReviewStep(context),
        _KycStep.submitted => _buildSubmittedStep(context),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _stepBody(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FC),
        elevation: 0,
        centerTitle: true,
        leadingWidth: 56,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: InkWell(
            onTap: _goBack,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF101828)),
            ),
          ),
        ),
        title: Text(
          'KYC registration',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF101828),
              ),
        ),
      ),
      body: SafeArea(
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _buildStepper(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        _step == _KycStep.submitted ? 24 : 120,
                      ),
                      child: body,
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }
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

class _KycAttachment {
  const _KycAttachment({
    this.fileName,
    this.sourceLabel,
    this.path,
  });

  final String? fileName;
  final String? sourceLabel;
  final String? path;

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
    final textMuted = const Color(0xFF667085);
    final muted = const Color(0xFFE5E7EB);

    Widget circle;
    if (isCompleted) {
      circle = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF2FA56E),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
      );
    } else if (isActive) {
      circle = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFF1F88C9),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      circle = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: muted),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontWeight: FontWeight.w700,
              fontSize: 12,
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
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              height: 1.0,
              fontWeight: FontWeight.w600,
              color: isCompleted || isActive ? const Color(0xFF101828) : textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

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
                color: const Color(0xFF101828),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF667085),
                height: 1.4,
              ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
          ),
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2D9A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFB54708)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8A4B0F),
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

class _PremiumTextField extends StatelessWidget {
  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.valid,
    required this.validator,
    required this.onChanged,
    this.requiredField = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool valid;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onChanged;
  final bool requiredField;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;
    final statusIcon = !hasValue
        ? Icons.radio_button_unchecked_rounded
        : valid
            ? Icons.check_rounded
            : Icons.close_rounded;
    final statusColor = !hasValue
        ? const Color(0xFF98A2B3)
        : valid
            ? const Color(0xFF2FA56E)
            : const Color(0xFFE23A4B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8EDF2)),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF101828),
                              ),
                        ),
                        if (requiredField) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: Color(0xFFE23A4B),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: controller,
                      validator: validator,
                      keyboardType: keyboardType,
                      textCapitalization: textCapitalization,
                      inputFormatters: inputFormatters,
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(top: 0, bottom: 0),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: hintText,
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF98A2B3),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(statusIcon, color: statusColor, size: 14),
            ],
          ),
        ),
      ],
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
    final uploaded = attachment.isUploaded;
    final borderColor = uploaded ? const Color(0xFFB7E4C7) : const Color(0xFFE8EDF2);
    final backgroundColor = uploaded ? const Color(0xFFF0FBF4) : Colors.white;
    final titleColor = uploaded ? const Color(0xFF1F7A52) : const Color(0xFF101828);

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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: uploaded ? const Color(0xFFD9F3E5) : const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  uploaded ? Icons.check_circle_rounded : Icons.description_rounded,
                  color: uploaded ? const Color(0xFF2FA56E) : const Color(0xFF1F88C9),
                ),
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
                            document.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                          ),
                        ),
                        if (uploaded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9F3E5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Uploaded',
                              style: TextStyle(
                                color: Color(0xFF1F7A52),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              document.requiredLabel,
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported formats: ${document.formats}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      document.maxSize,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera_rounded),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              if (uploaded) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onView,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
          if (uploaded) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onReplace,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Color(0xFFB7E4C7)),
                  foregroundColor: const Color(0xFF1F7A52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Replace', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
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
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            color: const Color(0xFF1F88C9),
          ),
        ],
      ),
    );
  }
}

class _ReviewDocumentRow extends StatelessWidget {
  const _ReviewDocumentRow({
    required this.title,
    required this.attachment,
    required this.onView,
    required this.onReplace,
  });

  final String title;
  final _KycAttachment attachment;
  final VoidCallback onView;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final uploaded = attachment.isUploaded;
    final hasPreview = attachment.path != null && File(attachment.path!).existsSync();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              color: uploaded ? const Color(0xFFD9F3E5) : const Color(0xFFEAF1FF),
              child: hasPreview
                  ? Image.file(
                      File(attachment.path!),
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      uploaded ? Icons.check_rounded : Icons.insert_drive_file_rounded,
                      color: uploaded ? const Color(0xFF2FA56E) : const Color(0xFF1F88C9),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  uploaded ? 'Uploaded' : 'Waiting for upload',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: uploaded ? const Color(0xFF1F7A52) : const Color(0xFF667085),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onView,
            child: const Text('View'),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: onReplace,
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  const _StatusInfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
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
          color: muted ? const Color(0xFFF8F9FC) : const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: muted ? const Color(0xFF667085) : const Color(0xFF1F88C9)),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AadhaarSpacingFormatter extends TextInputFormatter {
  const _AadhaarSpacingFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 3 || i == 7) {
        buffer.write(' ');
      }
    }
    final text = buffer.toString().trimRight();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
