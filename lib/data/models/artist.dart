import 'song.dart';
import 'album.dart';

class Artist {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String? description;
  final List<Song>? topSongs;
  final List<Album>? albums;

  const Artist({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.description,
    this.topSongs,
    this.albums,
  });
  
  factory Artist.fromJson(Map<String, dynamic> json) {
     return Artist(
        id: json['id'] ?? '',
        name: json['name'] ?? json['title'] ?? 'Unknown Artist',
        thumbnailUrl: Song.fromJson(json).thumbnailUrl,
        description: json['description'],
     );
  }
}
