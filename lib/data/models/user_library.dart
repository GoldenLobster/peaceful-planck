import 'playlist.dart';
import 'album.dart';
import 'artist.dart';
import 'song.dart';

class UserLibrary {
  final List<Playlist> playlists;
  final List<Album> savedAlbums;
  final List<Artist> followedArtists;
  final List<Song> likedSongs;

  const UserLibrary({
    this.playlists = const [],
    this.savedAlbums = const [],
    this.followedArtists = const [],
    this.likedSongs = const [],
  });
}
