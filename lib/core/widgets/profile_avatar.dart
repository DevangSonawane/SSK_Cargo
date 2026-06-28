import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class SskProfileAvatar extends StatelessWidget {
  const SskProfileAvatar({
    super.key,
    required this.imageUrl,
    this.imageBytes,
    this.onTap,
    this.size = 72,
    this.fallbackAsset = 'assets/user.png',
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final VoidCallback? onTap;
  final double size;
  final String fallbackAsset;

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
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5EAF0), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      return Image.memory(imageBytes!, fit: BoxFit.cover);
    }

    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) {
      return Image.asset(fallbackAsset, fit: BoxFit.cover);
    }

    if (value.startsWith('data:image/')) {
      final commaIndex = value.indexOf(',');
      if (commaIndex > 0) {
        try {
          final encoded = value.substring(commaIndex + 1);
          return Image.memory(base64Decode(encoded), fit: BoxFit.cover);
        } catch (_) {
          return Image.asset(fallbackAsset, fit: BoxFit.cover);
        }
      }
      return Image.asset(fallbackAsset, fit: BoxFit.cover);
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(fallbackAsset, fit: BoxFit.cover);
        },
      );
    }

    return Image.asset(fallbackAsset, fit: BoxFit.cover);
  }
}
