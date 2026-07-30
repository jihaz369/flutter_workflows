import 'dart:typed_data';
import 'crc_service.dart';
import '../models/modem_models.dart';

/// Frame builder and parser
class FrameService {
  static const int _preambleByte = 0xAA;
  static const int _postambleByte = 0x55;
  static const int _headerSize = 4; // preamble(1) + seq(2) + len(1)

  /// Build frames from binary string
  static List<ModemFrame> buildFrames(String binary, int frameSizeBytes, {bool crc = true, bool fec = false}) {
    final bytes = _binaryToBytes(binary);
    final frames = <ModemFrame>[];

    for (int i = 0; i < bytes.length; i += frameSizeBytes) {
      final end = (i + frameSizeBytes < bytes.length) ? i + frameSizeBytes : bytes.length;
      var payload = Uint8List.sublistView(bytes, i, end);

      if (crc) {
        payload = CrcService.appendCrc(payload);
      }

      frames.add(ModemFrame(
        sequence: frames.length,
        payload: payload,
        crc: crc ? CrcService.compute(Uint8List.sublistView(bytes, i, end)) : null,
        fecEnabled: fec,
      ));
    }

    return frames;
  }

  /// Parse frames from raw bytes
  static List<ModemFrame> parseFrames(Uint8List data, int frameSizeBytes, {bool crc = true}) {
    final frames = <ModemFrame>[];
    int offset = 0;

    while (offset < data.length) {
      if (data[offset] != _preambleByte) {
        offset++;
        continue;
      }

      if (offset + _headerSize > data.length) break;

      final seq = (data[offset + 1] << 8) | data[offset + 2];
      final len = data[offset + 3];

      if (offset + _headerSize + len > data.length) break;

      var payload = Uint8List.sublistView(data, offset + _headerSize, offset + _headerSize + len);
      bool valid = true;

      if (crc && payload.length >= 2) {
        final result = CrcService.extractAndVerify(payload);
        payload = result.$1;
        valid = result.$2;
      }

      frames.add(ModemFrame(
        sequence: seq,
        payload: payload,
        crc: valid ? 0 : null,
      ));

      offset += _headerSize + len;
    }

    return frames;
  }

  /// Serialize frame to bytes with header
  static Uint8List serializeFrame(ModemFrame frame) {
    final result = Uint8List(_headerSize + frame.payload.length);
    result[0] = _preambleByte;
    result[1] = (frame.sequence >> 8) & 0xFF;
    result[2] = frame.sequence & 0xFF;
    result[3] = frame.payload.length;
    result.setRange(_headerSize, _headerSize + frame.payload.length, frame.payload);
    return result;
  }

  /// Serialize all frames to continuous bytes
  static Uint8List serializeFrames(List<ModemFrame> frames) {
    final builder = BytesBuilder();
    for (final frame in frames) {
      builder.add(serializeFrame(frame));
    }
    return builder.toBytes();
  }

  /// Extract payload from all frames
  static String extractPayload(List<ModemFrame> frames) {
    final builder = BytesBuilder();
    for (final frame in frames) {
      builder.add(frame.payload);
    }
    return _bytesToBinary(builder.toBytes());
  }

  static Uint8List _binaryToBytes(String binary) {
    final bytes = <int>[];
    for (int i = 0; i < binary.length; i += 8) {
      final end = (i + 8 < binary.length) ? i + 8 : binary.length;
      bytes.add(int.parse(binary.substring(i, end).padRight(8, '0'), radix: 2));
    }
    return Uint8List.fromList(bytes);
  }

  static String _bytesToBinary(Uint8List bytes) {
    final bits = StringBuffer();
    for (final b in bytes) {
      bits.write(b.toRadixString(2).padLeft(8, '0'));
    }
    return bits.toString();
  }
}
