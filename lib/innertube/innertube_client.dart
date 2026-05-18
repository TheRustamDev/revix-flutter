import 'package:dio/dio.dart';
import 'dart:convert';

class InnerTubeClient {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-KXML3nxPQ';

  static const Map<String, dynamic> _context = {
    "client": {
      "clientName": "WEB_REMIX",
      "clientVersion": "1.20240101.01.00",
      "hl": "en",
      "gl": "US",
    }
  };

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0',
      'X-YouTube-Client-Name': '67',
      'X-YouTube-Client-Version': '1.20240101.01.00',
      'Origin': 'https://music.youtube.com',
      'Referer': 'https://music.youtube.com/',
    },
  ));

  Future<List<SongResult>> search(String query) async {
    try {
      final response = await _dio.post(
        '/search?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "query": query,
          "params": "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D"
        }),
      );

      final data = response.data;
      final List<SongResult> results = [];

      try {
        final contents = data['contents']['tabbedSearchResultsRenderer']
            ['tabs'][0]['tabRenderer']['content']['sectionListRenderer']
            ['contents'];

        for (var section in contents) {
          final items = section['musicShelfRenderer']?['contents'] ?? [];
          for (var item in items) {
            final renderer = item['musicResponsiveListItemRenderer'];
            if (renderer == null) continue;

            final title = renderer['flexColumns']?[0]
                ?['musicResponsiveListItemFlexColumnRenderer']
                ?['text']?['runs']?[0]?['text'] ?? '';

            final artist = renderer['flexColumns']?[1]
                ?['musicResponsiveListItemFlexColumnRenderer']
                ?['text']?['runs']?[0]?['text'] ?? '';

            final videoId = renderer['playlistItemData']?['videoId'] ??
                renderer['overlay']?['musicItemThumbnailOverlayRenderer']
                ?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']
                ?['watchEndpoint']?['videoId'] ?? '';

            final thumbnail = renderer['thumbnail']
                ?['musicThumbnailRenderer']?['thumbnail']
                ?['thumbnails']?.last?['url'] ?? '';

            if (videoId.isNotEmpty && title.isNotEmpty) {
              results.add(SongResult(
                id: videoId,
                title: title,
                artist: artist,
                thumbnail: thumbnail,
              ));
            }
          }
        }
      } catch (e) {
        print('Parse error: $e');
      }

      return results;
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }
}

class SongResult {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;

  SongResult({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
  });

  @override
  String toString() => '$title by $artist (id: $id)';
}
