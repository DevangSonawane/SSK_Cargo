import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

enum _KycFlowState { form, pending, approved, rejected }

class BrokerKycRegistrationScreen extends ConsumerStatefulWidget {
  const BrokerKycRegistrationScreen({super.key});

  @override
  ConsumerState<BrokerKycRegistrationScreen> createState() =>
      _BrokerKycRegistrationScreenState();
}

class _BrokerKycRegistrationScreenState extends ConsumerState<BrokerKycRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _gstController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _businessRegController = TextEditingController();

  Timer? _refreshTimer;

  bool _initialLoading = true;
  bool _saving = false;
  String? _errorMessage;
  String? _statusLabel;
  String? _rejectionReason;
  DateTime? _submittedAt;
  DateTime? _reviewedAt;
  Map<String, String> _submittedDocuments = const {};

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_currentFlowState == _KycFlowState.pending) {
        _loadKycStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _panController.dispose();
    _aadhaarController.dispose();
    _gstController.dispose();
    _bankAccountController.dispose();
    _businessRegController.dispose();
    super.dispose();
  }

  _KycFlowState get _currentFlowState {
    final status = _statusLabel?.toLowerCase().trim();
    if (status == null || status.isEmpty) {
      return _submittedDocuments.isEmpty ? _KycFlowState.form : _KycFlowState.pending;
    }
    if (_isApprovedStatus(status)) {
      return _KycFlowState.approved;
    }
    if (_isRejectedStatus(status)) {
      return _KycFlowState.rejected;
    }
    if (_isPendingStatus(status)) {
      return _KycFlowState.pending;
    }
    return _submittedDocuments.isEmpty ? _KycFlowState.form : _KycFlowState.pending;
  }

  bool _isApprovedStatus(String status) {
    return status.contains('verified') || status.contains('approved') || status.contains('complete');
  }

  bool _isRejectedStatus(String status) {
    return status.contains('reject') || status.contains('declin');
  }

  bool _isPendingStatus(String status) {
    return status.contains('pending') ||
        status.contains('submit') ||
        status.contains('review') ||
        status.contains('under');
  }

  String _labelForKey(String key) {
    return switch (key) {
      'pan_number' => 'PAN number',
      'aadhaar_number' => 'Aadhaar number',
      'gst_number' => 'GST number',
      'bank_account_number' => 'Bank account number',
      'business_registration_number' => 'Business registration number',
      _ => key.replaceAll('_', ' '),
    };
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
      'aadhaar_number': _aadhaarController.text.trim(),
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
          .getBrokerKycStatus(accessToken: session.tokens.accessToken);
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final submission = data['submission'] as Map<String, dynamic>?;
      final documents = _documentsFromMap(submission?['documents'] as Map<String, dynamic>?);

      if (mounted) {
        setState(() {
          _statusLabel = data['kyc_status']?.toString();
          _rejectionReason = submission?['rejection_reason']?.toString();
          _submittedAt = DateTime.tryParse(submission?['submitted_at']?.toString() ?? '');
          _reviewedAt = DateTime.tryParse(submission?['reviewed_at']?.toString() ?? '');
          _submittedDocuments = documents;
          if (_currentFlowState != _KycFlowState.form && documents.isNotEmpty) {
            _prefillControllers(documents);
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
    if (!(_formKey.currentState?.validate() ?? false)) {
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
      _submittedDocuments = {
        'pan_number': _panController.text.trim(),
        'aadhaar_number': _aadhaarController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim(),
        'business_registration_number': _businessRegController.text.trim(),
      };
      _submittedAt = DateTime.now();
      _statusLabel = 'submitted';
      _rejectionReason = null;
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

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  void _showDocumentsSheet() {
    final entries = _submittedDocuments.entries.toList(growable: false);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SheetContainer(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_copy_rounded, color: Color(0xFF1F88C9)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'My documents',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF101828),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (entries.isEmpty)
                      Text(
                        'No document snapshot is available yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF667085),
                            ),
                      )
                    else
                      ...entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8EDF2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _labelForKey(entry.key),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFF667085),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.value,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: const Color(0xFF101828),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F88C9),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w800),
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

  Widget _buildHeroCard(BuildContext context, _KycFlowState state) {
    final now = DateTime.now();
    final elapsed = _submittedAt == null ? null : now.difference(_submittedAt!);

    final cardColor = switch (state) {
      _KycFlowState.approved => const [Color(0xFF2FA56E), Color(0xFF1F7A52)],
      _KycFlowState.pending => const [Color(0xFF1F88C9), Color(0xFF0F5F98)],
      _KycFlowState.rejected => const [Color(0xFFE23A4B), Color(0xFFB42334)],
      _KycFlowState.form => const [Color(0xFF1F88C9), Color(0xFF0F5F98)],
    };

    final title = switch (state) {
      _KycFlowState.approved => 'KYC verification complete',
      _KycFlowState.pending => 'Verification submitted',
      _KycFlowState.rejected => 'Verification needs attention',
      _KycFlowState.form => 'KYC registration',
    };

    final subtitle = switch (state) {
      _KycFlowState.approved =>
        'Your broker account is verified. You can now review your documents.',
      _KycFlowState.pending =>
        elapsed == null ? 'Your submission is waiting for admin review.' : 'Waiting for admin review. ${_formatElapsed(elapsed)} elapsed.',
      _KycFlowState.rejected =>
        _rejectionReason == null ? 'Please update the documents and resubmit.' : _rejectionReason!,
      _KycFlowState.form =>
        'Submit your legal and financial identity documents to start review.',
    };

    final icon = switch (state) {
      _KycFlowState.approved => Icons.verified_rounded,
      _KycFlowState.pending => Icons.access_time_rounded,
      _KycFlowState.rejected => Icons.error_outline_rounded,
      _KycFlowState.form => Icons.badge_rounded,
    };

    final trailing = switch (state) {
      _KycFlowState.pending => elapsed == null ? 'Clock active' : _formatElapsed(elapsed),
      _KycFlowState.approved => 'Verified',
      _KycFlowState.rejected => 'Action required',
      _KycFlowState.form => 'Ready to submit',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cardColor,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: cardColor.last.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                ),
                if (state == _KycFlowState.pending && elapsed != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trailing,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, _KycFlowState state) {
    final rows = _submittedDocuments.entries.toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state == _KycFlowState.approved
                    ? Icons.verified_user_rounded
                    : Icons.description_rounded,
                color:
                    state == _KycFlowState.approved ? const Color(0xFF2FA56E) : const Color(0xFF1F88C9),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state == _KycFlowState.approved ? 'Verified documents' : 'Submitted details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_submittedAt != null) ...[
            _DetailRow(
              label: 'Submitted at',
              value: _submittedAt!.toLocal().toString().split('.').first,
            ),
            const SizedBox(height: 10),
          ],
          if (_reviewedAt != null) ...[
            _DetailRow(
              label: 'Reviewed at',
              value: _reviewedAt!.toLocal().toString().split('.').first,
            ),
            const SizedBox(height: 10),
          ],
          if (rows.isEmpty)
            Text(
              'No document details available yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
            )
          else
            ...rows.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DetailRow(
                  label: _labelForKey(entry.key),
                  value: entry.value,
                ),
              ),
            ),
          if (state == _KycFlowState.approved) ...[
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _showDocumentsSheet,
              icon: const Icon(Icons.folder_copy_rounded),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2FA56E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: const Text(
                'View my documents',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F3FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF1F88C9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Submit your business identity documents once. The admin review will update this screen automatically.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                          height: 1.4,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFEC9D1)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFE23A4B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _DocumentField(
            controller: _panController,
            label: 'PAN number',
            hintText: 'ABCDE1234F',
            icon: Icons.credit_card_rounded,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'PAN number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _DocumentField(
            controller: _aadhaarController,
            label: 'Aadhaar number',
            hintText: 'XXXX-XXXX-1234',
            icon: Icons.badge_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Aadhaar number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _DocumentField(
            controller: _gstController,
            label: 'GST number',
            hintText: '27ABCDE1234F1Z5',
            icon: Icons.receipt_long_rounded,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'GST number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _DocumentField(
            controller: _bankAccountController,
            label: 'Bank account number',
            hintText: '1234567890123',
            icon: Icons.account_balance_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Bank account number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _DocumentField(
            controller: _businessRegController,
            label: 'Business registration number',
            hintText: 'U12345MH2020PTC123456',
            icon: Icons.storefront_rounded,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Business registration number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _saving ? null : _submitKyc,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F88C9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                  : const Text(
                      'Submit for verification',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(BuildContext context) {
    if (_rejectionReason == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEC9D1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE23A4B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _rejectionReason!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF922234),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flowState = _currentFlowState;
    final showForm = flowState == _KycFlowState.form || flowState == _KycFlowState.rejected;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('KYC registration'),
      ),
      body: SafeArea(
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _loadKycStatus(silent: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroCard(context, flowState),
                      const SizedBox(height: 18),
                      if (flowState == _KycFlowState.rejected) ...[
                        _buildRejectedBanner(context),
                        const SizedBox(height: 18),
                      ],
                      if (showForm) ...[
                        _buildForm(context),
                      ] else ...[
                        _buildDetailsCard(context, flowState),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _showDocumentsSheet,
                          icon: const Icon(Icons.folder_copy_rounded),
                          style: FilledButton.styleFrom(
                            backgroundColor: flowState == _KycFlowState.approved
                                ? const Color(0xFF2FA56E)
                                : const Color(0xFF1F88C9),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          label: Text(
                            flowState == _KycFlowState.approved
                                ? 'View my documents'
                                : 'Review submission',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DocumentField extends StatelessWidget {
  const _DocumentField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
