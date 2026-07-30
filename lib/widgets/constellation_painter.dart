import 'package:flutter/material.dart';
import '../theme/holo_theme.dart';

class ConstellationPainter extends CustomPainter {
  final List<(double, double)> points;
  ConstellationPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final axisPaint = Paint()
      ..color = HoloTheme.dimCyan.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), axisPaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), axisPaint);
    final pointPaint = Paint()
      ..color = HoloTheme.green
      ..style = PaintingStyle.fill;
    for (final (x, y) in points) {
      final px = size.width / 2 + x * 40;
      final py = size.height / 2 - y * 40;
      canvas.drawCircle(Offset(px, py), 6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
