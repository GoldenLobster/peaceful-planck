import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class ProxyAudioSource extends StreamAudioSource {
  final String url;
  final MediaItem? mediaItem;
  final Function(String) onError;

  ProxyAudioSource(this.url, {this.mediaItem, required this.onError}) : super(tag: mediaItem);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.142 Safari/537.36; SMART-TV; Tizen 4.0',
      'Accept': '*/*',
    };
    if (start != null || end != null) {
      headers['Range'] = 'bytes=${start ?? 0}-${end ?? ''}';
    }

    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final streamedResponse = await request.send();
      if (streamedResponse.statusCode >= 400) {
        onError('HTTP error ${streamedResponse.statusCode}');
        throw Exception('HTTP error ${streamedResponse.statusCode}');
      }

    final contentType = streamedResponse.headers['content-type'] ?? 'audio/mp4';
    final contentLengthStr = streamedResponse.headers['content-length'];
    final contentRange = streamedResponse.headers['content-range'];
    
    int? sourceLength;
    int offset = start ?? 0;

    if (streamedResponse.statusCode == 200) {
      offset = 0; // The server ignored our range request and sent from 0
    }

    if (contentRange != null) {
      final parts = contentRange.split('/');
      if (parts.length == 2) {
        sourceLength = int.tryParse(parts[1]);
      }
    } else if (contentLengthStr != null) {
      sourceLength = int.tryParse(contentLengthStr);
    }

      return StreamAudioResponse(
        sourceLength: sourceLength,
        contentLength: contentLengthStr != null ? int.tryParse(contentLengthStr) : null,
        offset: offset,
        stream: streamedResponse.stream,
        contentType: contentType,
      );
    } catch (e) {
      onError('Proxy Error: $e');
      throw e;
    }
  }
}
