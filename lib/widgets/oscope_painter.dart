import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../theme/holo_theme.dart';

class OscopePainter extends CustomPainter {
  final Float32List samples;
  OscopePainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    if (samples.isEmpty) return;
    final paint = Paint()
      ..color = HoloTheme.green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    final step = samples.length ~/ size.width.toInt();
    final s = step < 1 ? 1 : step;
    for (int i = 0; i < size.width.toInt() && i * s < samples.length; i++) {
      final x = i.toDouble();
      final y = size.height / 2 + samples[i * s] * size.height / 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
