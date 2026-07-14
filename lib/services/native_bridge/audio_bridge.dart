import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioBridge {
  static final AudioPlayer _player = AudioPlayer();
  static final StreamController<Map<String, dynamic>> _eventController = StreamController<Map<String, dynamic>>.broadcast();

  static void init() {
    _player.playerStateStream.listen((state) {
      String statusStr;
      if (state.processingState == ProcessingState.completed) {
        statusStr = 'completed';
      } else if (state.playing) {
        statusStr = 'playing';
      } else if (state.processingState == ProcessingState.buffering || state.processingState == ProcessingState.loading) {
        statusStr = 'buffering';
      } else {
        statusStr = 'paused';
      }
      _eventController.add({'type': 'state', 'value': statusStr});
    });

    _player.positionStream.listen((pos) {
      _eventController.add({'type': 'position', 'position': pos.inMilliseconds / 1000.0});
    });

    _player.bufferedPositionStream.listen((pos) {
      _eventController.add({'type': 'buffer', 'buffered': pos.inMilliseconds / 1000.0});
    });
  }

  static Future<void> play({
    required String url,
    required String title,
    required String artist,
    String? artworkUrl,
  }) async {
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          album: artist,
          title: title,
          artist: artist,
          artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
        ),
      );
      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      print("Error playing audio: \$e");
    }
  }

  static Future<void> pause() async {
    await _player.pause();
  }

  static Future<void> resume() async {
    await _player.play();
  }

  static Future<void> seek(double positionSeconds) async {
    await _player.seek(Duration(milliseconds: (positionSeconds * 1000).toInt()));
  }

  static Stream<dynamic> get audioEventsStream {
    return _eventController.stream;
  }
}
