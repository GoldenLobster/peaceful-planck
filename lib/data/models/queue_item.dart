import 'song.dart';

class QueueItem {
  final String id; 
  final Song song;

  const QueueItem({
    required this.id,
    required this.song,
  });
}
