import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/artist.dart';
import '../../data/models/home_feed.dart';
import '../../services/native_bridge/youtube_bridge.dart';
import '../providers/player_provider.dart';

class ArtistScreen extends ConsumerStatefulWidget {
  final Artist artist;
  const ArtistScreen({super.key, required this.artist});

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  bool _isLoading = true;
  HomeFeed? _artistFeed;

  @override
  void initState() {
    super.initState();
    _fetchArtist();
  }

  Future<void> _fetchArtist() async {
    final res = await YouTubeBridge.getArtist(widget.artist.id);
    if (res != null) {
      final decoded = jsonDecode(res) as List<dynamic>;
      setState(() {
        _artistFeed = HomeFeed.fromJson(decoded);
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist.name),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_artistFeed == null || _artistFeed!.sections.isEmpty)
          ? const Center(child: Text("No artist details found."))
          : ListView.builder(
              itemCount: _artistFeed!.sections.length,
              itemBuilder: (context, index) {
                final section = _artistFeed!.sections[index];
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
                        itemCount: section.contents.songs.length + section.contents.albums.length,
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
                                   ],
                                 ),
                               ),
                             );
                          } else {
                             final albumIndex = i - section.contents.songs.length;
                             final album = section.contents.albums[albumIndex];
                             return Container(
                               width: 140,
                               margin: const EdgeInsets.symmetric(horizontal: 8),
                               child: Column(
                                 children: [
                                   album.thumbnailUrl != null 
                                      ? Image.network(album.thumbnailUrl!, width: 140, height: 140, fit: BoxFit.cover)
                                      : Container(width: 140, height: 140, color: Colors.grey),
                                   const SizedBox(height: 8),
                                   Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                                 ],
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
