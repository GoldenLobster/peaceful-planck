import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class ProxyAudioSource extends StreamAudioSource {
  final String url;
  final MediaItem? mediaItem;

  ProxyAudioSource(this.url, {this.mediaItem}) : super(tag: mediaItem);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final headers = {
      'User-Agent': 'com.google.ios.youtube/19.29.1 (iPhone14,3; U; CPU iOS 15_6 like Mac OS X)',
      'Accept': '*/*',
    };
    if (start != null || end != null) {
      headers['Range'] = 'bytes=${start ?? 0}-${end ?? ''}';
    }

    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(headers);

    final streamedResponse = await request.send();
    if (streamedResponse.statusCode >= 400) {
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
  }
}
