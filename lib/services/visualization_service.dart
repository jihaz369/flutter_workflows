import 'dart:math';
import 'dart:typed_data';

class VisualizationService {
  static List<double> fft(Float32List samples) {
    final n = samples.length;
    if (n <= 1) return samples.map((s) => s.toDouble()).toList();
    int paddedN = 1;
    while (paddedN < n) paddedN <<= 1;
    final real = Float64List(paddedN);
    final imag = Float64List(paddedN);
    for (int i = 0; i < n; i++) real[i] = samples[i];
    _fftRecursive(real, imag, paddedN);
    final magnitudes = List<double>.filled(paddedN ~/ 2, 0);
    for (int i = 0; i < paddedN ~/ 2; i++) {
      magnitudes[i] = sqrt(real[i] * real[i] + imag[i] * imag[i]);
    }
    return magnitudes;
  }

  static void _fftRecursive(Float64List real, Float64List imag, int n) {
    if (n <= 1) return;
    final half = n ~/ 2;
    final evenReal = Float64List(half);
    final evenImag = Float64List(half);
    final oddReal = Float64List(half);
    final oddImag = Float64List(half);
    for (int i = 0; i < half; i++) {
      evenReal[i] = real[i * 2];
      evenImag[i] = imag[i * 2];
      oddReal[i] = real[i * 2 + 1];
      oddImag[i] = imag[i * 2 + 1];
    }
    _fftRecursive(evenReal, evenImag, half);
    _fftRecursive(oddReal, oddImag, half);
    for (int k = 0; k < half; k++) {
      final angle = -2 * pi * k / n;
      final cosAngle = cos(angle);
      final sinAngle = sin(angle);
      final tReal = cosAngle * oddReal[k] - sinAngle * oddImag[k];
      final tImag = sinAngle * oddReal[k] + cosAngle * oddImag[k];
      real[k] = evenReal[k] + tReal;
      imag[k] = evenImag[k] + tImag;
      real[k + half] = evenReal[k] - tReal;
      imag[k + half] = evenImag[k] - tImag;
    }
  }

  static List<(double, double)> extractConstellation(
    Float32List samples,
    String modulation,
    int sampleRate,
    int centerFreq,
    int symbolRate,
  ) {
    final points = <(double, double)>[];
    final samplesPerSymbol = (sampleRate / symbolRate).floor();
    final numSymbols = (samples.length / samplesPerSymbol).floor();
    for (int i = 0; i < numSymbols && i < 200; i++) {
      final start = i * samplesPerSymbol;
      final end = start + samplesPerSymbol;
      if (end > samples.length) break;
      double iEnergy = 0, qEnergy = 0;
      for (int s = start; s < end; s++) {
        final t = s / sampleRate;
        iEnergy += samples[s] * cos(2 * pi * centerFreq * t);
        qEnergy += samples[s] * sin(2 * pi * centerFreq * t);
      }
      final magnitude = sqrt(iEnergy * iEnergy + qEnergy * qEnergy) / samplesPerSymbol;
      final phase = atan2(qEnergy, iEnergy);
      points.add((magnitude * cos(phase), magnitude * sin(phase)));
    }
    return points;
  }

  static List<double> toDb(List<double> magnitudes, {double minDb = -80}) {
    return magnitudes.map((m) {
      final db = 20 * log(m + 1e-10) / ln10;
      return db < minDb ? minDb : db;
    }).toList();
  }
}
