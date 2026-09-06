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
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  String _originalName = '';
  String _originalEmail = '';
  String _originalPhone = '';
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
    super.dispose();
  }

  bool get _hasChanges {
    final nameChanged = _nameController.text.trim() != _originalName.trim();
    final emailChanged = _emailController.text.trim() != _originalEmail.trim();
    final phoneChanged = _phoneController.text.trim() != _originalPhone.trim();
    final imageChanged = _pickedAvatarBytes != null;
    return nameChanged || emailChanged || phoneChanged || imageChanged;
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
      _originalProfileImage = user.profileImage;
      _nameController.text = _originalName;
      _emailController.text = _originalEmail;
      _phoneController.text = _originalPhone;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
          );

      if (!mounted) return;

      setState(() {
        _originalName = saved.user.displayName;
        _originalEmail = saved.user.email ?? '';
        _originalPhone = saved.user.phone;
        _originalProfileImage = saved.user.profileImage;
        _nameController.text = _originalName;
        _emailController.text = _originalEmail;
        _phoneController.text = _originalPhone;
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
    final profileImage = _pickedAvatarBytes != null
        ? null
        : (_originalProfileImage ?? user?.profileImage);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8FF),
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
                        border: Border.all(color: const Color(0xFFDCEAFF)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1769D1,
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
                                      borderColor: const Color(0xFF1769D1),
                                      onTap: _pickAvatar,
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: 0,
                                      child: Material(
                                        color: const Color(0xFF1769D1),
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
                                        color: const Color(0xFF10245B),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'JPG, PNG up to 5MB',
                                  style: TextStyle(
                                    color: Color(0xFF5B6B91),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (user != null) ...[
                            const Text(
                              'Optional',
                              style: TextStyle(
                                color: Color(0xFF60708D),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(label: 'Role', value: user.role),
                            _DetailRow(label: 'Status', value: user.status),
                          ],
                          if (_hasChanges) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1769D1),
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
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF075FC7), Color(0xFF147FE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
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
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Manage account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
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
    prefixIcon: Icon(icon, color: const Color(0xFF1769D1)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD6E6FA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD6E6FA)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFF1769D1), width: 1.4),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEAFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFE3F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              label == 'Role'
                  ? Icons.work_rounded
                  : Icons.verified_user_rounded,
              color: const Color(0xFF1769D1),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF5B6B91),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF10245B),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_rounded, color: Color(0xFF1769D1), size: 20),
        ],
      ),
    );
  }
}
