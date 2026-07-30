import 'dart:typed_data';

class ModemFrame {
  final int sequence;
  final Uint8List payload;
  final int? crc;
  final bool fecEnabled;

  ModemFrame({
    required this.sequence,
    required this.payload,
    this.crc,
    this.fecEnabled = false,
  });

  int get length => payload.length;

  @override
  String toString() => 'FRAME ${sequence.toString().padLeft(3, '0')} • ${payload.length} bytes';
}

class EncryptedPacket {
  final int version;
  final String encryptionFormat;
  final String modemVersion;
  final Uint8List iv;
  final Uint8List ciphertext;
  final Uint8List? tag;

  EncryptedPacket({
    required this.version,
    required this.encryptionFormat,
    required this.modemVersion,
    required this.iv,
    required this.ciphertext,
    this.tag,
  });

  Uint8List toBytes() {
    final header = Uint8List(8);
    header[0] = version;
    header[1] = encryptionFormat.length;
    final encBytes = Uint8List.fromList(encryptionFormat.codeUnits);
    final verBytes = Uint8List.fromList(modemVersion.codeUnits);
    final result = BytesBuilder();
    result.add(header);
    result.add(encBytes);
    result.add(verBytes);
    result.add(iv);
    if (tag != null) result.add(tag!);
    result.add(ciphertext);
    return result.toBytes();
  }
}

class AudioConfig {
  final int sampleRate;
  final int centerFreq;
  final int symbolRate;
  final int frameSize;
  final double volume;
  final double noiseLevel;
  final bool crcEnabled;
  final bool fecEnabled;
  final String modulation;

  AudioConfig({
    this.sampleRate = 22050,
    this.centerFreq = 1500,
    this.symbolRate = 300,
    this.frameSize = 32,
    this.volume = 0.8,
    this.noiseLevel = 0.0,
    this.crcEnabled = true,
    this.fecEnabled = false,
    this.modulation = 'fsk2',
  });

  AudioConfig copyWith({
    int? sampleRate,
    int? centerFreq,
    int? symbolRate,
    int? frameSize,
    double? volume,
    double? noiseLevel,
    bool? crcEnabled,
    bool? fecEnabled,
    String? modulation,
  }) => AudioConfig(
    sampleRate: sampleRate ?? this.sampleRate,
    centerFreq: centerFreq ?? this.centerFreq,
    symbolRate: symbolRate ?? this.symbolRate,
    frameSize: frameSize ?? this.frameSize,
    volume: volume ?? this.volume,
    noiseLevel: noiseLevel ?? this.noiseLevel,
    crcEnabled: crcEnabled ?? this.crcEnabled,
    fecEnabled: fecEnabled ?? this.fecEnabled,
    modulation: modulation ?? this.modulation,
  );
}

class DemodConfig {
  final int sampleRate;
  final int centerFreq;
  final int symbolRate;
  final int frameSize;
  final bool crcEnabled;
  final bool fecEnabled;
  final String modulation;
  final double agcGain;
  final double squelch;

  DemodConfig({
    this.sampleRate = 22050,
    this.centerFreq = 1500,
    this.symbolRate = 300,
    this.frameSize = 32,
    this.crcEnabled = true,
    this.fecEnabled = false,
    this.modulation = 'fsk2',
    this.agcGain = 20.0,
    this.squelch = -40.0,
  });
}
