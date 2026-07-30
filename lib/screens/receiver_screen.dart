import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../theme/holo_theme.dart';
import '../services/wav_service.dart';
import '../services/demodulation_service.dart';
import '../services/encoder_service.dart';
import '../services/encryption_service.dart';
import '../widgets/holo_panel.dart';
import '../widgets/oscope_painter.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  String _decodedText = 'Awaiting decode...';
  String _binaryInput = 'No data received';
  bool _isDecrypting = false;
  final _passphraseController = TextEditingController();
  String _decryptStatus = 'No decryption active';
  Uint8List? _encBuffer;
  Float32List? _rxSamples;

  String _modulation = 'fsk2';
  int _sampleRate = 22050;
  int _centerFreq = 1500;
  int _symbolRate = 300;
  int _frameSize = 32;
  bool _crcEnabled = true;
  bool _fecEnabled = false;
  double _agcGain = 20;
  double _squelch = -40;

  final List<String> _log = [];

  void _logAdd(String msg) {
    setState(() {
      _log.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
      if (_log.length > 100) _log.removeAt(0);
    });
  }

  Future<void> _loadWav() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['wav'], withData: true);
    if (result != null && result.files.single.bytes != null) {
      try {
        final parsed = WavService.parseWav(result.files.single.bytes!);
        setState(() => _rxSamples = parsed.samples);
        _logAdd('Loaded WAV: ${parsed.samples.length} samples, ${parsed.duration.toStringAsFixed(2)}s');
      } catch (e) {
        _logAdd('WAV load error: $e');
      }
    }
  }

  void _decode() {
    if (_rxSamples == null || _rxSamples!.isEmpty) {
      _logAdd('No signal to decode');
      return;
    }
    try {
      final binary = DemodulationService.demodulate(
        samples: _rxSamples!,
        modulation: _modulation,
        sampleRate: _sampleRate,
        centerFreq: _centerFreq,
        symbolRate: _symbolRate,
      );
      final text = EncoderService.binaryToText(binary);
      setState(() {
        _binaryInput = binary.length > 256 ? binary.substring(0, 256) + '...' : binary;
        _decodedText = text;
      });
      _logAdd('Decode complete: ${binary.length} bits');
    } catch (e) {
      _logAdd('Decode error: $e');
    }
  }

  Future<void> _loadEnc() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['enc', 'bin'], withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _encBuffer = result.files.single.bytes);
      _logAdd('Encrypted file loaded: ${_encBuffer!.length} bytes');
    }
  }

  void _attemptDecrypt() {
    final passphrase = _passphraseController.text;
    if (passphrase.isEmpty) {
      setState(() => _decryptStatus = 'ERROR: No passphrase');
      return;
    }
    try {
      if (_encBuffer != null) {
        final decrypted = EncryptionService.decryptFromEnc(_encBuffer!, passphrase);
        setState(() {
          _decodedText = decrypted;
          _decryptStatus = 'Decryption successful';
        });
        _logAdd('Decryption successful - Message recovered');
      }
    } catch (e) {
      setState(() => _decryptStatus = 'Decryption failed');
      _logAdd('Decryption failed: $e');
    }
  }

  Widget _btn(String label, VoidCallback onPressed, {bool primary = false, bool disabled = false}) {
    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? HoloTheme.dimCyan.withOpacity(0.2) : HoloTheme.panel,
        side: BorderSide(color: primary ? HoloTheme.cyan : HoloTheme.borderColor),
      ),
      child: Text(label),
    );
  }

  Widget _statusDot(String label, bool active) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: [
        Container(width: 8, height: 8,
          decoration: BoxDecoration(
            color: active ? HoloTheme.green : HoloTheme.dimCyan,
            shape: BoxShape.circle,
            boxShadow: active ? [BoxShadow(color: HoloTheme.green.withOpacity(0.5), blurRadius: 8)] : null,
          )),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10)),
      ]));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        HoloPanel(title: 'Signal Input', child: Column(children: [
          Wrap(spacing: 8, children: [
            _btn('LOAD WAV', _loadWav, primary: true),
            _btn('DECODE', _decode, primary: true),
            _btn('COPY BINARY', () {
              if (_binaryInput != 'No data received') {
                Clipboard.setData(ClipboardData(text: _binaryInput));
                _logAdd('RX binary copied');
              }
            }),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _rxSamples != null ? 1.0 : 0.0,
            backgroundColor: HoloTheme.darkPanel,
            valueColor: const AlwaysStoppedAnimation(HoloTheme.cyan),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _statusDot('SYNC', false),
            _statusDot('CRC', false),
            _statusDot('RECEIVING', _rxSamples != null),
          ]),
        ])),
        HoloPanel(title: 'Decoded Text', child: Column(children: [
          Container(padding: const EdgeInsets.all(10), constraints: const BoxConstraints(minHeight: 80),
            decoration: BoxDecoration(color: HoloTheme.darkPanel, border: Border.all(color: HoloTheme.borderColor)),
            child: SelectableText(_decodedText, style: const TextStyle(color: HoloTheme.green, fontFamily: HoloTheme.fontMono))),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            _btn('COPY TEXT', () => Clipboard.setData(ClipboardData(text: _decodedText))),
            _btn('SAVE TXT', () => Share.share(_decodedText)),
          ]),
        ])),
        HoloPanel(title: 'Demodulation Settings', child: _configGrid()),
        HoloPanel(title: 'Decryption Layer', child: Column(children: [
          Row(children: [
            Switch(value: _isDecrypting, onChanged: (v) => setState(() => _isDecrypting = v)),
            Text(_isDecrypting ? 'DECRYPTION ON' : 'DECRYPTION OFF',
              style: TextStyle(color: _isDecrypting ? HoloTheme.green : HoloTheme.dimCyan, fontFamily: HoloTheme.fontMono)),
          ]),
          TextField(controller: _passphraseController, enabled: _isDecrypting, obscureText: true,
            decoration: const InputDecoration(labelText: 'Passphrase')),
          const SizedBox(height: 8),
          Text(_decryptStatus, style: TextStyle(color: _decryptStatus.contains('success') ? HoloTheme.green : HoloTheme.dimCyan)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            _btn('LOAD ENC FILE', _loadEnc),
            _btn('DECRYPT BUFFER', _attemptDecrypt, primary: true, disabled: !_isDecrypting),
          ]),
        ])),
        if (_rxSamples != null)
          HoloPanel(title: 'Signal Scope', child: SizedBox(
            height: 150, child: CustomPaint(painter: OscopePainter(_rxSamples!), size: Size.infinite))),
        HoloPanel(title: 'Receiver Log', child: Container(
          constraints: const BoxConstraints(maxHeight: 150),
          child: ListView.builder(shrinkWrap: true, itemCount: _log.length,
            itemBuilder: (ctx, i) => Text(_log[i], style: const TextStyle(color: HoloTheme.dimCyan, fontFamily: HoloTheme.fontMono, fontSize: 11)),
          ),
        )),
      ]),
    );
  }

  Widget _configGrid() {
    return Column(children: [
      Row(children: [
        Expanded(child: _dropdown('Modulation', _modulation,
          ['fsk2','fsk4','fsk8','fsk16','bpsk','qpsk','psk8','ook','ask','msk','gmsk','mfsk','dbpsk','dqpsk'],
          (v) => setState(() => _modulation = v!))),
        Expanded(child: _dropdown('Sample Rate', _sampleRate.toString(),
          ['8000','16000','22050','44100','48000'], (v) => setState(() => _sampleRate = int.parse(v!)))),
        Expanded(child: _numField('Center Freq', _centerFreq, (v) => _centerFreq = v)),
        Expanded(child: _numField('Symbol Rate', _symbolRate, (v) => _symbolRate = v)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _numField('Frame Size', _frameSize, (v) => _frameSize = v)),
        Expanded(child: Column(children: [
          Row(children: [
            Checkbox(value: _crcEnabled, onChanged: (v) => setState(() => _crcEnabled = v!), activeColor: HoloTheme.cyan),
            const Text('CRC-16', style: TextStyle(color: HoloTheme.cyan, fontSize: 11)),
          ]),
          Row(children: [
            Checkbox(value: _fecEnabled, onChanged: (v) => setState(() => _fecEnabled = v!), activeColor: HoloTheme.cyan),
            const Text('FEC', style: TextStyle(color: HoloTheme.cyan, fontSize: 11)),
          ]),
        ])),
        Expanded(child: _slider('AGC Gain', _agcGain / 40, (v) => setState(() => _agcGain = v * 40))),
        Expanded(child: _numField('Squelch', _squelch.toInt(), (v) => _squelch = v.toDouble())),
      ]),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10)),
        DropdownButtonFormField<String>(value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: onChanged, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8))),
      ]));
  }

  Widget _numField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10)),
        TextField(controller: TextEditingController(text: value.toString()), keyboardType: TextInputType.number,
          style: const TextStyle(color: HoloTheme.cyan, fontFamily: HoloTheme.fontMono, fontSize: 12),
          onChanged: (v) => onChanged(int.tryParse(v) ?? value),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8))),
      ]));
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10)),
        Slider(value: value, min: 0, max: 1, onChanged: onChanged),
      ]));
  }
}
