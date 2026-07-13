import '../../data/models/song.dart';
import '../../data/models/album.dart';
import '../../data/models/artist.dart';
import '../../data/models/playlist.dart';
import '../../data/models/search_result.dart';

abstract class YouTubeRepository {
  Future<SearchResults> search(String query);
  Future<Song?> getSongDetails(String videoId);
  Future<Playlist?> getPlaylist(String playlistId);
  Future<Artist?> getArtist(String artistId);
  Future<Album?> getAlbum(String albumId);
  Future<String?> getStreamUrl(String videoId);
  Future<List<Song>> getRecommendations(String videoId);
}
