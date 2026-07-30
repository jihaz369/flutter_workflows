import 'dart:math';
import 'dart:typed_data';

class ModulationService {
  static final _random = Random();

  static Float32List modulate({
    required String binary,
    required String modulation,
    required int sampleRate,
    required int centerFreq,
    required int symbolRate,
    required double volume,
    double noiseLevel = 0.0,
  }) {
    final samplesPerSymbol = (sampleRate / symbolRate).floor();
    final totalSamples = binary.length * samplesPerSymbol;
    final samples = Float32List(totalSamples);

    for (int i = 0; i < binary.length; i++) {
      final symbol = _getSymbol(binary, i, modulation, centerFreq);

      for (int s = 0; s < samplesPerSymbol; s++) {
        final t = (i * samplesPerSymbol + s) / sampleRate;
        double sample = _generateSample(
          symbol: symbol,
          modulation: modulation,
          time: t,
          centerFreq: centerFreq,
          symbolRate: symbolRate,
          bitIndex: i,
        );

        sample *= volume;
        if (noiseLevel > 0) {
          sample += (_random.nextDouble() * 2 - 1) * noiseLevel;
        }
        samples[i * samplesPerSymbol + s] = sample.clamp(-1.0, 1.0);
      }
    }

    return samples;
  }

  static SymbolData _getSymbol(String binary, int index, String modulation, int centerFreq) {
    switch (modulation) {
      case 'fsk2':
      case 'ook':
      case 'ask':
        final bit = index < binary.length ? int.parse(binary[index]) : 0;
        return SymbolData(freq: bit, phase: 0.0, amplitude: bit == 1 ? 1.0 : (modulation == 'ook' ? 0.0 : 0.3));

      case 'fsk4':
        final bits = _getBits(binary, index, 2);
        final freqs = [-750, -250, 250, 750];
        return SymbolData(freq: centerFreq + freqs[bits], phase: 0.0, amplitude: 1.0);

      case 'fsk8':
        final bits = _getBits(binary, index, 3);
        final freqs = [-875, -625, -375, -125, 125, 375, 625, 875];
        return SymbolData(freq: centerFreq + freqs[bits], phase: 0.0, amplitude: 1.0);

      case 'fsk16':
        final bits = _getBits(binary, index, 4);
        final freqs = List.generate(16, (i) => -937 + (i * 125));
        return SymbolData(freq: centerFreq + freqs[bits], phase: 0.0, amplitude: 1.0);

      case 'bpsk':
      case 'dbpsk':
        final bit = index < binary.length ? int.parse(binary[index]) : 0;
        return SymbolData(freq: centerFreq, phase: bit * pi, amplitude: 1.0);

      case 'qpsk':
      case 'dqpsk':
        final bits = _getBits(binary, index, 2);
        final phases = [0.0, pi / 2, pi, 3 * pi / 2];
        return SymbolData(freq: centerFreq, phase: phases[bits], amplitude: 1.0);

      case 'psk8':
        final bits = _getBits(binary, index, 3);
        final phases = List.generate(8, (i) => i * pi / 4);
        return SymbolData(freq: centerFreq, phase: phases[bits], amplitude: 1.0);

      case 'msk':
      case 'gmsk':
        final bit = index < binary.length ? int.parse(binary[index]) : 0;
        return SymbolData(freq: centerFreq, phase: bit * pi / 2, amplitude: 1.0);

      case 'mfsk':
        final bits = _getBits(binary, index, 3);
        final freqs = List.generate(8, (i) => -700 + (i * 200));
        return SymbolData(freq: centerFreq + freqs[bits], phase: 0.0, amplitude: 1.0);

      default:
        final bit = index < binary.length ? int.parse(binary[index]) : 0;
        return SymbolData(freq: bit, phase: 0.0, amplitude: 1.0);
    }
  }

  static int _getBits(String binary, int index, int count) {
    int value = 0;
    for (int i = 0; i < count && (index + i) < binary.length; i++) {
      value = (value << 1) | int.parse(binary[index + i]);
    }
    return value;
  }

  static double _generateSample({
    required SymbolData symbol,
    required String modulation,
    required double time,
    required int centerFreq,
    required int symbolRate,
    required int bitIndex,
  }) {
    switch (modulation) {
      case 'fsk2':
        final f = symbol.freq == 1 ? centerFreq + 500 : centerFreq - 500;
        return sin(2 * pi * f * time);

      case 'fsk4':
      case 'fsk8':
      case 'fsk16':
      case 'mfsk':
        return sin(2 * pi * symbol.freq * time);

      case 'ook':
        if (symbol.amplitude == 0) return 0.0;
        return sin(2 * pi * centerFreq * time);

      case 'ask':
        return symbol.amplitude * sin(2 * pi * centerFreq * time);

      case 'bpsk':
        return sin(2 * pi * centerFreq * time + symbol.phase);

      case 'qpsk':
      case 'psk8':
        return sin(2 * pi * centerFreq * time + symbol.phase);

      case 'dbpsk':
        return sin(2 * pi * centerFreq * time + symbol.phase);

      case 'dqpsk':
        return sin(2 * pi * centerFreq * time + symbol.phase);

      case 'msk':
        final deviation = symbolRate / 4;
        final f = centerFreq + (symbol.phase > 0 ? deviation : -deviation);
        return sin(2 * pi * f * time);

      case 'gmsk':
        final deviation = symbolRate / 4;
        final f = centerFreq + (symbol.phase > 0 ? deviation : -deviation);
        return sin(2 * pi * f * time) * _gaussianPulse(time, symbolRate);

      default:
        final f = symbol.freq == 1 ? centerFreq + 500 : centerFreq - 500;
        return sin(2 * pi * f * time);
    }
  }

  static double _gaussianPulse(double t, int symbolRate) {
    final bt = 0.3;
    final sigma = sqrt(log(2)) / (2 * pi * bt * symbolRate);
    return exp(-t * t / (2 * sigma * sigma));
  }

  static List<(double, double)> getConstellationPoints(String modulation) {
    switch (modulation) {
      case 'bpsk':
      case 'dbpsk':
        return [(1.0, 0.0), (-1.0, 0.0)];
      case 'qpsk':
      case 'dqpsk':
        return [(1.0, 0.0), (0.0, 1.0), (-1.0, 0.0), (0.0, -1.0)];
      case 'psk8':
        return List.generate(8, (i) {
          final angle = i * pi / 4;
          return (cos(angle), sin(angle));
        });
      case 'fsk2':
      case 'ook':
      case 'ask':
        return [(0.0, 1.0), (0.0, -1.0), (1.0, 0.0), (-1.0, 0.0)];
      case 'fsk4':
        return [(-1.0, 0.0), (-0.33, 0.0), (0.33, 0.0), (1.0, 0.0)];
      default:
        return [(1.0, 0.0), (-1.0, 0.0)];
    }
  }

  static int getBitsPerSymbol(String modulation) {
    switch (modulation) {
      case 'fsk2': case 'bpsk': case 'ook': case 'ask':
      case 'dbpsk': case 'msk': case 'gmsk':
        return 1;
      case 'fsk4': case 'qpsk': case 'dqpsk':
        return 2;
      case 'fsk8': case 'psk8': case 'mfsk':
        return 3;
      case 'fsk16':
        return 4;
      default:
        return 1;
    }
  }
}

class SymbolData {
  final int freq;
  final double phase;
  final double amplitude;

  SymbolData({required this.freq, required this.phase, required this.amplitude});
}
