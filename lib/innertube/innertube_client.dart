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
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'Mozilla/5.0',
      'X-YouTube-Client-Name': '67',
      'X-YouTube-Client-Version': '1.20240101.01.00',
      'Origin': 'https://music.youtube.com',
      'Referer': 'https://music.youtube.com/',
    },
  ));

  // Get YouTube Music "Up Next" for a playing song
  Future<List<SongResult>> getUpNext(String videoId) async {
    try {
      final response = await _dio.post(
        '/next?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "videoId": videoId,
          "isAudioOnly": true,
          "params": "wAEB",
        }),
      );
      final List<SongResult> results = [];
      try {
        final data = response.data;
        // Path 1: singleColumnMusicWatchNextResultsRenderer
        dynamic contents;
        try {
          contents = data['contents']
                          ['singleColumnMusicWatchNextResultsRenderer']
                      ['tabbedRenderer']['watchNextTabbedResultsRenderer']
                  ['tabs'][0]['tabRenderer']['content']['musicQueueRenderer']
              ['content']['playlistPanelRenderer']['contents'];
        } catch (_) {}

        // Path 2: twoColumnWatchNextResults fallback
        if (contents == null) {
          try {
            contents = data['contents']['twoColumnWatchNextResults']
                ['secondaryResults']['secondaryResults']['results'];
          } catch (_) {}
        }

        if (contents != null) {
          for (var item in contents) {
            final r = item['playlistPanelVideoRenderer'] ??
                item['compactVideoRenderer'];
            if (r == null) continue;
            final title = r['title']?['runs']?[0]?['text'] ??
                r['title']?['simpleText'] ??
                '';
            final artist = r['longBylineText']?['runs']?[0]?['text'] ??
                r['shortBylineText']?['runs']?[0]?['text'] ??
                '';
            final vid = r['videoId'] ?? '';
            final thumb = r['thumbnail']?['thumbnails']?.last?['url'] ?? '';
            if (vid.isNotEmpty && title.isNotEmpty) {
              results.add(SongResult(
                  id: vid, title: title, artist: artist, thumbnail: thumb));
            }
          }
        }
      } catch (e) {
        print('UpNext parse: $e');
      }
      return results;
    } catch (e) {
      print('UpNext error: $e');
      return [];
    }
  }

  // Get Lyrics Browse ID
  Future<String?> getLyricsBrowseId(String videoId) async {
    try {
      final response = await _dio.post(
        '/next?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "videoId": videoId,
          "isAudioOnly": true,
        }),
      );
      final tabs = response.data['contents']
              ?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']
          ?['watchNextTabbedResultsRenderer']?['tabs'];
      if (tabs == null) return null;

      for (var tab in tabs) {
        final title =
            tab['tabRenderer']?['title']?.toString().toLowerCase() ?? '';
        if (title.contains('lyrics')) {
          return tab['tabRenderer']?['endpoint']?['browseEndpoint']
              ?['browseId'];
        }
      }
    } catch (e) {
      print('getLyricsBrowseId error: $e');
    }
    return null;
  }

  // Get Lyrics Text
  Future<String?> getLyrics(String browseId) async {
    try {
      final response = await _dio.post(
        '/browse?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "browseId": browseId,
        }),
      );
      final contents = response.data['contents']?['sectionListRenderer']
              ?['contents']?[0]?['musicDescriptionShelfRenderer']
          ?['description']?['runs'];
      if (contents == null) return null;

      return (contents as List).map((r) => r['text'] ?? '').join('');
    } catch (e) {
      print('getLyrics error: $e');
    }
    return null;
  }

  // Search with timestamp to bust cache
  Future<List<SongResult>> freshSearch(String query) async {
    // Use exact same working search logic as original search()
    // Only difference: add random offset param to bust cache
    final salt = DateTime.now().millisecondsSinceEpoch % 99999;
    try {
      final response = await _dio.post(
        '/search?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB_REMIX",
              "clientVersion": "1.20240101.01.00", // NEVER change this
              "hl": "en",
              "gl": "US",
              "utcOffsetMinutes": salt % 60, // only this changes
            }
          },
          "query": query,
          "params": "EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D",
        }),
      );
      final List<SongResult> results = [];
      try {
        final contents = response.data['contents']
                ['tabbedSearchResultsRenderer']['tabs'][0]['tabRenderer']
            ['content']['sectionListRenderer']['contents'];
        for (var section in contents) {
          final items = section['musicShelfRenderer']?['contents'] ?? [];
          for (var item in items) {
            final renderer = item['musicResponsiveListItemRenderer'];
            if (renderer == null) continue;
            final title = renderer['flexColumns']?[0]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';
            final artist = renderer['flexColumns']?[1]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';
            final videoId = renderer['playlistItemData']?['videoId'] ??
                renderer['overlay']?['musicItemThumbnailOverlayRenderer']
                        ?['content']?['musicPlayButtonRenderer']
                    ?['playNavigationEndpoint']?['watchEndpoint']?['videoId'] ??
                '';
            final thumbnail = renderer['thumbnail']?['musicThumbnailRenderer']
                        ?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';
            if (videoId.isNotEmpty && title.isNotEmpty) {
              results.add(SongResult(
                  id: videoId,
                  title: title,
                  artist: artist,
                  thumbnail: thumbnail));
            }
          }
        }
      } catch (e) {
        print('freshSearch parse: $e');
      }
      return results;
    } catch (e) {
      print('freshSearch error: $e');
      // FALLBACK: try original search() as backup
      return await search(query);
    }
  }

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
        final contents = data['contents']['tabbedSearchResultsRenderer']['tabs']
            [0]['tabRenderer']['content']['sectionListRenderer']['contents'];

        for (var section in contents) {
          final items = section['musicShelfRenderer']?['contents'] ?? [];
          for (var item in items) {
            final renderer = item['musicResponsiveListItemRenderer'];
            if (renderer == null) continue;

            final title = renderer['flexColumns']?[0]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';

            final artist = renderer['flexColumns']?[1]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';

            final videoId = renderer['playlistItemData']?['videoId'] ??
                renderer['overlay']?['musicItemThumbnailOverlayRenderer']
                        ?['content']?['musicPlayButtonRenderer']
                    ?['playNavigationEndpoint']?['watchEndpoint']?['videoId'] ??
                '';

            final thumbnail = renderer['thumbnail']?['musicThumbnailRenderer']
                        ?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';

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

  Future<List<SongResult>> getQuickPicks() async {
    return await freshSearch("Trending popular hits 2024");
  }

  Future<List<SongResult>> getRelatedSongs(String videoId) async {
    return await getUpNext(videoId);
  }

  Future<List<PlaylistResult>> searchPlaylists(String query) async {
    try {
      final response = await _dio.post(
        '/search?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "query": query,
          "params": "Eg-KAQwIABAAGAAgACgB" // Type: Playlists filter
        }),
      );

      final List<PlaylistResult> results = [];
      try {
        final contents = response.data['contents']
                ['tabbedSearchResultsRenderer']['tabs'][0]['tabRenderer']
            ['content']['sectionListRenderer']['contents'];

        for (var section in contents) {
          final items = section['musicShelfRenderer']?['contents'] ?? [];
          for (var item in items) {
            final renderer = item['musicResponsiveListItemRenderer'];
            if (renderer == null) continue;

            final title = renderer['flexColumns']?[0]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';
            final owner = renderer['flexColumns']?[1]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';
            final playlistId = renderer['navigationEndpoint']?['browseEndpoint']
                    ?['browseId'] ??
                '';
            final thumbnail = renderer['thumbnail']?['musicThumbnailRenderer']
                        ?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';

            if (playlistId.isNotEmpty && title.isNotEmpty) {
              results.add(PlaylistResult(
                id: playlistId,
                title: title,
                owner: owner,
                thumbnail: thumbnail,
              ));
            }
          }
        }
      } catch (e) {
        print('Playlist parse error: $e');
      }
      return results;
    } catch (e) {
      print('Playlist search error: $e');
      return [];
    }
  }

  Future<List<SongResult>> getPlaylistDetails(String browseId) async {
    try {
      final response = await _dio.post(
        '/browse?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "browseId": browseId,
        }),
      );

      final List<SongResult> results = [];
      try {
        final sectionList = response.data['contents']
                ['singleColumnBrowseResultsRenderer']['tabs'][0]['tabRenderer']
            ['content']['sectionListRenderer']['contents'];
        dynamic shelf;
        for (var s in sectionList) {
          if (s['musicPlaylistShelfRenderer'] != null) {
            shelf = s['musicPlaylistShelfRenderer'];
            break;
          }
        }

        if (shelf != null) {
          final contents = shelf['contents'];
          for (var item in contents) {
            final renderer = item['musicResponsiveListItemRenderer'];
            if (renderer == null) continue;

            final title = renderer['flexColumns']?[0]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';

            final artist = renderer['flexColumns']?[1]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';

            final videoId = renderer['playlistItemData']?['videoId'] ?? '';
            final thumbnail = renderer['thumbnail']?['musicThumbnailRenderer']
                        ?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';

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
        print('Playlist details parse error: $e');
      }
      return results;
    } catch (e) {
      print('Playlist details error: $e');
      return [];
    }
  }

  Future<Map<String, List<dynamic>>> getHomeFeed() async {
    try {
      final response = await _dio.post(
        '/browse?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "browseId": "FEmusic_home",
        }),
      );

      final Map<String, List<dynamic>> sections = {};
      try {
        final sectionList = response.data['contents']
                ['singleColumnBrowseResultsRenderer']['tabs'][0]['tabRenderer']
            ['content']['sectionListRenderer']['contents'];

        for (var section in sectionList) {
          final shelf = section['musicCarouselShelfRenderer'];
          if (shelf == null) continue;

          final title = shelf['header']
                      ?['musicCarouselShelfBasicHeaderRenderer']?['title']
                  ?['runs']?[0]?['text'] ??
              '';
          if (title.isEmpty) continue;

          final List<dynamic> items = [];
          for (var item in shelf['contents']) {
            final songRenderer = item['musicTwoRowItemRenderer'];
            if (songRenderer == null) continue;

            final itemTitle = songRenderer['title']?['runs']?[0]?['text'] ?? '';
            final itemId = songRenderer['navigationEndpoint']?['watchEndpoint']
                ?['videoId'];
            final playlistId = songRenderer['navigationEndpoint']
                ?['browseEndpoint']?['browseId'];
            final thumb = songRenderer['thumbnail']?['musicThumbnailRenderer']
                        ?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';

            if (itemTitle.isNotEmpty) {
              if (itemId != null) {
                final artist =
                    songRenderer['subtitle']?['runs']?[0]?['text'] ?? '';
                items.add(SongResult(
                    id: itemId,
                    title: itemTitle,
                    artist: artist,
                    thumbnail: thumb));
              } else if (playlistId != null) {
                final owner =
                    songRenderer['subtitle']?['runs']?[0]?['text'] ?? '';
                items.add(PlaylistResult(
                    id: playlistId,
                    title: itemTitle,
                    owner: owner,
                    thumbnail: thumb));
              }
            }
          }

          if (items.isNotEmpty) {
            sections[title] = items;
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

class PlaylistResult {
  final String id;
  final String title;
  final String owner;
  final String thumbnail;

  PlaylistResult({
    required this.id,
    required this.title,
    required this.owner,
    required this.thumbnail,
  });
}
