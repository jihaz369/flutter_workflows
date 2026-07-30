# Holo Radio - Native Flutter Digital Modem

A complete native Flutter Android port of the HoloRadio digital modem system.

## Architecture

```
lib/
  models/           - Data models (frames, packets, config)
  services/         - Business logic
    dsp/            - Digital signal processing
    encoder_service.dart
    decoder_service.dart
    modulation_service.dart
    demodulation_service.dart
    frame_service.dart
    crc_service.dart
    fec_service.dart
    wav_service.dart
    audio_service.dart
    encryption_service.dart
    visualization_service.dart
  screens/          - UI screens
    home_screen.dart
    sender_screen.dart
    receiver_screen.dart
    settings_screen.dart
    analyzer_screen.dart
  widgets/          - Reusable widgets & painters
  theme/            - Holo visual theme
  utils/            - Utilities
```

## Modem Pipeline

### Transmit
```
TEXT -> ENCODE -> BIT STREAM -> FRAME BUILDER -> CRC/FEC -> ENCRYPTION -> MODULATOR -> PCM AUDIO -> [WAV FILE | ANDROID SPEAKER]
```

### Receive
```
WAV FILE -> PCM AUDIO -> DEMODULATOR -> FRAME PARSER -> CRC/FEC -> DECRYPT -> TEXT
```

## Supported Modulations

- FSK: 2, 4, 8, 16 levels
- PSK: BPSK, QPSK, 8PSK, DBPSK, DQPSK
- OOK, ASK
- MSK, GMSK
- MFSK

## WAV Format

- PCM 16-bit mono
- Configurable sample rate (8000-48000 Hz)
- Standard RIFF/WAVE header

## ENC Format

- Version: 1
- Encryption: AES-GCM-256
- Key Derivation: PBKDF2-HMAC-SHA256 (100k iterations)
- Structure: version(1) + formatLen(1) + format + versionString + IV(12) + TAG(16) + ciphertext

## CRC

- CRC-16-CCITT
- Polynomial: 0x1021
- Initial: 0xFFFF
- Reflection: false

## FEC

- Hamming (7,4) code
- Corrects single-bit errors

## Build Instructions

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Dependencies

- just_audio: Native audio playback
- audio_session: Audio session management
- file_picker: File import
- share_plus: File export
- encrypt + pointycastle: AES-GCM-256 encryption
- permission_handler: Android permissions

## Permissions

- RECORD_AUDIO: For microphone input
- READ/WRITE_EXTERNAL_STORAGE: For file operations
