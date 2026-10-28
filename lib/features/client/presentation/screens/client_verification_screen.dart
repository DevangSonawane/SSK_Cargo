import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/client_kyc_gate_provider.dart';
import '../../../../core/widgets/digilocker_verification_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Client KYC has no submit/review stage: Aadhaar + PAN come from one
/// DigiLocker session and GST is verified manually; the backend finalises KYC
/// automatically when all three checks pass.
class ClientVerificationScreen extends ConsumerStatefulWidget {
  const ClientVerificationScreen({super.key});
  @override
  ConsumerState<ClientVerificationScreen> createState() =>
      _ClientVerificationScreenState();
}

class _ClientVerificationScreenState
    extends ConsumerState<ClientVerificationScreen> {
  final _gst = TextEditingController();
  Map<String, String> _statuses = const {};
  bool _loading = true;
  bool _verifying = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gst.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token =
        ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
    try {
      final response = await ref
          .read(apiClientProvider)
          .getKycStatus(accessToken: token);
      final data = response['data'] is Map
          ? (response['data'] as Map).cast<String, dynamic>()
          : response;
      final submission = data['submission'] is Map
          ? (data['submission'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final results = submission['verification_results'] is Map
          ? (submission['verification_results'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      if (mounted)
        setState(() {
          _statuses = parseVerificationStatuses(results, const [
            'aadhaar',
            'pan',
            'gst',
          ]);
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyGst() async {
    final value = _gst.text.trim().toUpperCase();
    if (!RegExp(
      r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
    ).hasMatch(value)) {
      setState(() => _message = 'Enter a valid 15-character GSTIN.');
      return;
    }
    setState(() => _verifying = true);
    try {
      final token =
          ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
      final result = await ref
          .read(apiClientProvider)
          .verifyGst(accessToken: token, gstin: value);
      final data = result['data'] is Map
          ? (result['data'] as Map).cast<String, dynamic>()
          : result;
      final status = '${data['status'] ?? 'failed'}'.toLowerCase();
      final details = data['details'] is Map
          ? (data['details'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      if (mounted)
        setState(() {
          _statuses = {..._statuses, 'gst': status};
          _message = details['message']?.toString();
        });
      await ref.read(clientKycGateProvider.notifier).refresh();
    } catch (e) {
      if (mounted)
        setState(
          () => _message = e is ApiException
              ? e.message
              : 'GST verification failed.',
        );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final status = ref.watch(clientKycGateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Verify your account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aadhaar and PAN are verified together via DigiLocker. GST verification is required separately.',
                ),
                const SizedBox(height: 18),
                DigilockerVerificationCard(
                  role: 'client',
                  accessToken: session?.tokens.accessToken ?? '',
                  userName: session?.user.name ?? '',
                  initialStatuses: _statuses,
                  onChanged: (snapshot) {
                    setState(
                      () => _statuses = {..._statuses, ...snapshot.statuses},
                    );
                    ref.read(clientKycGateProvider.notifier).refresh();
                  },
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GSTIN',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _gst,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: '27ABCDE1234F1Z5',
                            suffixIcon: Icon(
                              _statuses['gst'] == 'verified'
                                  ? Icons.verified
                                  : Icons.pending,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: _verifying ? null : _verifyGst,
                          child: Text(
                            _verifying ? 'Verifying…' : 'Verify GSTIN',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: const TextStyle(color: Colors.red)),
                ],
                if (status.verified) ...[
                  const SizedBox(height: 18),
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.verified, color: Colors.green),
                      title: Text('Verification complete'),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
