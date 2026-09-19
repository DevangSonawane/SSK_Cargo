import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../data/driver_trip_handoff_utils.dart';

class DriverDeliveryPhotoUploadScreen extends ConsumerStatefulWidget {
  const DriverDeliveryPhotoUploadScreen({
    super.key,
    required this.tripId,
    this.requiresPayment = true,
  });

  final String tripId;
  final bool requiresPayment;

  @override
  ConsumerState<DriverDeliveryPhotoUploadScreen> createState() =>
      _DriverDeliveryPhotoUploadScreenState();
}

class _DriverDeliveryPhotoUploadScreenState
    extends ConsumerState<DriverDeliveryPhotoUploadScreen> {
  static const int _minMedia = 2;
  static const int _maxMedia = 6;

  final _picker = ImagePicker();
  final List<_CapturedMedia> _media = [];
  bool _uploading = false;
  bool _loadingTrip = true;
  bool _resumingFromRemoteState = false;
  String? _tripPaymentStatus;
  List<dynamic> _remotePodMedia = const [];

  int get _remoteMediaCount => _remotePodMedia.length;
  int get _totalMediaCount => _remoteMediaCount + _media.length;

  void _setTripSession({required String tripId, String? paymentStatus}) {
    final resolvedTripId = tripId.trim();
    if (resolvedTripId.isEmpty) {
      return;
    }

    final currentSession = ref.read(driverTripSessionProvider);
    ref.read(driverActiveTripIdProvider.notifier).state = resolvedTripId;
    ref.read(driverTripSessionProvider.notifier).state = DriverTripSession(
      tripId: resolvedTripId,
      bookingId: currentSession?.bookingId,
      bookingNumber: currentSession?.bookingNumber,
      status: currentSession?.status,
      paymentStatus: paymentStatus?.trim().isNotEmpty == true
          ? paymentStatus!.trim()
          : currentSession?.paymentStatus,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setTripSession(tripId: widget.tripId);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadRemoteTripState());
    });
  }

  Future<void> _loadRemoteTripState() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getTrip(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      final trip = extractTripFromResponse(response) ?? response;
      final paymentStatus = trip['paymentStatus']
          ?.toString()
          .trim()
          .toLowerCase();
      final podMedia = trip['podMedia'];
      final podPhotos = trip['podPhotos'];

      if (!mounted) return;
      setState(() {
        _tripPaymentStatus = paymentStatus;
        _remotePodMedia = podMedia is List
            ? podMedia
            : podPhotos is List
            ? podPhotos
            : const [];
        _loadingTrip = false;
      });
      _setTripSession(tripId: widget.tripId, paymentStatus: paymentStatus);

      if (_remoteMediaCount >= _minMedia && !_resumingFromRemoteState) {
        _resumingFromRemoteState = true;
        if (!mounted) return;
        if (!const {'pending', 'partial'}.contains(paymentStatus)) {
          context.go('/driver/thank-you/${widget.tripId}');
        } else {
          context.go('/driver/payment/${widget.tripId}');
        }
      }
    } on ApiException {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_totalMediaCount >= _maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can add up to 6 proof-of-delivery items.'),
        ),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _media.add(
          _CapturedMedia(
            bytes: bytes,
            fileName: picked.name,
            type: _PodMediaType.image,
          ),
        );
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

  Future<void> _pickVideo() async {
    if (_totalMediaCount >= _maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can add up to 6 proof-of-delivery items.'),
        ),
      );
      return;
    }

    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _media.add(
          _CapturedMedia(
            bytes: bytes,
            fileName: picked.name,
            type: _PodMediaType.video,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open video camera: $error'),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    }
  }

  Future<void> _submitPhotos() async {
    if (_totalMediaCount < _minMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add at least ${_minMedia - _totalMediaCount} more proof-of-delivery item(s).',
          ),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to upload delivery photos.'),
        ),
      );
      return;
    }
    if (_media.isEmpty) {
      if (_tripPaymentStatus == 'paid') {
        await ref
            .read(apiClientProvider)
            .completeTrip(
              accessToken: session.tokens.accessToken,
              tripId: widget.tripId,
            );
        if (!mounted) return;
        context.go('/driver/thank-you/${widget.tripId}');
      } else {
        context.go('/driver/payment/${widget.tripId}');
      }
      return;
    }

    setState(() => _uploading = true);

    try {
      final files = _media
          .map(
            (item) =>
                MultipartFile.fromBytes(item.bytes, filename: item.fileName),
          )
          .toList(growable: false);

      await ref
          .read(apiClientProvider)
          .uploadTripPod(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
            files: files,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_media.length} proof-of-delivery item(s) uploaded successfully.',
          ),
          backgroundColor: const Color(0xFF2FA56E),
        ),
      );

      await _loadRemoteTripState();
      if (!mounted) return;

      if (_tripPaymentStatus == 'paid') {
        await ref
            .read(apiClientProvider)
            .completeTrip(
              accessToken: session.tokens.accessToken,
              tripId: widget.tripId,
            );
        if (!mounted) return;
        context.go('/driver/thank-you/${widget.tripId}');
      } else {
        context.go('/driver/payment/${widget.tripId}');
      }
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
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _totalMediaCount >= _minMedia && !_uploading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Upload proof'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            if (_loadingTrip) ...[
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Color(0xFFE8EDF2),
                color: Color(0xFF1F88C9),
              ),
              const SizedBox(height: 12),
            ],
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
                            AppIcons.receipt_long_rounded,
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
                    media: _media,
                    remoteCount: _remoteMediaCount,
                    maxMedia: _maxMedia,
                    onAddFromGallery: _uploading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    onAddFromCamera: _uploading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    onAddVideo: _uploading ? null : _pickVideo,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$_totalMediaCount of $_maxMedia photos/videos added',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_totalMediaCount < _minMedia) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Add at least ${_minMedia - _totalMediaCount} more to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB54708),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: canSubmit ? _submitPhotos : null,
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
                                'Submit proof',
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
    required this.media,
    required this.remoteCount,
    required this.maxMedia,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
    required this.onAddVideo,
  });

  final List<_CapturedMedia> media;
  final int remoteCount;
  final int maxMedia;
  final VoidCallback? onAddFromGallery;
  final VoidCallback? onAddFromCamera;
  final VoidCallback? onAddVideo;

  @override
  Widget build(BuildContext context) {
    final canAddMore = remoteCount + media.length < maxMedia;
    final tiles = <Widget>[
      for (var i = 0; i < remoteCount; i++) const _RemoteMediaTile(),
      for (final item in media)
        _PhotoTile(media: item, onTap: onAddFromGallery),
      if (canAddMore)
        _AddPhotoTile(
          onGalleryTap: onAddFromGallery,
          onCameraTap: onAddFromCamera,
          onVideoTap: onAddVideo,
        ),
    ];

    if (tiles.isEmpty) {
      return _AddPhotoTile(
        onGalleryTap: onAddFromGallery,
        onCameraTap: onAddFromCamera,
        onVideoTap: onAddVideo,
        isEmptyState: true,
      );
    }

    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.media, this.onTap});

  final _CapturedMedia media;
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
              if (media.type == _PodMediaType.image)
                Image.memory(media.bytes, fit: BoxFit.cover)
              else
                Container(
                  color: const Color(0xFF101828),
                  child: const Center(
                    child: Icon(
                      AppIcons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
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
                  media.fileName,
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
  const _AddPhotoTile({
    required this.onGalleryTap,
    required this.onCameraTap,
    required this.onVideoTap,
    this.isEmptyState = false,
  });

  final VoidCallback? onGalleryTap;
  final VoidCallback? onCameraTap;
  final VoidCallback? onVideoTap;
  final bool isEmptyState;

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(AppIcons.photo_camera_rounded),
                  title: const Text('Take photo'),
                  onTap: onCameraTap == null
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          onCameraTap!();
                        },
                ),
                ListTile(
                  leading: const Icon(AppIcons.videocam_rounded),
                  title: const Text('Record video'),
                  onTap: onVideoTap == null
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          onVideoTap!();
                        },
                ),
                ListTile(
                  leading: const Icon(AppIcons.photo_library_rounded),
                  title: const Text('Choose photo'),
                  onTap: onGalleryTap == null
                      ? null
                      : () {
                          Navigator.of(sheetContext).pop();
                          onGalleryTap!();
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEmptyState ? null : () => _showSourceSheet(context),
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: isEmptyState ? 220 : 104,
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
              child: isEmptyState
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MediaPickButton(
                          icon: AppIcons.photo_camera_rounded,
                          label: 'Photo',
                          onTap: onCameraTap,
                        ),
                        const SizedBox(width: 10),
                        _MediaPickButton(
                          icon: AppIcons.videocam_rounded,
                          label: 'Video',
                          onTap: onVideoTap,
                        ),
                        const SizedBox(width: 10),
                        _MediaPickButton(
                          icon: AppIcons.photo_library_rounded,
                          label: 'Gallery',
                          onTap: onGalleryTap,
                        ),
                      ],
                    )
                  : Column(
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
                            AppIcons.add_rounded,
                            color: Color(0xFF1F88C9),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'More',
                          style: TextStyle(
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

class _RemoteMediaTile extends StatelessWidget {
  const _RemoteMediaTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7F0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFCDEFD9)),
        ),
        child: const Center(
          child: Icon(
            AppIcons.check_circle_rounded,
            color: Color(0xFF2FA56E),
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _MediaPickButton extends StatelessWidget {
  const _MediaPickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1F88C9), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1F88C9),
                fontSize: 10,
                fontWeight: FontWeight.w800,
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

enum _PodMediaType { image, video }

class _CapturedMedia {
  const _CapturedMedia({
    required this.bytes,
    required this.fileName,
    required this.type,
  });

  final Uint8List bytes;
  final String fileName;
  final _PodMediaType type;
}
