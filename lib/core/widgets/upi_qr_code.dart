import 'package:flutter/material.dart';
import 'package:qr/qr.dart' as qr;

/// Renders a QR code for [data] on-device — web parity with the driver app's
/// `QRCode.toDataURL(upiUrl, { width: 220, margin: 1 })`, so the collect
/// payment QR never depends on a third-party image service being reachable.
class UpiQrCode extends StatelessWidget {
  const UpiQrCode({super.key, required this.data, this.size = 196});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    qr.QrImage? image;
    try {
      image = qr.QrImage(
        qr.QrCode.fromData(
          data: data,
          errorCorrectLevel: qr.QrErrorCorrectLevel.M,
        ),
      );
    } catch (_) {
      image = null;
    }
    if (image == null) {
      return SizedBox.square(
        dimension: size,
        child: const Center(
          child: Icon(Icons.qr_code_2_rounded, size: 56, color: Colors.grey),
        ),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _QrPainter(image)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image);

  final qr.QrImage image;

  // One quiet-zone module on each side, matching the web's `margin: 1`.
  static const int _margin = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final count = image.moduleCount + _margin * 2;
    final cell = size.shortestSide / count;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final dark = Paint()
      ..color = Colors.black
      ..isAntiAlias = false;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        if (!image.isDark(row, col)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (col + _margin) * cell,
            (row + _margin) * cell,
            // Slight overlap avoids hairline gaps between modules.
            cell + 0.5,
            cell + 0.5,
          ),
          dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) => oldDelegate.image != image;
}
