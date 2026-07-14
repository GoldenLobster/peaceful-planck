import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'proxy_audio_source.dart';

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

    _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
      _eventController.add({'type': 'error', 'message': 'Stream Error: $e'});
    });
  }

  static Future<void> play({
    required String url,
    required String title,
    required String artist,
    String? artworkUrl,
  }) async {
    try {
      final audioSource = ProxyAudioSource(
        url,
        mediaItem: MediaItem(
          id: url,
          album: artist,
          title: title,
          artist: artist,
          artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
        ),
        onError: (errorMsg) {
          _eventController.add({'type': 'error', 'message': errorMsg});
        },
      );
      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      print("Error playing audio: $e");
      _eventController.add({'type': 'error', 'message': e.toString()});
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
