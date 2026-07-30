import 'dart:typed_data';

class EncoderService {
  static String textToBinary(String text) {
    final bytes = Uint8List.fromList(text.codeUnits);
    final bits = StringBuffer();
    for (final b in bytes) {
      bits.write(b.toRadixString(2).padLeft(8, '0'));
    }
    return bits.toString();
  }

  static String binaryToText(String binary) {
    if (binary.isEmpty) return '';
    final bytes = <int>[];
    for (int i = 0; i < binary.length; i += 8) {
      final end = (i + 8 < binary.length) ? i + 8 : binary.length;
      final byteStr = binary.substring(i, end).padRight(8, '0');
      bytes.add(int.parse(byteStr, radix: 2));
    }
    return String.fromCharCodes(bytes);
  }

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
