import 'package:just_audio/just_audio.dart';
void main() {
  AudioSource.uri(Uri.parse("http://example.com"), headers: {"User-Agent": "test"});
}
