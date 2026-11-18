import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/client_kyc_gate_provider.dart';
import '../../../../core/widgets/digilocker_verification_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Client KYC has no submit/review stage (KYC guide Pt2): the user picks
/// "Aadhaar + PAN" or "GST" on the card's toggle, and the backend finalises
/// KYC automatically the moment either path verifies.
class ClientVerificationScreen extends ConsumerStatefulWidget {
  const ClientVerificationScreen({super.key});
  @override
  ConsumerState<ClientVerificationScreen> createState() =>
      _ClientVerificationScreenState();
}

class _ClientVerificationScreenState
    extends ConsumerState<ClientVerificationScreen> {
  Map<String, String> _statuses = const {};
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
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
          _statuses = parseVerificationStatuses(
            results,
            kycTrackedDocs('client'),
          );
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
                  'Choose one option: Aadhaar + PAN, or your business GSTIN. Either one is enough.',
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
                  },
                  // A path just verified: the backend auto-finalises client
                  // KYC, so pick up the new kyc_status.
                  onDigilockerDone: (_) =>
                      ref.read(clientKycGateProvider.notifier).refresh(),
                ),
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
