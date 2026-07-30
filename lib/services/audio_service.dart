import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'wav_service.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playPcm(Float32List samples, int sampleRate) async {
    if (_isPlaying) await stop();
    final wavData = WavService.generateWav(samples, sampleRate: sampleRate);
    await _player.setAudioSource(MyCustomSource(wavData));
    await _player.play();
    _isPlaying = true;
  }

  Future<void> playWav(Uint8List wavData) async {
    if (_isPlaying) await stop();
    await _player.setAudioSource(MyCustomSource(wavData));
    await _player.play();
    _isPlaying = true;
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  bool get isPlaying => _isPlaying;

  void dispose() {
    _player.dispose();
  }
}

class MyCustomSource extends StreamAudioSource {
  final Uint8List _buffer;
  MyCustomSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.fromIterable([_buffer.sublist(start, end)]),
      contentType: 'audio/wav',
    );
  }
}
