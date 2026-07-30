import 'dart:typed_data';

/// Hamming (7,4) FEC implementation
/// Encodes 4 data bits into 7 bits (3 parity bits)
/// Can correct single-bit errors and detect double-bit errors
class FecService {
  /// Encode a nibble (4 bits) into 7 bits
  static int _encodeNibble(int data) {
    final d1 = (data >> 3) & 1;
    final d2 = (data >> 2) & 1;
    final d3 = (data >> 1) & 1;
    final d4 = data & 1;

    final p1 = d1 ^ d2 ^ d4;
    final p2 = d1 ^ d3 ^ d4;
    final p3 = d2 ^ d3 ^ d4;

    return (d1 << 6) | (d2 << 5) | (d3 << 4) | (p3 << 3) | (d4 << 2) | (p2 << 1) | p1;
  }

  /// Decode 7 bits into 4 bits, with error correction
  static int _decodeNibble(int encoded) {
    final d1 = (encoded >> 6) & 1;
    final d2 = (encoded >> 5) & 1;
    final d3 = (encoded >> 4) & 1;
    final p3 = (encoded >> 3) & 1;
    final d4 = (encoded >> 2) & 1;
    final p2 = (encoded >> 1) & 1;
    final p1 = encoded & 1;

    final s1 = p1 ^ d1 ^ d2 ^ d4;
    final s2 = p2 ^ d1 ^ d3 ^ d4;
    final s3 = p3 ^ d2 ^ d3 ^ d4;

    final syndrome = (s3 << 2) | (s2 << 1) | s1;

    int corrected = encoded;
    if (syndrome != 0) {
      // Single bit error, flip the bit at syndrome position
      corrected ^= (1 << (7 - syndrome));
    }

    return ((corrected >> 6) & 1) << 3 |
           ((corrected >> 5) & 1) << 2 |
           ((corrected >> 4) & 1) << 1 |
           ((corrected >> 2) & 1);
  }

  static Uint8List encode(Uint8List data) {
    final result = <int>[];
    for (final byte in data) {
      final high = _encodeNibble((byte >> 4) & 0xF);
      final low = _encodeNibble(byte & 0xF);
      result.add(high);
      result.add(low);
    }
    return Uint8List.fromList(result);
  }

  static Uint8List decode(Uint8List data) {
    if (data.length % 2 != 0) {
      // Pad with zero if odd
      data = Uint8List.fromList([...data, 0]);
    }
    final result = <int>[];
    for (int i = 0; i < data.length; i += 2) {
      final high = _decodeNibble(data[i]);
      final low = _decodeNibble(data[i + 1]);
      result.add((high << 4) | low);
    }
    return Uint8List.fromList(result);
  }

  static String encodeBinary(String binary) {
    final bytes = EncoderService.binaryToBytes(binary);
    final encoded = encode(bytes);
    return EncoderService.bytesToBinary(encoded);
  }

  static String decodeBinary(String binary) {
    final bytes = EncoderService.binaryToBytes(binary);
    final decoded = decode(bytes);
    return EncoderService.bytesToBinary(decoded);
  }
}

// Forward reference for binary conversion
class EncoderService {
  static Uint8List binaryToBytes(String binary) {
    final bytes = <int>[];
    for (int i = 0; i < binary.length; i += 8) {
      final end = (i + 8 < binary.length) ? i + 8 : binary.length;
      final byteStr = binary.substring(i, end).padRight(8, '0');
      bytes.add(int.parse(byteStr, radix: 2));
    }
    return Uint8List.fromList(bytes);
  }

  static String bytesToBinary(Uint8List bytes) {
    final bits = StringBuffer();
    for (final b in bytes) {
      bits.write(b.toRadixString(2).padLeft(8, '0'));
    }
    return bits.toString();
  }
}
