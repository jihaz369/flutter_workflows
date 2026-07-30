import 'dart:typed_data';
import 'dart:math';

class WavService {
  static Uint8List generateWav(Float32List samples, {
    required int sampleRate,
    int bitsPerSample = 16,
    int channels = 1,
  }) {
    final bytesPerSample = bitsPerSample ~/ 8;
    final dataSize = samples.length * bytesPerSample * channels;
    final fileSize = 44 + dataSize;

    final buffer = Uint8List(fileSize);
    final view = ByteData.sublistView(buffer);
    var offset = 0;

    _writeString(buffer, offset, 'RIFF'); offset += 4;
    view.setUint32(offset, fileSize - 8, Endian.little); offset += 4;
    _writeString(buffer, offset, 'WAVE'); offset += 4;
    _writeString(buffer, offset, 'fmt '); offset += 4;
    view.setUint32(offset, 16, Endian.little); offset += 4;
    view.setUint16(offset, 1, Endian.little); offset += 2;
    view.setUint16(offset, channels, Endian.little); offset += 2;
    view.setUint32(offset, sampleRate, Endian.little); offset += 4;
    view.setUint32(offset, sampleRate * channels * bytesPerSample, Endian.little); offset += 4;
    view.setUint16(offset, channels * bytesPerSample, Endian.little); offset += 2;
    view.setUint16(offset, bitsPerSample, Endian.little); offset += 2;
    _writeString(buffer, offset, 'data'); offset += 4;
    view.setUint32(offset, dataSize, Endian.little); offset += 4;

    for (int i = 0; i < samples.length; i++) {
      final sample = (samples[i] * 32767).clamp(-32768, 32767).toInt();
      view.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer;
  }

  static ({Float32List samples, int sampleRate, int channels, int bitsPerSample, double duration}) parseWav(Uint8List data) {
    if (data.length < 44) throw Exception('WAV file too small');

    final view = ByteData.sublistView(data);

    if (_readString(data, 0, 4) != 'RIFF' || _readString(data, 8, 4) != 'WAVE') {
      throw Exception('Invalid WAV header');
    }

    int offset = 12;
    int sampleRate = 22050;
    int channels = 1;
    int bitsPerSample = 16;

    while (offset < data.length - 8) {
      final chunkId = _readString(data, offset, 4);
      final chunkSize = view.getUint32(offset + 4, Endian.little);

      if (chunkId == 'fmt ') {
        channels = view.getUint16(offset + 10, Endian.little);
        sampleRate = view.getUint32(offset + 12, Endian.little);
        bitsPerSample = view.getUint16(offset + 22, Endian.little);
      } else if (chunkId == 'data') {
        final numSamples = chunkSize ~/ (channels * (bitsPerSample ~/ 8));
        final samples = Float32List(numSamples);
        int dataOffset = offset + 8;

        for (int i = 0; i < numSamples; i++) {
          if (bitsPerSample == 16) {
            final raw = view.getInt16(dataOffset + i * 2, Endian.little);
            samples[i] = raw / 32768.0;
          } else if (bitsPerSample == 8) {
            samples[i] = (data[dataOffset + i] - 128) / 128.0;
          }
        }

        final duration = numSamples / sampleRate;
        return (
          samples: samples,
          sampleRate: sampleRate,
          channels: channels,
          bitsPerSample: bitsPerSample,
          duration: duration,
        );
      }

      offset += 8 + chunkSize;
      if (chunkSize % 2 == 1) offset++;
    }

    throw Exception('No data chunk found');
  }

  static void _writeString(Uint8List buffer, int offset, String str) {
    for (int i = 0; i < str.length; i++) {
      buffer[offset + i] = str.codeUnitAt(i);
    }
  }

  static String _readString(Uint8List buffer, int offset, int length) {
    return String.fromCharCodes(buffer.sublist(offset, offset + length));
  }

  static bool isValidWav(Uint8List data) {
    return data.length >= 44 &&
           _readString(data, 0, 4) == 'RIFF' &&
           _readString(data, 8, 4) == 'WAVE';
  }

  static ({int sampleRate, int channels, int bitsPerSample, double duration, int dataSize}) getMetadata(Uint8List data) {
    final result = parseWav(data);
    return (
      sampleRate: result.sampleRate,
      channels: result.channels,
      bitsPerSample: result.bitsPerSample,
      duration: result.duration,
      dataSize: result.samples.length * 2,
    );
  }
}
