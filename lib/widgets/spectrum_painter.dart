import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:typed_data';
import '../services/visualization_service.dart';
import '../theme/holo_theme.dart';

class SpectrumPainter extends CustomPainter {
  final Float32List samples;
  final int sampleRate;
  SpectrumPainter(this.samples, this.sampleRate);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    if (samples.isEmpty) return;
    final fftSize = 512;
    final fftData = samples.length > fftSize
      ? Float32List.sublistView(samples, 0, fftSize)
      : samples;
    final magnitudes = VisualizationService.fft(fftData);
    final dbValues = VisualizationService.toDb(magnitudes);
    final paint = Paint()
      ..color = HoloTheme.cyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    final binWidth = size.width / dbValues.length;
    for (int i = 0; i < dbValues.length; i++) {
      final normalized = (dbValues[i] + 80) / 80;
      final x = i * binWidth;
      final y = size.height - (normalized.clamp(0, 1) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    final gridPaint = Paint()
      ..color = HoloTheme.grid
      ..strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
