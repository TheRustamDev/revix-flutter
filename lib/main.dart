import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'innertube/innertube_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _client = InnerTubeClient();
  final _player = AudioPlayer();
  List<SongResult> _songs = [];
  String _status = 'Ready';

  Future<void> _search() async {
    setState(() => _status = 'Searching...');
    final results = await _client.search('Talwiinder');
    setState(() {
      _songs = results;
      _status = 'Found ${results.length} songs';
    });
  }

  Future<void> _play(SongResult song) async {
    setState(() => _status = 'Loading: ${song.title}...');
    try {
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(
        song.id,
        ytClients: [YoutubeApiClient.androidVr],
      );
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final url = streamInfo.url.toString();
      print('Stream URL: $url');
      await _player.setUrl(url);
      await _player.play();
      setState(() => _status = 'Playing: ${song.title}');
    } catch (e) {
      setState(() => _status = 'Error: $e');
      print('Play error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title:
              const Text('REVIX Test', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_status, style: const TextStyle(color: Colors.pink)),
            ),
            ElevatedButton(
              onPressed: _search,
              child: const Text('Search Songs'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(_songs[i].title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(_songs[i].artist,
                      style: const TextStyle(color: Colors.grey)),
                  onTap: () => _play(_songs[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
