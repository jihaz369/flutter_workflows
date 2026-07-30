import 'dart:math';
import 'dart:typed_data';

/// Demodulation service for various modulation schemes
class DemodulationService {
  static final _random = Random();

  /// Demodulate PCM samples back to binary string
  static String demodulate({
    required Float32List samples,
    required String modulation,
    required int sampleRate,
    required int centerFreq,
    required int symbolRate,
  }) {
    final samplesPerSymbol = (sampleRate / symbolRate).floor();
    final numSymbols = (samples.length / samplesPerSymbol).floor();
    final bits = StringBuffer();

    for (int i = 0; i < numSymbols; i++) {
      final start = i * samplesPerSymbol;
      final end = start + samplesPerSymbol;
      final symbolSamples = samples.sublist(start, end > samples.length ? samples.length : end);

      final symbolBits = _demodulateSymbol(
        symbolSamples: symbolSamples,
        modulation: modulation,
        sampleRate: sampleRate,
        centerFreq: centerFreq,
        symbolRate: symbolRate,
      );
      bits.write(symbolBits);
    }

    return bits.toString();
  }

  static String _demodulateSymbol({
    required List<double> symbolSamples,
    required String modulation,
    required int sampleRate,
    required int centerFreq,
    required int symbolRate,
  }) {
    switch (modulation) {
      case 'fsk2':
        return _demodulateFsk2(symbolSamples, sampleRate, centerFreq);
      case 'fsk4':
        return _demodulateFsk4(symbolSamples, sampleRate, centerFreq);
      case 'bpsk':
        return _demodulateBpsk(symbolSamples, sampleRate, centerFreq);
      case 'qpsk':
        return _demodulateQpsk(symbolSamples, sampleRate, centerFreq);
      case 'ook':
        return _demodulateOok(symbolSamples, sampleRate, centerFreq);
      default:
        return _demodulateFsk2(symbolSamples, sampleRate, centerFreq);
    }
  }

  static String _demodulateFsk2(List<double> samples, int sampleRate, int centerFreq) {
    double energyMark = 0;
    double energySpace = 0;

    for (int i = 0; i < samples.length; i++) {
      final t = i / sampleRate;
      final mark = sin(2 * pi * (centerFreq + 500) * t);
      final space = sin(2 * pi * (centerFreq - 500) * t);
      energyMark += samples[i] * mark;
      energySpace += samples[i] * space;
    }

    return energyMark > energySpace ? '1' : '0';
  }

  static String _demodulateFsk4(List<double> samples, int sampleRate, int centerFreq) {
    final freqs = [-750, -250, 250, 750];
    double maxEnergy = -1;
    int bestIdx = 0;

    for (int f = 0; f < 4; f++) {
      double energy = 0;
      for (int i = 0; i < samples.length; i++) {
        final t = i / sampleRate;
        final ref = sin(2 * pi * (centerFreq + freqs[f]) * t);
        energy += samples[i] * ref;
      }
      if (energy > maxEnergy) {
        maxEnergy = energy;
        bestIdx = f;
      }
    }

    return bestIdx.toRadixString(2).padLeft(2, '0');
  }

  static String _demodulateBpsk(List<double> samples, int sampleRate, int centerFreq) {
    double iEnergy = 0;
    double qEnergy = 0;

    for (int i = 0; i < samples.length; i++) {
      final t = i / sampleRate;
      final iRef = cos(2 * pi * centerFreq * t);
      final qRef = sin(2 * pi * centerFreq * t);
      iEnergy += samples[i] * iRef;
      qEnergy += samples[i] * qRef;
    }

    final phase = atan2(qEnergy, iEnergy);
    return phase.abs() > pi / 2 ? '1' : '0';
  }

  static String _demodulateQpsk(List<double> samples, int sampleRate, int centerFreq) {
    double iEnergy = 0;
    double qEnergy = 0;

    for (int i = 0; i < samples.length; i++) {
      final t = i / sampleRate;
      final iRef = cos(2 * pi * centerFreq * t);
      final qRef = sin(2 * pi * centerFreq * t);
      iEnergy += samples[i] * iRef;
      qEnergy += samples[i] * qRef;
    }

    final phase = atan2(qEnergy, iEnergy);
    final normalized = ((phase + 2 * pi) % (2 * pi)) / (pi / 2);
    final symbol = (normalized + 0.5).floor() % 4;
    return symbol.toRadixString(2).padLeft(2, '0');
  }

  static String _demodulateOok(List<double> samples, int sampleRate, int centerFreq) {
    double energy = 0;
    for (int i = 0; i < samples.length; i++) {
      final t = i / sampleRate;
      final ref = sin(2 * pi * centerFreq * t);
      energy += samples[i] * ref;
    }
    return energy.abs() > 0.1 ? '1' : '0';
  }

  /// Simple threshold decoder (fallback for noisy signals)
  static String thresholdDecode(Float32List samples, {int step = 1}) {
    final bits = StringBuffer();
    for (int i = 0; i < samples.length; i += step) {
      bits.write(samples[i] > 0 ? '1' : '0');
    }
    return bits.toString();
  }
}
