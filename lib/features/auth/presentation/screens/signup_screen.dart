import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gadidost/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gadidost/l10n/app_localizations.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/otp_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_verification_view.dart';
import 'package:gadidost/core/utils/user_facing_error.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _faint = Color(0xFF9CA3AF);
const _line = Color(0xFFE5E7EB);
const _green = Color(0xFF149468);
const _red = Color(0xFFDC2626);

enum _SignupStep { details, truck, verify }

/// Truck types a self-registering driver can pick (web parity:
/// `src/lib/truckTypes.js`, kept in sync with the backend by hand).
const _truckTypes = <({String value, String label, String capacity})>[
  (value: '3_wheeler', label: '3 Wheeler', capacity: '500 kg'),
  (value: 'tata_ace', label: 'Tata Ace', capacity: '750 kg'),
  (value: 'pickup_8ft', label: 'Pickup 8ft', capacity: '1 Ton'),
  (value: 'pickup_10ft', label: 'Pickup 10ft', capacity: '1.2 Ton'),
  (value: '14ft', label: '14ft Truck', capacity: '3.7 Ton'),
  (value: '17ft', label: '17ft Truck', capacity: '4.5 Ton'),
  (value: '19ft', label: '19ft Truck', capacity: '6 Ton'),
  (value: '22ft', label: '22ft Truck', capacity: '7 Ton'),
  (value: '32ft_sxl', label: '32ft SXL', capacity: '9 Ton'),
  (value: '32ft_mxl', label: '32ft MXL', capacity: '18 Ton'),
];

final _registrationRegex = RegExp(
  r'^[A-Z]{2}[-\s]?\d{1,2}[-\s]?[A-Z]{1,3}[-\s]?\d{1,4}$',
  caseSensitive: false,
);

/// Sign-up for clients, brokers and drivers: account details → (driver
/// only) their truck → phone OTP. The new account is signed in straight away
/// after verification.
///
/// Mirrors the web registration (`Register.jsx`): brokers add a business
/// name and use `POST /api/auth/register`; drivers register themselves with
/// their own truck via `POST /api/auth/register/driver`.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.role = AppRole.client});

  final AppRole role;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessController = TextEditingController();
  final _registrationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _makeController = TextEditingController();
  final _yearController = TextEditingController();

  _SignupStep _step = _SignupStep.details;
  bool _forward = true;
  bool _isSendingOtp = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;
  String _truckCategory = '14ft';
  DateTime? _insuranceExpiry;

  bool get _isBroker => widget.role == AppRole.broker;
  bool get _isDriver => widget.role == AppRole.driver;

  List<_SignupStep> get _steps => _isDriver
      ? _SignupStep.values
      : const [_SignupStep.details, _SignupStep.verify];

  String get _loginPath => switch (widget.role) {
    AppRole.broker => '/broker/login',
    AppRole.driver => '/driver/login',
    _ => '/login',
  };

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _capacityController.text = _capacityFor(_truckCategory);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _businessController.dispose();
    _registrationController.dispose();
    _capacityController.dispose();
    _makeController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  String get _phone => normalizeIndianPhone(_phoneController.text);

  static String _capacityFor(String category) =>
      _truckTypes.firstWhere((t) => t.value == category).capacity;

  void _goTo(_SignupStep step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = _steps.indexOf(step) > _steps.indexOf(_step);
      _step = step;
      _error = null;
    });
  }

  void _back() {
    final index = _steps.indexOf(_step);
    if (index <= 0) {
      context.go(_loginPath);
    } else {
      _goTo(_steps[index - 1]);
    }
  }

  void _fail(String message) {
    HapticFeedback.mediumImpact();
    setState(() => _error = message);
  }

  /// Validates the account details. Returns an error message, or null.
  String? _validateDetails(AppLocalizations l10n) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty ||
        email.isEmpty ||
        _phoneController.text.isEmpty ||
        password.isEmpty ||
        (_isBroker && _businessController.text.trim().isEmpty)) {
      return l10n.signupAllFieldsRequired;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    if (_phone.length != 10) {
      return 'Enter a valid 10-digit mobile number.';
    }
    if (password.length < 8) return l10n.signupPasswordHelper;
    return null;
  }

  String? _validateTruck() {
    final registration = _registrationController.text.trim();
    if (registration.isEmpty) return 'Truck registration number is required.';
    if (!_registrationRegex.hasMatch(registration)) {
      return 'Registration number looks invalid, e.g. MH-12-AB-1234.';
    }
    if (_capacityController.text.trim().isEmpty) {
      return 'Capacity is required.';
    }
    final yearText = _yearController.text.trim();
    if (yearText.isNotEmpty) {
      final year = int.tryParse(yearText);
      final maxYear = DateTime.now().year + 1;
      if (year == null || year < 1990 || year > maxYear) {
        return 'Enter a year between 1990 and $maxYear.';
      }
    }
    return null;
  }

  void _submitDetails() {
    final error = _validateDetails(AppLocalizations.of(context)!);
    if (error != null) return _fail(error);
    if (_isDriver) {
      _goTo(_SignupStep.truck);
    } else {
      _sendOtp();
    }
  }

  void _submitTruck() {
    final error = _validateTruck();
    if (error != null) return _fail(error);
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;
    setState(() {
      _isSendingOtp = true;
      _error = null;
    });
    try {
      await ref.read(otpServiceProvider).sendOtp(phone: _phone);
      if (mounted) _goTo(_SignupStep.verify);
    } catch (error) {
      if (mounted) _fail(userFacingError(error));
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _register(String idToken) {
    final auth = ref.read(authSessionProvider.notifier);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (_isDriver) {
      final make = _makeController.text.trim();
      final expiry = _insuranceExpiry;
      return auth.registerDriver(
        name: name,
        email: email,
        phone: _phone,
        password: password,
        registration: _registrationController.text.trim().toUpperCase(),
        category: _truckCategory,
        capacity: _capacityController.text.trim(),
        make: make.isEmpty ? null : make,
        year: int.tryParse(_yearController.text.trim()),
        insuranceExpiry: expiry == null
            ? null
            : '${expiry.year.toString().padLeft(4, '0')}-'
                  '${expiry.month.toString().padLeft(2, '0')}-'
                  '${expiry.day.toString().padLeft(2, '0')}',
        idToken: idToken,
      );
    }
    return auth.register(
      name: name,
      email: email,
      phone: _phone,
      password: password,
      role: widget.role.name,
      businessName: _isBroker ? _businessController.text.trim() : null,
      idToken: idToken,
    );
  }

  /// Creates the account with the Firebase [idToken] that proves ownership
  /// of [_phone] (the backend rejects signups without it). The token is used
  /// straight away and never stored, so editing the number always needs a
  /// fresh OTP.
  Future<void> _createAccount(String idToken) async {
    if (_isSubmitting) return;
    final password = _passwordController.text;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final auth = ref.read(authSessionProvider.notifier);
    try {
      await _register(idToken);
      final session = await auth.login(email: email, password: password);
      ref.read(selectedRoleProvider.notifier).state = appRoleFromApiRole(
        session.user.role,
      );
      ref.read(authExpiredMessageProvider.notifier).state = null;
      ref.read(bottomNavVisibleProvider.notifier).state = true;
      if (!mounted) return;
      context.go(switch (session.user.role.trim().toLowerCase()) {
        'broker' => '/broker/home',
        'driver' => '/driver/home',
        _ => '/client/home',
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (_isPhoneVerificationError(error)) {
        // Expired/mismatched token: the code screen shows this and lets the
        // user verify again.
        throw OtpException(switch (error.code) {
          'PHONE_VERIFICATION_INVALID' =>
            'Verification expired. Tap "Resend code" to get a new one.',
          'PHONE_VERIFICATION_MISMATCH' =>
            'This code was for a different number. Please verify again.',
          _ => 'Please verify your number to continue.',
        });
      }
      _returnWithError(userFacingError(error));
    } catch (error) {
      if (!mounted) return;
      _returnWithError(userFacingError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Sends the user back to the step the failure most likely belongs to.
  void _returnWithError(String message) {
    final lower = message.toLowerCase();
    final truckRelated =
        _isDriver &&
        (lower.contains('truck') ||
            lower.contains('vehicle') ||
            lower.contains('registration number') ||
            lower.contains('capacity') ||
            lower.contains('insurance'));
    _goTo(truckRelated ? _SignupStep.truck : _SignupStep.details);
    _fail(message);
  }

  bool _isPhoneVerificationError(ApiException error) =>
      error.code?.startsWith('PHONE_VERIFICATION_') ?? false;

  Future<void> _pickTruckType() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Truck type',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
            for (final type in _truckTypes)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  type.label,
                  style: const TextStyle(color: _ink, fontSize: 14.5),
                ),
                subtitle: Text(
                  type.capacity,
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
                trailing: type.value == _truckCategory
                    ? const Icon(Icons.check_rounded, color: _green)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(type.value),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _truckCategory = picked;
      _capacityController.text = _capacityFor(picked);
    });
  }

  Future<void> _pickInsuranceExpiry() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _insuranceExpiry ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _green, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _insuranceExpiry = picked);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                index: _steps.indexOf(_step),
                total: _steps.length,
                onBack: _isSubmitting ? null : _back,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  reverseDuration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (current, previous) =>
                      Stack(children: [...previous, ?current]),
                  transitionBuilder: (child, animation) {
                    final isIncoming =
                        child.key == ValueKey<_SignupStep>(_step);
                    final dir = _forward == isIncoming ? 1.0 : -1.0;
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(0.06 * dir, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<_SignupStep>(_step),
                    child: _stepBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    final l10n = AppLocalizations.of(context)!;
    return switch (_step) {
      _SignupStep.details => _detailsStep(l10n),
      _SignupStep.truck => _truckStep(),
      _SignupStep.verify => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: OtpVerificationView(
              phone: _phone,
              showBadge: false,
              title: 'Verify your number',
              continuingLabel: 'Verified',
              onChangeNumber: () => _goTo(_SignupStep.details),
              onVerified: _createAccount,
            ),
          ),
        ),
      ),
    };
  }

  Widget _detailsStep(AppLocalizations l10n) {
    final subtitle = switch (widget.role) {
      AppRole.broker => 'Manage your fleet, drivers and trips in one place.',
      AppRole.driver => 'Find loads and get paid for every trip.',
      _ => 'Book trucks and track every shipment in one place.',
    };
    return _StepLayout(
      title: 'Create your account',
      subtitle: subtitle,
      error: _error,
      button: _PrimaryButton(
        label: _isDriver ? 'Continue' : 'Create account',
        loading: _isSendingOtp,
        onPressed: _submitDetails,
      ),
      below: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.signupAlreadyHaveAccount,
            style: const TextStyle(color: _muted, fontSize: 13.5),
          ),
          TextButton(
            onPressed: () => context.go(_loginPath),
            style: TextButton.styleFrom(
              foregroundColor: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.signupLoginAction,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: _ink,
              ),
            ),
          ),
        ],
      ),
      children: [
        _Field(
          label: _isBroker ? 'Owner name' : 'Full name',
          controller: _nameController,
          hint: 'Your name',
          keyboardType: TextInputType.name,
          capitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
        ),
        _Field(
          label: 'Email',
          controller: _emailController,
          hint: 'name@company.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        if (_isBroker)
          _Field(
            label: 'Business name',
            controller: _businessController,
            hint: 'Your business name',
            keyboardType: TextInputType.text,
            capitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.organizationName],
          ),
        _Field(
          label: 'Mobile number',
          controller: _phoneController,
          hint: '98765 43210',
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          prefixText: '+91',
          action: TextInputAction.next,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 1, bottom: 12),
          child: Text(
            'We\'ll text you a code to confirm this number.',
            style: TextStyle(color: _faint, fontSize: 12.5),
          ),
        ),
        _Field(
          label: 'Password',
          controller: _passwordController,
          hint: 'At least 8 characters',
          obscure: _obscurePassword,
          autofillHints: const [AutofillHints.newPassword],
          action: TextInputAction.done,
          onSubmitted: (_) => _submitDetails(),
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                _obscurePassword ? 'Show' : 'Hide',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _truckStep() {
    final type = _truckTypes.firstWhere((t) => t.value == _truckCategory);
    final expiry = _insuranceExpiry;
    return _StepLayout(
      title: 'Add your truck',
      subtitle: 'This helps brokers find and verify your vehicle.',
      error: _error,
      button: _PrimaryButton(
        label: 'Create account',
        loading: _isSendingOtp,
        onPressed: _submitTruck,
      ),
      children: [
        _Field(
          label: 'Registration number',
          controller: _registrationController,
          hint: 'MH-12-AB-1234',
          keyboardType: TextInputType.text,
          capitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]')),
            LengthLimitingTextInputFormatter(15),
            _UpperCaseFormatter(),
          ],
        ),
        _PickerField(
          label: 'Truck type',
          value: type.label,
          onTap: _pickTruckType,
          icon: Icons.keyboard_arrow_down_rounded,
        ),
        _Field(
          label: 'Capacity',
          controller: _capacityController,
          hint: 'e.g. 10 Tons',
          keyboardType: TextInputType.text,
        ),
        _Field(
          label: 'Make / model (optional)',
          controller: _makeController,
          hint: 'e.g. Tata 1109',
          keyboardType: TextInputType.text,
          capitalization: TextCapitalization.words,
        ),
        _Field(
          label: 'Year (optional)',
          controller: _yearController,
          hint: 'e.g. 2020',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          action: TextInputAction.done,
        ),
        _PickerField(
          label: 'Insurance expiry (optional)',
          value: expiry == null
              ? null
              : '${expiry.day.toString().padLeft(2, '0')}/'
                    '${expiry.month.toString().padLeft(2, '0')}/'
                    '${expiry.year}',
          hint: 'Select date',
          onTap: _pickInsuranceExpiry,
          icon: Icons.calendar_today_outlined,
        ),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Tappable field styled like [_Field], for values picked from a sheet or
/// date picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.icon,
    this.hint = '',
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: const BorderSide(color: _line),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? hint,
                        style: TextStyle(
                          color: value == null ? _faint : _ink,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(icon, size: 18, color: _muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Back arrow, hairline step markers and a step count.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.total,
    required this.onBack,
  });

  final int index;
  final int total;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 24, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(AppIcons.arrow_back_rounded, size: 22),
            color: _ink,
            tooltip: 'Back',
          ),
          const Spacer(),
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(left: 4),
              width: i == index ? 22 : 10,
              height: 3,
              decoration: BoxDecoration(
                color: i <= index ? _ink : _line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            '0${index + 1} / 0$total',
            style: const TextStyle(
              color: _faint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Heading, fields, then the button pinned to the bottom of the screen.
class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.button,
    this.below,
    this.error,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget button;
  final Widget? below;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                ),
                button,
                if (below != null) ...[const SizedBox(height: 14), below!],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.prefixText,
    this.suffix,
    this.obscure = false,
    this.action = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final Widget? suffix;
  final bool obscure;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            textInputAction: action,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            obscureText: obscure,
            onSubmitted: onSubmitted,
            cursorColor: _ink,
            cursorWidth: 1.4,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _faint, fontSize: 14),
              isDense: true,
              prefixIcon: prefixText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Text(
                        prefixText!,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: _line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: _ink, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
