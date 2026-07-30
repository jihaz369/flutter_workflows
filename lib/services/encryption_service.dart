import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  static const String _saltString = 'HoloRadioSalt_v1';
  static const int _iterations = 100000;
  static const int _keyLength = 32;
  static const int _ivLength = 12;

  static Uint8List _deriveKey(String passphrase) {
    final salt = Uint8List.fromList(_saltString.codeUnits);
    final password = utf8.encode(passphrase);
    return _pbkdf2(password, salt, _iterations, _keyLength);
  }

  static Uint8List _pbkdf2(List<int> password, Uint8List salt, int iterations, int keyLen) {
    var result = <int>[];
    var blockNum = 1;
    while (result.length < keyLen) {
      final hmac = Hmac(sha256, password);
      final saltBlock = Uint8List(salt.length + 4);
      saltBlock.setRange(0, salt.length, salt);
      saltBlock[salt.length] = (blockNum >> 24) & 0xFF;
      saltBlock[salt.length + 1] = (blockNum >> 16) & 0xFF;
      saltBlock[salt.length + 2] = (blockNum >> 8) & 0xFF;
      saltBlock[salt.length + 3] = blockNum & 0xFF;

      var u = Uint8List.fromList(hmac.convert(saltBlock).bytes);
      var block = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < block.length; j++) {
          block[j] ^= u[j];
        }
      }

      result.addAll(block);
      blockNum++;
    }

    return Uint8List.fromList(result.sublist(0, keyLen));
  }

  static Uint8List _generateIv() {
    final rand = Random.secure();
    return Uint8List.fromList(List.generate(_ivLength, (_) => rand.nextInt(256)));
  }

  static ({Uint8List ciphertext, Uint8List iv, Uint8List tag}) encrypt(Uint8List plaintext, String passphrase) {
    final keyBytes = _deriveKey(passphrase);
    final iv = _generateIv();

    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plaintext, iv: encrypt.IV(iv));

    final cipherBytes = Uint8List.fromList(encrypted.bytes);
    final tag = Uint8List.sublistView(cipherBytes, cipherBytes.length - 16);
    final ciphertext = Uint8List.sublistView(cipherBytes, 0, cipherBytes.length - 16);

    return (ciphertext: ciphertext, iv: iv, tag: tag);
  }

  static Uint8List decrypt(Uint8List ciphertext, Uint8List iv, Uint8List tag, String passphrase) {
    final keyBytes = _deriveKey(passphrase);
    final combined = Uint8List(ciphertext.length + tag.length);
    combined.setRange(0, ciphertext.length, ciphertext);
    combined.setRange(ciphertext.length, combined.length, tag);

    final key = encrypt.Key(keyBytes);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(combined),
      iv: encrypt.IV(iv),
    );

    return Uint8List.fromList(decrypted);
  }

  static Uint8List encryptToEnc(String text, String passphrase) {
    final plaintext = Uint8List.fromList(text.codeUnits);
    final result = encrypt(plaintext, passphrase);

    final encFormat = 'AES-GCM-256';
    final modemVersion = 'HoloRadio v1.0';

    final builder = BytesBuilder();
    builder.addByte(1);
    builder.addByte(encFormat.length);
    builder.add(Uint8List.fromList(encFormat.codeUnits));
    builder.add(Uint8List.fromList(modemVersion.codeUnits));
    builder.add(result.iv);
    builder.add(result.tag);
    builder.add(result.ciphertext);

    return builder.toBytes();
  }

  static String decryptFromEnc(Uint8List data, String passphrase) {
    if (data.length < 30) throw Exception('Invalid ENC file');

    final version = data[0];
    final encFormatLen = data[1];
    var offset = 2;
    offset += encFormatLen;
    offset = 32;

    final iv = Uint8List.sublistView(data, offset, offset + _ivLength);
    offset += _ivLength;

    final tag = Uint8List.sublistView(data, offset, offset + 16);
    offset += 16;

    final ciphertext = Uint8List.sublistView(data, offset);

    final decrypted = decrypt(ciphertext, iv, tag, passphrase);
    return String.fromCharCodes(decrypted);
  }

  static bool isValidPassphrase(String passphrase) {
    return passphrase.length >= 4;
  }
}
