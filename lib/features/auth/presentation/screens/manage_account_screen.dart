import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
          backgroundColor: Color(0xFF2FA56E),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF8),
      body: _loading
          ? const SafeArea(child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ManageAccountHeader(onBack: () => context.pop()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE4EFE8)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF101828,
                            ).withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFE23A4B)),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Center(
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SskProfileAvatar(
                                      imageUrl: profileImage,
                                      imageBytes: _pickedAvatarBytes,
                                      size: 132,
                                      borderColor: const Color(0xFF2FA56E),
                                      onTap: _pickAvatar,
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: 0,
                                      child: Material(
                                        color: const Color(0xFF2FA56E),
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          onTap: _pickAvatar,
                                          customBorder: const CircleBorder(),
                                          child: const Padding(
                                            padding: EdgeInsets.all(11),
                                            child: Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tap to choose from gallery',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF101828),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'JPG, PNG up to 5MB',
                                  style: TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            onChanged: () {
                              if (mounted) setState(() {});
                            },
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _accountFieldDecoration(
                                    labelText: 'Full name',
                                    icon: Icons.person_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter a name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _accountFieldDecoration(
                                    labelText: 'Email',
                                    icon: Icons.email_rounded,
                                  ),
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
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: _accountFieldDecoration(
                                    labelText: 'Phone',
                                    icon: Icons.phone_rounded,
                                  ).copyWith(helperText: 'Optional'),
                                ),
                                if (isBroker) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _addressController,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: _accountFieldDecoration(
                                      labelText: 'Business address',
                                      icon: Icons.location_on_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _serviceCityController,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: _accountFieldDecoration(
                                      labelText: 'Service city',
                                      icon: Icons.location_city_rounded,
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Enter the city you serve';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (user != null) ...[
                            _ActiveStatusToggle(status: user.status),
                          ],
                          if (_hasChanges) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2FA56E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
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
                                            Icons.save_rounded,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 17,
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
                ],
              ),
            ),
    );
  }
}

class _ManageAccountHeader extends StatelessWidget {
  const _ManageAccountHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF247B52), Color(0xFF2FA56E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Manage account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _accountFieldDecoration({
  required String labelText,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: Colors.white,
    prefixIcon: Icon(icon, color: const Color(0xFF2FA56E)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDCEBE2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFDCEBE2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF2FA56E), width: 1.4),
    ),
  );
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
        color: const Color(0xFFF6FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEBE2)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF2FA56E),
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
                  style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  isActive ? 'Account is active' : 'Account is inactive',
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Switch(
              value: isActive,
              onChanged: (_) {},
              activeThumbColor: const Color(0xFF2FA56E),
              activeTrackColor: const Color(0xFFCDEFD9),
              inactiveThumbColor: const Color(0xFF98A2B3),
              inactiveTrackColor: const Color(0xFFE4E7EC),
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
