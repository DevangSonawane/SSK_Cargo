import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';

class SskProfileAvatar extends StatelessWidget {
  const SskProfileAvatar({
    super.key,
    required this.imageUrl,
    this.imageBytes,
    this.onTap,
    this.size = 72,
    this.fallbackAsset = 'assets/user.png',
    this.borderColor = const Color(0xFFE5EAF0),
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback? onTap;
  final double size;
  final String fallbackAsset;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final child = _buildImage();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Platform-style placeholder (same as broker): neutral slate disc with a
  /// dark person glyph — no brand color, lets the photo be the identity.
  Widget _placeholder() {
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFFE8EDF3),
      child: Icon(
        AppIcons.person_rounded,
        color: const Color(0xFF475569),
        size: size * 0.55,
      ),
    );
  }

  Widget _buildImage() {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(imageBytes!, fit: BoxFit.cover);
    }

    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) {
      return _placeholder();
    }

    if (value.startsWith('data:image/')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex > 0) {
        try {
          final encoded = value.substring(commaIndex + 1);
          return Image.memory(base64Decode(encoded), fit: BoxFit.cover);
        } catch (_) {
          return _placeholder();
        }
      }
      return _placeholder();
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
      );
    }

    return _placeholder();
  }
}
