import 'package:flutter/services.dart';

class YouTubeBridge {
  static const MethodChannel _channel = MethodChannel('com.ytmultimate/data');

  static Future<String?> search(String query) async {
    try {
      final String? result = await _channel.invokeMethod('search', {'query': query});
      return result;
    } on PlatformException catch (e) {
      print("Failed to search: '${e.message}'.");
      return null;
    }
  }

  static Future<String?> getSong(String id) async {
    try {
      final String? result = await _channel.invokeMethod('getSong', {'id': id});
      return result;
    } on PlatformException catch (e) {
      print("Failed to get song: '${e.message}'.");
      return null;
    }
  }

  static Future<String?> getPlaylist(String id) async {
    try {
      final String? result = await _channel.invokeMethod('getPlaylist', {'id': id});
      return result;
    } on PlatformException catch (e) {
      print("Failed to get playlist: '${e.message}'.");
      return null;
    }
  }

  static Future<String?> getArtist(String id) async {
    try {
      final String? result = await _channel.invokeMethod('getArtist', {'id': id});
      return result;
    } on PlatformException catch (e) {
      print("Failed to get artist: '${e.message}'.");
      return null;
    }
  }

  static Future<String?> getStream(String id) async {
    try {
      final String? result = await _channel.invokeMethod('getStream', {'id': id});
      return result;
    } on PlatformException catch (e) {
      print("Failed to get stream: '${e.message}'.");
      return null;
    }
  }
}
