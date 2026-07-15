import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'proxy_audio_source.dart';
import '../app_logger.dart';

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
    String? artist,
    String? artworkUrl,
    bool useProxy = false, // Force false by default as proxy seems buggy for AVPlayer
  }) async {
    try {
      AppLogger.log("AudioBridge.play: url=$url");
      final MediaItem mediaItem = MediaItem(
        id: url,
        album: artist,
        title: title,
        artUri: artworkUrl != null ? Uri.parse(artworkUrl) : null,
      );

      // We completely bypass the ProxyAudioSource because AVPlayer natively handles HTTP range requests much better.
      // However, YouTube blocks AVPlayer's default "AppleCoreMedia" User-Agent.
      // We must explicitly pass a standard browser or Android User-Agent in the headers.
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
      };

      AppLogger.log("Using standard AudioSource.uri with custom headers");
      final audioSource = AudioSource.uri(
        Uri.parse(url), 
        tag: mediaItem,
        headers: headers,
      );
      
      AppLogger.log("Setting audio source...");
      await _player.setAudioSource(audioSource);
      AppLogger.log("Audio source set, starting playback...");
      await _player.play();
      AppLogger.log("Playback started.");
    } catch (e) {
      AppLogger.log("AudioBridge.play Exception: $e");
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
