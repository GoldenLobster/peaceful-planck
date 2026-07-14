import 'song.dart';

class Album {
  final String id;
  final String title;
  final String artistName;
  final String? thumbnailUrl;
  final String? year;
  final List<Song>? tracks;

  const Album({
    required this.id,
    required this.title,
    required this.artistName,
    this.thumbnailUrl,
    this.year,
    this.tracks,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Album',
      artistName: Song.parseAuthor(json['author']),
      thumbnailUrl: Song.fromJson(json).thumbnailUrl, 
      year: json['year'],
      tracks: (json['tracks'] as List?)?.map((t) => Song.fromJson(t)).toList(),
    );
  }
}
