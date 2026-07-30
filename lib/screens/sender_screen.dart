import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../theme/holo_theme.dart';
import '../services/encoder_service.dart';
import '../services/modulation_service.dart';
import '../services/wav_service.dart';
import '../services/audio_service.dart';
import '../services/encryption_service.dart';
import '../services/frame_service.dart';
import '../services/visualization_service.dart';
import '../widgets/holo_panel.dart';
import '../widgets/spectrum_painter.dart';
import '../widgets/oscope_painter.dart';
import '../widgets/bitstream_painter.dart';
import '../widgets/constellation_painter.dart';

class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final _textController = TextEditingController(
    text: 'Hello, HoloRadio! This is a test transmission.',
  );
  final _passphraseController = TextEditingController();
  final _audioService = AudioService();

  String _binaryOutput = 'Awaiting encoding...';
  String _frameOutput = 'No frames generated';
  bool _isEncrypting = false;
  bool _isTransmitting = false;
  String _keyStatus = 'No key loaded';

  String _modulation = 'fsk2';
  int _sampleRate = 22050;
  int _centerFreq = 1500;
  int _symbolRate = 300;
  int _frameSize = 32;
  double _volume = 0.8;
  double _noiseLevel = 0.0;
  bool _crcEnabled = true;
  bool _fecEnabled = false;

  Float32List? _lastSamples;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _audioService.initialize();
    _logAdd('System initialized');
  }

  void _logAdd(String msg) {
    setState(() {
      _log.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
      if (_log.length > 100) _log.removeAt(0);
    });
  }

  void _encode() {
    final text = _textController.text;
    if (text.isEmpty) return;
    final binary = EncoderService.textToBinary(text);
    setState(() => _binaryOutput = binary);
    _logAdd('Encoded ${text.length} chars -> ${binary.length} bits');
  }

  void _buildFrames() {
    if (_binaryOutput == 'Awaiting encoding...') _encode();
    final frames = FrameService.buildFrames(_binaryOutput, _frameSize, crc: _crcEnabled, fec: _fecEnabled);
    setState(() => _frameOutput = 'Generated ${frames.length} frames @ $_frameSize bytes');
    _logAdd('Built ${frames.length} frames');
  }

  Future<void> _transmit() async {
    if (_binaryOutput == 'Awaiting encoding...') _encode();
    setState(() => _isTransmitting = true);
    _logAdd('Starting audio transmission...');
    try {
      final samples = ModulationService.modulate(
        binary: _binaryOutput,
        modulation: _modulation,
        sampleRate: _sampleRate,
        centerFreq: _centerFreq,
        symbolRate: _symbolRate,
        volume: _volume,
        noiseLevel: _noiseLevel,
      );
      _lastSamples = samples;
      await _audioService.playPcm(samples, _sampleRate);
      _logAdd('Transmission complete');
    } catch (e) {
      _logAdd('Transmission error: $e');
    } finally {
      setState(() => _isTransmitting = false);
    }
  }

  Future<void> _generateWav() async {
    if (_binaryOutput == 'Awaiting encoding...') _encode();
    final samples = ModulationService.modulate(
      binary: _binaryOutput,
      modulation: _modulation,
      sampleRate: _sampleRate,
      centerFreq: _centerFreq,
      symbolRate: _symbolRate,
      volume: _volume,
      noiseLevel: _noiseLevel,
    );
    final wavData = WavService.generateWav(samples, sampleRate: _sampleRate);
    await Share.shareXFiles([
      XFile.fromData(wavData, mimeType: 'audio/wav', name: 'holotx.wav'),
    ], text: 'HoloRadio WAV transmission');
    _logAdd('WAV generated: ${wavData.length} bytes');
  }

  Future<void> _downloadEncrypted() async {
    final passphrase = _passphraseController.text;
    if (passphrase.isEmpty) {
      _logAdd('ERROR: Passphrase required');
      return;
    }
    final text = _textController.text;
    if (text.isEmpty) {
      _logAdd('ERROR: No text to encrypt');
      return;
    }
    try {
      final encData = EncryptionService.encryptToEnc(text, passphrase);
      await Share.shareXFiles([
        XFile.fromData(encData, mimeType: 'application/octet-stream', name: 'holomessage.enc'),
      ]);
      setState(() => _keyStatus = 'Key valid - AES-GCM-256 active');
      _logAdd('Encrypted file exported: ${encData.length} bytes');
    } catch (e) {
      _logAdd('Encryption failed: $e');
    }
  }

  void _copyBinary() {
    if (_binaryOutput == 'Awaiting encoding...') return;
    Clipboard.setData(ClipboardData(text: _binaryOutput));
    _logAdd('Binary copied to clipboard');
  }

  void _showConstellation() {
    final points = ModulationService.getConstellationPoints(_modulation);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HoloTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: const BorderSide(color: HoloTheme.cyan)),
        title: const Text('Constellation Diagram', style: TextStyle(color: HoloTheme.cyan, fontFamily: HoloTheme.fontMono)),
        content: SizedBox(
          width: 300, height: 300,
          child: CustomPaint(painter: ConstellationPainter(points), size: const Size(300, 300)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE', style: TextStyle(color: HoloTheme.cyan))),
        ],
      ),
    );
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

  Widget _dispBox(String text, {double minH = 80, double maxH = 150}) {
    return Container(
      padding: const EdgeInsets.all(10),
      constraints: BoxConstraints(minHeight: minH, maxHeight: maxH),
      decoration: BoxDecoration(color: HoloTheme.darkPanel, border: Border.all(color: HoloTheme.borderColor), borderRadius: BorderRadius.circular(2)),
      child: SingleChildScrollView(child: SelectableText(text, style: const TextStyle(color: HoloTheme.green, fontFamily: HoloTheme.fontMono, fontSize: 11))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          HoloPanel(title: 'Text Input', child: Column(children: [
            TextField(controller: _textController, maxLines: 4,
              style: const TextStyle(color: HoloTheme.cyan, fontFamily: HoloTheme.fontMono, fontSize: 13),
              decoration: const InputDecoration(hintText: 'Enter message to encode...')),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              _btn('ENCODE', _encode, primary: true),
              _btn('CLEAR', () { _textController.clear(); setState(() => _binaryOutput = 'Awaiting encoding...'); }),
              _btn('SAMPLE', () { _textController.text = 'HoloRadio Test Message #42. Signal check. Over.'; _encode(); }),
            ]),
          ])),
          HoloPanel(title: 'Binary Output', child: Column(children: [
            _dispBox(_binaryOutput),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              _btn('COPY BINARY', _copyBinary),
              _btn('EXPORT BIN', () => Share.share(_binaryOutput)),
            ]),
          ])),
          HoloPanel(title: 'Frame Builder', child: Column(children: [
            _dispBox(_frameOutput, maxH: 80),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              _btn('BUILD FRAMES', _buildFrames, primary: true),
              _btn('EXPORT FRAMES', () => _logAdd('Frames exported')),
            ]),
          ])),
          HoloPanel(title: 'Security Layer', child: Column(children: [
            Row(children: [
              Switch(value: _isEncrypting, onChanged: (v) => setState(() => _isEncrypting = v)),
              Text(_isEncrypting ? 'ENCRYPTION ON' : 'ENCRYPTION OFF',
                style: TextStyle(color: _isEncrypting ? HoloTheme.green : HoloTheme.dimCyan, fontFamily: HoloTheme.fontMono, fontSize: 11)),
            ]),
            TextField(controller: _passphraseController, enabled: _isEncrypting, obscureText: true,
              style: const TextStyle(color: HoloTheme.cyan, fontFamily: HoloTheme.fontMono),
              decoration: const InputDecoration(labelText: 'Passphrase')),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: HoloTheme.darkPanel, border: Border.all(color: HoloTheme.borderColor)),
              child: Text(_keyStatus, style: TextStyle(color: _keyStatus.contains('valid') ? HoloTheme.green : HoloTheme.dimCyan))),
            const SizedBox(height: 8),
            _btn('DOWNLOAD ENCRYPTED (.ENC)', _downloadEncrypted, primary: true, disabled: !_isEncrypting),
          ])),
          HoloPanel(title: 'Transmission Controls', child: Column(children: [
            _configGrid(),
            const SizedBox(height: 15),
            Wrap(spacing: 10, children: [
              _btn('TRANSMIT AUDIO', _transmit, primary: true, disabled: _isTransmitting),
              _btn('GENERATE WAV', _generateWav, primary: true),
              _btn('CONSTELLATION', _showConstellation),
            ]),
          ])),
          if (_lastSamples != null) ...[
            HoloPanel(title: 'Spectrum Analyzer', child: SizedBox(
              height: 150, child: CustomPaint(painter: SpectrumPainter(_lastSamples!, _sampleRate), size: Size.infinite))),
            HoloPanel(title: 'Oscilloscope', child: SizedBox(
              height: 150, child: CustomPaint(painter: OscopePainter(_lastSamples!), size: Size.infinite))),
          ],
          HoloPanel(title: 'Bit Stream', child: SizedBox(
            height: 100, child: CustomPaint(painter: BitStreamPainter(_binaryOutput), size: Size.infinite))),
          HoloPanel(title: 'System Log', child: Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(shrinkWrap: true, itemCount: _log.length,
              itemBuilder: (ctx, i) => Text(_log[i], style: const TextStyle(color: HoloTheme.dimCyan, fontFamily: HoloTheme.fontMono, fontSize: 11)),
            ),
          )),
        ],
      ),
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
        Expanded(child: _slider('Volume', _volume, (v) => setState(() => _volume = v))),
        Expanded(child: _slider('Noise', _noiseLevel, (v) => setState(() => _noiseLevel = v))),
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
      ]),
    ]);
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: onChanged, decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8))),
      ]));
  }

  Widget _numField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        TextField(controller: TextEditingController(text: value.toString()), keyboardType: TextInputType.number,
          style: const TextStyle(color: HoloTheme.cyan, fontFamily: HoloTheme.fontMono, fontSize: 12),
          onChanged: (v) => onChanged(int.tryParse(v) ?? value),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8))),
      ]));
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label: ${(value * 100).toInt()}%', style: const TextStyle(color: HoloTheme.dimCyan, fontSize: 10)),
        Slider(value: value, min: 0, max: 1, onChanged: onChanged),
      ]));
  }

  @override
  void dispose() {
    _textController.dispose();
    _passphraseController.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
