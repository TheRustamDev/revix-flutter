import 'package:dio/dio.dart';
import 'dart:convert';
import 'innertube_client.dart';

class YouTubeMusicRecommendations {
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
      'Origin': 'https://music.youtube.com',
      'Referer': 'https://music.youtube.com/',
    },
  ));

  // Get songs that YouTube Music plays AFTER a given song
  // This is the core of smart autoplay
  Future<List<SongResult>> getWatchNext(String videoId,
      {String? playlistId}) async {
    try {
      final body = {
        "context": _context,
        "videoId": videoId,
        "playlistId": playlistId ?? "RDAMVM$videoId",
        "params": "wAEB",
        "autoplay": true,
      };

      final response = await _dio.post(
        '/next?key=$_apiKey&prettyPrint=false',
        data: jsonEncode(body),
      );

      final List<SongResult> results = [];

      try {
        final tabs = response.data['contents']
                ?['singleColumnMusicWatchNextResultsRenderer']
            ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];

        if (tabs == null) return [];

        for (var tab in tabs) {
          final items = tab['tabRenderer']?['content']?['musicQueueRenderer']
              ?['content']?['playlistPanelRenderer']?['contents'];

          if (items == null) continue;

          for (var item in items) {
            final renderer = item['playlistPanelVideoRenderer'];
            if (renderer == null) continue;

            final id = renderer['videoId'] ?? '';
            if (id == videoId || id.isEmpty) continue; // skip current song

            final title = renderer['title']?['runs']?[0]?['text'] ?? '';
            final artist =
                renderer['shortBylineText']?['runs']?[0]?['text'] ?? '';
            final thumbnail =
                renderer['thumbnail']?['thumbnails']?.last?['url'] ?? '';

            if (id.isNotEmpty && title.isNotEmpty) {
              results.add(SongResult(
                id: id,
                title: title,
                artist: artist,
                thumbnail: thumbnail,
              ));
            }
          }
        }
      } catch (e) {
        print('WatchNext parse error: $e');
      }

      return results;
    } catch (e) {
      print('WatchNext error: $e');
      return [];
    }
  }

  // Get personalized home feed
  Future<Map<String, List<SongResult>>> getHomeFeed() async {
    try {
      final response = await _dio.post(
        '/browse?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "browseId": "FEmusic_home",
        }),
      );

      final Map<String, List<SongResult>> sections = {};

      try {
        final contents = response.data['contents']
                        ?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
                    ?['tabRenderer']?['content']?['sectionListRenderer']
                ?['contents'] ??
            [];

        for (var section in contents) {
          final shelf = section['musicCarouselShelfRenderer'] ??
              section['musicImmersiveCarouselShelfRenderer'];
          if (shelf == null) continue;

          final sectionTitle = shelf['header']
                      ?['musicCarouselShelfBasicHeaderRenderer']?['title']
                  ?['runs']?[0]?['text'] ??
              'For You';

          final List<SongResult> songs = [];
          final items = shelf['contents'] ?? [];

          for (var item in items) {
            final renderer = item['musicTwoRowItemRenderer'] ??
                item['musicResponsiveListItemRenderer'];
            if (renderer == null) continue;

            final id = renderer['overlay']?['musicItemThumbnailOverlayRenderer']
                        ?['content']?['musicPlayButtonRenderer']
                    ?['playNavigationEndpoint']?['watchEndpoint']?['videoId'] ??
                '';

            if (id.isEmpty) continue;

            final title = renderer['title']?['runs']?[0]?['text'] ?? '';
            final subtitle = renderer['subtitle']?['runs']?[0]?['text'] ?? '';
            final thumbnail = renderer['thumbnailRenderer']
                        ?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';

            songs.add(SongResult(
              id: id,
              title: title,
              artist: subtitle,
              thumbnail: thumbnail,
            ));
          }

          if (songs.isNotEmpty) {
            sections[sectionTitle] = songs;
          }
        }
      } catch (e) {
        print('Home feed parse error: $e');
      }

      return sections;
    } catch (e) {
      print('Home feed error: $e');
      return {};
    }
  }
}
