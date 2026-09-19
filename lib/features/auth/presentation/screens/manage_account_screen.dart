import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../controllers/auth_controller.dart';

class ManageAccountScreen extends ConsumerStatefulWidget {
  const ManageAccountScreen({super.key});

  @override
  ConsumerState<ManageAccountScreen> createState() =>
      _ManageAccountScreenState();
}

class _ManageAccountScreenState extends ConsumerState<ManageAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _serviceCityController = TextEditingController();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  String _originalName = '';
  String _originalEmail = '';
  String _originalPhone = '';
  String _originalAddress = '';
  String _originalServiceCity = '';
  String? _originalProfileImage;
  Uint8List? _pickedAvatarBytes;
  String? _pickedAvatarDataUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _serviceCityController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    final nameChanged = _nameController.text.trim() != _originalName.trim();
    final emailChanged = _emailController.text.trim() != _originalEmail.trim();
    final phoneChanged = _phoneController.text.trim() != _originalPhone.trim();
    final addressChanged =
        _addressController.text.trim() != _originalAddress.trim();
    final serviceCityChanged =
        _serviceCityController.text.trim() != _originalServiceCity.trim();
    final imageChanged = _pickedAvatarBytes != null;
    return nameChanged ||
        emailChanged ||
        phoneChanged ||
        addressChanged ||
        serviceCityChanged ||
        imageChanged;
  }

  String _mimeTypeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _buildDataUrl(Uint8List bytes, String name) {
    final mimeType = _mimeTypeForName(name);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  Future<void> _loadProfile() async {
    try {
      final session = await ref
          .read(authSessionProvider.notifier)
          .refreshProfile();
      final user = session.user;
      _originalName = user.displayName;
      _originalEmail = user.email ?? '';
      _originalPhone = user.phone;
      _originalAddress = user.address;
      _originalProfileImage = user.profileImage;
      _nameController.text = _originalName;
      _emailController.text = _originalEmail;
      _phoneController.text = _originalPhone;
      _addressController.text = _originalAddress;
      if (user.role.toLowerCase() == 'broker') {
        await _loadBrokerProfile(session.tokens.accessToken);
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadBrokerProfile(String accessToken) async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBrokerProfile(accessToken: accessToken);
      final data = _asMap(response['data']);
      final profile = _asMap(data['profile']).isNotEmpty
          ? _asMap(data['profile'])
          : data;
      final serviceCity = _readString(profile, const [
        'serviceCity',
        'service_city',
        'city',
      ]);
      if (!mounted) {
        return;
      }
      _originalServiceCity = serviceCity;
      _serviceCityController.text = serviceCity;
    } catch (error) {
      developer.log(
        'Broker profile extras unavailable: $error',
        name: 'SSK.Auth',
      );
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pickedAvatarBytes = bytes;
      _pickedAvatarDataUrl = _buildDataUrl(bytes, picked.name);
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);
    try {
      developer.log(
        'Saving profile from manage account page',
        name: 'SSK.Auth',
      );
      final saved = await ref
          .read(authSessionProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            profileImage: _pickedAvatarDataUrl ?? _originalProfileImage,
            address: _addressController.text.trim(),
          );
      if (saved.user.role.toLowerCase() == 'broker') {
        final city = _serviceCityController.text.trim();
        await ref
            .read(apiClientProvider)
            .updateBrokerServiceCity(
              accessToken: saved.tokens.accessToken,
              city: city,
            );
      }

      if (!mounted) return;

      setState(() {
        _originalName = saved.user.displayName;
        _originalEmail = saved.user.email ?? '';
        _originalPhone = saved.user.phone;
        _originalAddress = _addressController.text.trim();
        _originalServiceCity = _serviceCityController.text.trim();
        _originalProfileImage = saved.user.profileImage;
        _nameController.text = _originalName;
        _emailController.text = _originalEmail;
        _phoneController.text = _originalPhone;
        _addressController.text = _originalAddress;
        _pickedAvatarBytes = null;
        _pickedAvatarDataUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.brand,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.user;
    final isBroker = user?.role.toLowerCase() == 'broker';
    final profileImage = _pickedAvatarBytes != null
        ? null
        : (_originalProfileImage ?? user?.profileImage);

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (user?.displayName.trim().isNotEmpty == true
              ? user!.displayName.trim()
              : 'Your name');
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (user?.email?.trim().isNotEmpty == true ? user!.email! : '');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(onBack: () => context.pop()),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _IdentityCard(
                        name: name,
                        email: email,
                        imageUrl: profileImage,
                        imageBytes: _pickedAvatarBytes,
                        onPick: _pickAvatar,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _InlineError(message: _errorMessage!),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.brandBorder),
                        ),
                        child: Form(
                          key: _formKey,
                          onChanged: () {
                            if (mounted) setState(() {});
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionLabel(text: 'Basic details'),
                              const SizedBox(height: 14),
                              _ProfileTextField(
                                label: 'Full name',
                                icon: AppIcons.person_rounded,
                                controller: _nameController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter a name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _ProfileTextField(
                                label: 'Email',
                                icon: AppIcons.email_rounded,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter an email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _ProfileTextField(
                                label: 'Phone',
                                icon: AppIcons.phone_rounded,
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                optional: true,
                              ),
                              if (isBroker) ...[
                                const SizedBox(height: 20),
                                const _SectionLabel(text: 'Business details'),
                                const SizedBox(height: 14),
                                _ProfileTextField(
                                  label: 'Business address',
                                  icon: AppIcons.location_on_rounded,
                                  controller: _addressController,
                                  minLines: 2,
                                  maxLines: 4,
                                ),
                                const SizedBox(height: 14),
                                _ProfileTextField(
                                  label: 'Service city',
                                  icon: AppIcons.location_city_rounded,
                                  controller: _serviceCityController,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Enter the city you serve';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 18),
                              if (user != null) ...[
                                _ActiveStatusToggle(status: user.status),
                              ],
                              if (_hasChanges) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _saving ? null : _save,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.brand,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.button,
                                        ),
                                      ),
                                    ),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                AppIcons.save_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Save Changes',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              AppIcons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Account details & photo',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onPick,
    this.imageBytes,
  });

  final String name;
  final String email;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SskProfileAvatar(
                  imageUrl: imageUrl,
                  imageBytes: imageBytes,
                  size: 104,
                  borderColor: Colors.white,
                  onTap: onPick,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.brand,
                    child: Icon(
                      AppIcons.camera_alt_outlined,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Material(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.camera_alt_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Change Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textHeading,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType,
    this.validator,
    this.optional = false,
    this.minLines,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool optional;
  final int? minLines;
  final int? maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              const Text(
                '(optional)',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEDF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF98A2B3)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  minLines: minLines,
                  maxLines: maxLines,
                  textCapitalization: textCapitalization,
                  validator: validator,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF101828),
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    fillColor: Colors.transparent,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF98A2B3),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerFill,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.error_outline_rounded,
            size: 18,
            color: AppColors.dangerIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.dangerText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveStatusToggle extends StatelessWidget {
  const _ActiveStatusToggle({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.trim().toLowerCase() == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.brandFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.verified_user_rounded,
              color: AppColors.brand,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isActive ? 'Account is active' : 'Account is inactive',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Switch(
              value: isActive,
              onChanged: (_) {},
              activeThumbColor: AppColors.brand,
              activeTrackColor: AppColors.brandBorder,
              inactiveThumbColor: AppColors.textTertiary,
              inactiveTrackColor: AppColors.line,
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}
