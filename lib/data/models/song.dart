class Song {
  final String id;
  final String title;
  final String artistName;
  final String? artistId;
  final String? albumName;
  final String? albumId;
  final String? thumbnailUrl;
  final int durationSeconds;

  const Song({
    required this.id,
    required this.title,
    required this.artistName,
    this.artistId,
    this.albumName,
    this.albumId,
    this.thumbnailUrl,
    required this.durationSeconds,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artistName: parseAuthor(json['author'] ?? json['artists']),
      artistId: _parseAuthorId(json['author'] ?? json['artists']),
      albumName: json['album']?['name'],
      albumId: json['album']?['id'],
      thumbnailUrl: _parseThumbnail(json['thumbnails']),
      durationSeconds: _parseDuration(json['duration']),
    );
  }

  static String parseAuthor(dynamic authorData) {
    if (authorData is String) return authorData;
    if (authorData is List && authorData.isNotEmpty) {
      return authorData.first['name'] ?? 'Unknown Artist';
    }
    if (authorData is Map) {
      return authorData['name'] ?? 'Unknown Artist';
    }
    return 'Unknown Artist';
  }

  static String? _parseAuthorId(dynamic authorData) {
    if (authorData is List && authorData.isNotEmpty) {
      return authorData.first['id'] ?? authorData.first['channel_id'];
    }
    if (authorData is Map) {
      return authorData['id'] ?? authorData['channel_id'];
    }
    return null;
  }

  static String? _parseThumbnail(dynamic thumbnails) {
    if (thumbnails is List && thumbnails.isNotEmpty) {
      return thumbnails.last['url'];
    }
    return null;
  }

  static int _parseDuration(dynamic duration) {
    if (duration is int) return duration;
    if (duration is Map && duration['seconds'] != null) {
      return duration['seconds'] as int;
    }
    return 0;
  }
}
