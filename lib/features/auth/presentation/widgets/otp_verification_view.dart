import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gadidost/core/theme/app_icons.dart';

import '../../../../core/network/api_client.dart';
import '../../data/otp_service.dart';
import 'otp_code_input.dart';

const _green = Color(0xFF2FA56E);
const _red = Color(0xFFE23A4B);
const _ink = Color(0xFF1B2A3A);
const _muted = Color(0xFF667085);

/// Phone-OTP entry: digit boxes, status line and resend timer.
///
/// Verifies the code with Firebase through [otpServiceProvider] (or picks up
/// Android auto-verification); once the success animation finishes it awaits
/// [onVerified] with the Firebase ID token. If that throws, the error is
/// shown and the user can enter the code again.
class OtpVerificationView extends ConsumerStatefulWidget {
  const OtpVerificationView({
    super.key,
    required this.phone,
    required this.onVerified,
    this.onChangeNumber,
    this.title = 'Verify your number',
    this.continuingLabel = 'Signing you in…',
    this.showBadge = true,
  });

  final String phone;
  final Future<void> Function(String idToken) onVerified;
  final VoidCallback? onChangeNumber;
  final String title;
  final String continuingLabel;
  final bool showBadge;

  @override
  ConsumerState<OtpVerificationView> createState() =>
      _OtpVerificationViewState();
}

class _OtpVerificationViewState extends ConsumerState<OtpVerificationView> {
  static const _resendSeconds = 30;

  OtpInputStatus _status = OtpInputStatus.idle;
  String? _error;
  bool _continuing = false;
  bool _resending = false;
  int _secondsLeft = _resendSeconds;
  int _inputGeneration = 0;
  String? _idToken;
  Timer? _timer;
  StreamSubscription<OtpAutoVerification>? _autoSub;

  @override
  void initState() {
    super.initState();
    _startTimer();
    final otp = ref.read(otpServiceProvider);
    _autoSub = otp.autoVerifications.listen(_onAutoVerified);
    final early = otp.takeAutoVerification(widget.phone);
    if (early != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onAutoVerified(early);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoSub?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) timer.cancel();
      setState(() => _secondsLeft -= 1);
    });
  }

  /// Android verified the number by itself — skip straight to success.
  void _onAutoVerified(OtpAutoVerification result) {
    if (result.phone != widget.phone ||
        _status == OtpInputStatus.success ||
        _continuing) {
      return;
    }
    setState(() {
      _idToken = result.idToken;
      _error = null;
      _status = OtpInputStatus.success;
    });
  }

  Future<void> _verify(String code) async {
    if (_status != OtpInputStatus.idle) return;
    setState(() {
      _status = OtpInputStatus.verifying;
      _error = null;
    });
    try {
      final idToken = await ref
          .read(otpServiceProvider)
          .verifyOtp(phone: widget.phone, code: code);
      if (!mounted || _status == OtpInputStatus.success) return;
      setState(() {
        _idToken = idToken;
        _status = OtpInputStatus.success;
      });
    } on OtpException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        if (error.wrongCode) {
          _status = OtpInputStatus.error;
        } else {
          _status = OtpInputStatus.idle;
          _inputGeneration++;
        }
      });
    }
  }

  Future<void> _continue() async {
    final idToken = _idToken;
    if (idToken == null) return;
    setState(() => _continuing = true);
    try {
      await widget.onVerified(idToken);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _continuing = false;
        _status = OtpInputStatus.idle;
        _idToken = null;
        _inputGeneration++;
        _error = error is ApiException
            ? error.message
            : error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(otpServiceProvider).sendOtp(phone: widget.phone);
      if (!mounted) return;
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New code sent to ${formatIndianPhone(widget.phone)}'),
          backgroundColor: _green,
        ),
      );
    } on OtpException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showBadge) ...[
          const _PhoneBadge(),
          const SizedBox(height: 18),
        ],
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: 'Enter the $kOtpLength-digit code sent to\n',
            children: [
              TextSpan(
                text: formatIndianPhone(widget.phone),
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, height: 1.5, color: _muted),
        ),
        if (widget.onChangeNumber != null)
          TextButton(
            onPressed: _continuing ? null : widget.onChangeNumber,
            style: TextButton.styleFrom(
              foregroundColor: _green,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Change number'),
          ),
        const SizedBox(height: 20),
        OtpCodeInput(
          key: ValueKey(_inputGeneration),
          length: kOtpLength,
          status: _status,
          onCompleted: _verify,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onErrorAnimationDone: () {
            if (mounted) setState(() => _status = OtpInputStatus.idle);
          },
          onSuccessAnimationDone: _continue,
        ),
        const SizedBox(height: 6),
        SizedBox(height: 20, child: Center(child: _statusLine())),
        const SizedBox(height: 6),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _status == OtpInputStatus.success || _continuing ? 0 : 1,
          child: _resendRow(),
        ),
      ],
    );
  }

  Widget _statusLine() {
    final Widget child;
    if (_continuing) {
      child = Row(
        key: const ValueKey('continuing'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: _green),
          ),
          const SizedBox(width: 10),
          Text(
            widget.continuingLabel,
            style: const TextStyle(color: _green, fontWeight: FontWeight.w700),
          ),
        ],
      );
    } else if (_status == OtpInputStatus.success) {
      child = const Text(
        'Verified!',
        key: ValueKey('verified'),
        style: TextStyle(
          color: _green,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      );
    } else if (_status == OtpInputStatus.verifying) {
      child = const Text(
        'Verifying…',
        key: ValueKey('verifying'),
        style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
      );
    } else if (_error != null) {
      child = Row(
        key: ValueKey('error-$_error'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.warning_amber_rounded, size: 16, color: _red),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
    } else {
      child = const SizedBox.shrink(key: ValueKey('idle'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 90),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _resendRow() {
    final canResend = _secondsLeft <= 0 && !_resending;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Didn\'t get the code?',
          style: TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: canResend
              ? TextButton(
                  key: const ValueKey('resend'),
                  onPressed: _resend,
                  style: TextButton.styleFrom(
                    foregroundColor: _green,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Resend code',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                )
              : Text(
                  _resending
                      ? 'Sending…'
                      : 'Resend in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                  key: const ValueKey('timer'),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Soft green badge with a gently floating phone icon.
class _PhoneBadge extends StatefulWidget {
  const _PhoneBadge();

  @override
  State<_PhoneBadge> createState() => _PhoneBadgeState();
}

class _PhoneBadgeState extends State<_PhoneBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _green.withValues(alpha: 0.20),
            _green.withValues(alpha: 0.06),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -4 + 8 * Curves.easeInOut.transform(_float.value)),
          child: child,
        ),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            AppIcons.shield_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
