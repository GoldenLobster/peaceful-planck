import 'song.dart';

class Playlist {
  final String id;
  final String title;
  final String? author;
  final String? thumbnailUrl;
  final int? trackCount;
  final List<Song>? tracks;

  const Playlist({
    required this.id,
    required this.title,
    this.author,
    this.thumbnailUrl,
    this.trackCount,
    this.tracks,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: Song.parseAuthor(json['author']),
      thumbnailUrl: Song.fromJson(json).thumbnailUrl,
      trackCount: json['item_count'],
      tracks: (json['items'] as List?)?.map((t) => Song.fromJson(t)).toList(),
    );
  }
}
