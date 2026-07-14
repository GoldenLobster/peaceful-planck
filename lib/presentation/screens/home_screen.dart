import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/home_feed.dart';
import '../../services/native_bridge/youtube_bridge.dart';
import '../providers/player_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoading = true;
  HomeFeed? _homeFeed;
  String? _errorStr;

  @override
  void initState() {
    super.initState();
    _fetchHome();
  }

  Future<void> _fetchHome() async {
    try {
      final res = await YouTubeBridge.getHome();
      if (res != null) {
        if (res.startsWith("ERROR:")) {
            setState(() {
               _errorStr = res.replaceFirst("ERROR:", "");
               _isLoading = false;
            });
            return;
        }
        final decoded = jsonDecode(res) as List<dynamic>;
        setState(() {
          _homeFeed = HomeFeed.fromJson(decoded);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorStr = "Failed to fetch. YouTubeBridge returned null.";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorStr = "Error parsing home feed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ytmUltimate', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorStr != null 
          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text("Error:\n$_errorStr", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
          : (_homeFeed == null || _homeFeed!.sections.isEmpty)
            ? const Center(child: Text("No recommendations found.\nMake sure you are online.", textAlign: TextAlign.center))
            : ListView.builder(
                itemCount: _homeFeed!.sections.length,
                itemBuilder: (context, index) {
                final section = _homeFeed!.sections[index];
                if (section.contents.songs.isEmpty && section.contents.albums.isEmpty && section.contents.playlists.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(section.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: section.contents.songs.length + section.contents.albums.length + section.contents.playlists.length,
                        itemBuilder: (context, i) {
                          if (i < section.contents.songs.length) {
                             final song = section.contents.songs[i];
                             return GestureDetector(
                               onTap: () => ref.read(playerProvider.notifier).play(song),
                               child: Container(
                                 width: 140,
                                 margin: const EdgeInsets.symmetric(horizontal: 8),
                                 child: Column(
                                   children: [
                                     song.thumbnailUrl != null 
                                        ? Image.network(song.thumbnailUrl!, width: 140, height: 140, fit: BoxFit.cover)
                                        : Container(width: 140, height: 140, color: Colors.grey),
                                     const SizedBox(height: 8),
                                     Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                     Text(song.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                   ],
                                 ),
                               ),
                             );
                          } else if (i < section.contents.songs.length + section.contents.albums.length) {
                             final albumIndex = i - section.contents.songs.length;
                             final album = section.contents.albums[albumIndex];
                             return GestureDetector(
                               onTap: () => context.push('/album', extra: album),
                               child: Container(
                                 width: 140,
                                 margin: const EdgeInsets.symmetric(horizontal: 8),
                                 child: Column(
                                   children: [
                                     album.thumbnailUrl != null 
                                        ? Image.network(album.thumbnailUrl!, width: 140, height: 140, fit: BoxFit.cover)
                                        : Container(width: 140, height: 140, color: Colors.grey),
                                     const SizedBox(height: 8),
                                     Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                     Text("Album", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                   ],
                                 ),
                               ),
                             );
                          } else {
                             final playlistIndex = i - section.contents.songs.length - section.contents.albums.length;
                             final playlist = section.contents.playlists[playlistIndex];
                             return GestureDetector(
                               onTap: () => context.push('/playlist', extra: playlist),
                               child: Container(
                                 width: 140,
                                 margin: const EdgeInsets.symmetric(horizontal: 8),
                                 child: Column(
                                   children: [
                                     playlist.thumbnailUrl != null 
                                        ? Image.network(playlist.thumbnailUrl!, width: 140, height: 140, fit: BoxFit.cover)
                                        : Container(width: 140, height: 140, color: Colors.grey),
                                     const SizedBox(height: 8),
                                     Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                     Text("Playlist", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                   ],
                                 ),
                               ),
                             );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
