import 'package:flutter/material.dart';
import '../theme/holo_theme.dart';

class BitStreamPainter extends CustomPainter {
  final String binary;
  BitStreamPainter(this.binary);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    if (binary.isEmpty || binary == 'Awaiting encoding...') return;
    final paint = Paint()..color = HoloTheme.cyan;
    final bitsToShow = (size.width / 4).floor();
    for (int i = 0; i < bitsToShow && i < binary.length; i++) {
      final x = i * 4.0;
      final bit = binary[i] == '1';
      final y = bit ? 2.0 : size.height / 2 + 2;
      final h = size.height / 2 - 4;
      canvas.drawRect(Rect.fromLTWH(x, y, 2, h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
