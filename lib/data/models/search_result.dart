import 'song.dart';
import 'album.dart';
import 'artist.dart';
import 'playlist.dart';

class SearchResults {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;
  final List<Playlist> playlists;

  const SearchResults({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });
  
  factory SearchResults.fromJson(List<dynamic> jsonList) {
     List<Song> songs = [];
     List<Album> albums = [];
     List<Artist> artists = [];
     List<Playlist> playlists = [];
     
     for (var item in jsonList) {
        if (item is! Map) continue;
        final type = item['type'] as String?;
        if (type == 'Song' || type == 'Video') {
           songs.add(Song.fromJson(item as Map<String, dynamic>));
        } else if (type == 'Album') {
           albums.add(Album.fromJson(item as Map<String, dynamic>));
        } else if (type == 'Artist') {
           artists.add(Artist.fromJson(item as Map<String, dynamic>));
        } else if (type == 'Playlist') {
           playlists.add(Playlist.fromJson(item as Map<String, dynamic>));
        }
     }
     
     return SearchResults(
        songs: songs,
        albums: albums,
        artists: artists,
        playlists: playlists
     );
  }
}
