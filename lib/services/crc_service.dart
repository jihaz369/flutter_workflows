import 'dart:typed_data';

/// CRC-16-CCITT implementation
/// Polynomial: 0x1021
/// Initial: 0xFFFF
/// Reflection: false
/// Final XOR: 0x0000
class CrcService {
  static const int _poly = 0x1021;
  static const int _init = 0xFFFF;

  static final List<int> _table = _generateTable();

  static List<int> _generateTable() {
    final table = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int crc = i << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ _poly) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
      table[i] = crc;
    }
    return table;
  }

  static int compute(Uint8List data) {
    int crc = _init;
    for (final byte in data) {
      crc = ((_table[((crc >> 8) ^ byte) & 0xFF] ^ (crc << 8)) & 0xFFFF);
    }
    return crc;
  }

  static int computeBinary(String binary) {
    final bytes = <int>[];
    for (int i = 0; i < binary.length; i += 8) {
      final end = (i + 8 < binary.length) ? i + 8 : binary.length;
      bytes.add(int.parse(binary.substring(i, end).padRight(8, '0'), radix: 2));
    }
    return compute(Uint8List.fromList(bytes));
  }

  static bool verify(Uint8List data, int expectedCrc) {
    return compute(data) == expectedCrc;
  }

  static Uint8List appendCrc(Uint8List data) {
    final crc = compute(data);
    final result = Uint8List(data.length + 2);
    result.setRange(0, data.length, data);
    result[data.length] = (crc >> 8) & 0xFF;
    result[data.length + 1] = crc & 0xFF;
    return result;
  }

  static (Uint8List data, bool valid) extractAndVerify(Uint8List dataWithCrc) {
    if (dataWithCrc.length < 2) return (dataWithCrc, false);
    final payload = Uint8List.sublistView(dataWithCrc, 0, dataWithCrc.length - 2);
    final receivedCrc = (dataWithCrc[dataWithCrc.length - 2] << 8) | dataWithCrc[dataWithCrc.length - 1];
    return (payload, compute(payload) == receivedCrc);
  }
}
