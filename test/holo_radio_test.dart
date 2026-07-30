import 'package:flutter_test/flutter_test.dart';
import 'package:holo_radio/services/encoder_service.dart';
import 'package:holo_radio/services/crc_service.dart';
import 'package:holo_radio/services/fec_service.dart';
import 'package:holo_radio/services/modulation_service.dart';
import 'package:holo_radio/services/demodulation_service.dart';
import 'package:holo_radio/services/wav_service.dart';
import 'package:holo_radio/services/encryption_service.dart';
import 'package:holo_radio/services/frame_service.dart';

void main() {
  group('Encoder Service', () {
    test('Text to binary round trip', () {
      const text = 'Hello, HoloRadio!';
      final binary = EncoderService.textToBinary(text);
      final decoded = EncoderService.binaryToText(binary);
      expect(decoded, text);
    });

    test('Binary to bytes round trip', () {
      const binary = '0100100001101001';
      final bytes = EncoderService.binaryToBytes(binary);
      final back = EncoderService.bytesToBinary(bytes);
      expect(back.substring(0, binary.length), binary);
    });
  });

  group('CRC Service', () {
    test('CRC computation and verification', () {
      final data = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final crc = CrcService.compute(data);
      expect(CrcService.verify(data, crc), true);
    });

    test('CRC append and extract', () {
      final data = Uint8List.fromList([0x01, 0x02, 0x03]);
      final withCrc = CrcService.appendCrc(data);
      final result = CrcService.extractAndVerify(withCrc);
      expect(result.$2, true);
      expect(result.$1, data);
    });
  });

  group('FEC Service', () {
    test('Hamming encode/decode round trip', () {
      final data = Uint8List.fromList([0x42, 0x13, 0xAB]);
      final encoded = FecService.encode(data);
      final decoded = FecService.decode(encoded);
      expect(decoded, data);
    });
  });

  group('Modulation/Demodulation', () {
    test('FSK2 round trip', () {
      const binary = '10110010';
      final samples = ModulationService.modulate(
        binary: binary,
        modulation: 'fsk2',
        sampleRate: 8000,
        centerFreq: 1500,
        symbolRate: 100,
        volume: 0.8,
      );
      final decoded = DemodulationService.demodulate(
        samples: samples,
        modulation: 'fsk2',
        sampleRate: 8000,
        centerFreq: 1500,
        symbolRate: 100,
      );
      expect(decoded.substring(0, binary.length), binary);
    });

    test('BPSK round trip', () {
      const binary = '10110010';
      final samples = ModulationService.modulate(
        binary: binary,
        modulation: 'bpsk',
        sampleRate: 8000,
        centerFreq: 1500,
        symbolRate: 100,
        volume: 0.8,
      );
      final decoded = DemodulationService.demodulate(
        samples: samples,
        modulation: 'bpsk',
        sampleRate: 8000,
        centerFreq: 1500,
        symbolRate: 100,
      );
      expect(decoded.substring(0, binary.length), binary);
    });
  });

  group('WAV Service', () {
    test('WAV generation and parsing round trip', () {
      final samples = Float32List.fromList([0.0, 0.5, -0.5, 0.25, -0.25]);
      final wav = WavService.generateWav(samples, sampleRate: 22050);
      expect(WavService.isValidWav(wav), true);
      final parsed = WavService.parseWav(wav);
      expect(parsed.sampleRate, 22050);
      expect(parsed.channels, 1);
      expect(parsed.bitsPerSample, 16);
      expect(parsed.samples.length, samples.length);
    });
  });

  group('Encryption Service', () {
    test('AES-GCM encrypt/decrypt round trip', () {
      const text = 'Secret HoloRadio Message';
      const passphrase = 'testpass123';
      final enc = EncryptionService.encryptToEnc(text, passphrase);
      final dec = EncryptionService.decryptFromEnc(enc, passphrase);
      expect(dec, text);
    });
  });

  group('Frame Service', () {
    test('Frame build and parse round trip', () {
      final binary = EncoderService.textToBinary('Frame test message');
      final frames = FrameService.buildFrames(binary, 16, crc: true);
      expect(frames.isNotEmpty, true);
      final serialized = FrameService.serializeFrames(frames);
      final parsed = FrameService.parseFrames(serialized, 16, crc: true);
      expect(parsed.length, frames.length);
    });
  });

  group('Full Modem Pipeline', () {
    test('Text -> Encode -> Modulate -> Demodulate -> Decode -> Text', () {
      const originalText = 'HoloRadio Full Pipeline Test #42';
      final binary = EncoderService.textToBinary(originalText);
      final frames = FrameService.buildFrames(binary, 32, crc: true);
      final frameBinary = FrameService.extractPayload(frames);
      final samples = ModulationService.modulate(
        binary: frameBinary,
        modulation: 'fsk2',
        sampleRate: 8000,
        centerFreq: 1500,
        symbolRate: 100,
        volume: 0.8,
      );
      final demodBinary = DemodulationService.demodulate(
        samples: samples,
        modulation: 'fsk2',
        sampleRate: 8000,
        centerFreq: 1500,
        symbolRate: 100,
      );
      final decodedText = EncoderService.binaryToText(demodBinary);
      expect(decodedText, originalText);
    });
  });
}
