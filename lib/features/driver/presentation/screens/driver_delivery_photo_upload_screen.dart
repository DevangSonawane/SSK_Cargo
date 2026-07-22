import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class DriverDeliveryPhotoUploadScreen extends StatefulWidget {
  const DriverDeliveryPhotoUploadScreen({
    super.key,
    required this.tripId,
    this.requiresPayment = true,
  });

  final String tripId;
  final bool requiresPayment;

  @override
  State<DriverDeliveryPhotoUploadScreen> createState() =>
      _DriverDeliveryPhotoUploadScreenState();
}

class _DriverDeliveryPhotoUploadScreenState
    extends State<DriverDeliveryPhotoUploadScreen> {
  static const int _maxPhotos = 6;

  final _picker = ImagePicker();
  final List<_CapturedPhoto> _photos = [];
  bool _uploading = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 6 delivery photos.')),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photos.add(_CapturedPhoto(bytes: bytes, fileName: picked.name));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open image picker: $error'),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    }
  }

  Future<void> _submitPhotos() async {
    if (_photos.isEmpty) return;

    setState(() => _uploading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_photos.length} delivery photo(s) uploaded successfully.',
        ),
        backgroundColor: const Color(0xFF2FA56E),
      ),
    );
    context.go('/driver/payment/${widget.tripId}');
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = _photos.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Upload picture'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EDF2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pillMaxWidth = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : MediaQuery.sizeOf(context).width - 80;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FB),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFBFD4EA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 15,
                            color: Color(0xFF1F88C9),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.max(0, pillMaxWidth - 42),
                            ),
                            child: Text(
                              widget.tripId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PhotoGrid(
                    photos: _photos,
                    maxPhotos: _maxPhotos,
                    onAddFromGallery: _uploading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    onAddFromCamera: _uploading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${_photos.length} of $_maxPhotos photos added',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: hasPhotos && !_uploading
                          ? _submitPhotos
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F88C9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _uploading
                            ? const SizedBox(
                                key: ValueKey('uploading'),
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                key: ValueKey('submit'),
                                'Submit photos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.photos,
    required this.maxPhotos,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
  });

  final List<_CapturedPhoto> photos;
  final int maxPhotos;
  final VoidCallback? onAddFromGallery;
  final VoidCallback? onAddFromCamera;

  @override
  Widget build(BuildContext context) {
    final canAddMore = photos.length < maxPhotos;
    final tiles = <Widget>[
      for (final photo in photos)
        _PhotoTile(photo: photo, onTap: onAddFromGallery),
      if (canAddMore) _AddPhotoTile(onCameraTap: onAddFromCamera),
    ];

    if (tiles.isEmpty) {
      return _AddPhotoTile(onCameraTap: onAddFromCamera, isEmptyState: true);
    }

    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, this.onTap});

  final _CapturedPhoto photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 104,
        height: 104,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(photo.bytes, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  photo.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
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

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onCameraTap, this.isEmptyState = false});

  final VoidCallback? onCameraTap;
  final bool isEmptyState;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCameraTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedRoundedRectPainter(
                  color: const Color(0xFFBFD4EA),
                  strokeWidth: 2,
                  dashWidth: 7,
                  dashSpace: 5,
                  radius: 22,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFF1F88C9),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEmptyState ? 'Add photo' : 'More',
                    style: const TextStyle(
                      color: Color(0xFF1F88C9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}

class _CapturedPhoto {
  const _CapturedPhoto({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}
