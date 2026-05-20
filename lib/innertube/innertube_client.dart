import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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

  String _hqThumb(String url) {
    if (url.isEmpty) return url;
    url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w576-h576-l90-rj');
    url = url.replaceAll(RegExp(r'=s\d+'), '=s576');
    return url;
  }

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
                  id: vid,
                  title: title,
                  artist: artist,
                  thumbnail: _hqThumb(thumb)));
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

  List<LyricLine> _assignTimings(List<String> lines, int totalDurationMs) {
    // Filter empty and section headers
    final valid = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !(l.startsWith('[') && l.endsWith(']')))
        .toList();

    if (valid.isEmpty) return [];

    // Distribute total song duration across lines
    // Longer lines get proportionally more time
    final totalChars = valid.fold(0, (sum, l) => sum + l.length);
    final List<LyricLine> result = [];

    // Start at 3% in (skip intro silence)
    int currentMs = (totalDurationMs * 0.03).round();
    // End at 96% (skip outro)
    final endMs = (totalDurationMs * 0.96).round();
    final availableMs = endMs - currentMs;

    for (final line in valid) {
      result.add(LyricLine(text: line, timeMs: currentMs));
      // Time proportional to character count
      final fraction = line.length / totalChars;
      currentMs += (availableMs * fraction).round();
    }

    return result;
  }

  Future<List<LyricLine>> fetchSyncedLyrics(
      String title, String artist, int durationSecs) async {
    try {
      // LRCLIB — free public API, no key needed
      final query = Uri.encodeComponent('$artist $title');
      final url = 'https://lrclib.net/api/search?q=$query';
      final resp = await _dio.get(url,
          options: Options(headers: {'User-Agent': 'REVIX One Music App'}));

      if (resp.data == null) return [];
      final results = resp.data as List;
      if (results.isEmpty) return [];

      // Find best match by duration
      Map<String, dynamic>? best;
      int bestDiff = 999999;
      for (final r in results) {
        if (r['syncedLyrics'] == null) continue;
        final dur = (r['duration'] as num?)?.toInt() ?? 0;
        final diff = (dur - durationSecs).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          best = r as Map<String, dynamic>;
        }
      }

      if (best == null || best['syncedLyrics'] == null) {
        // Fallback to plain lyrics with estimated timing
        return fetchLyrics(title.isEmpty ? artist : title);
      }

      // Parse LRC format: [mm:ss.xx] lyric line
      final lrc = best['syncedLyrics'] as String;
      final lines = lrc.split('\n');
      final List<LyricLine> result = [];
      final timeRegex = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');

      for (final line in lines) {
        final match = timeRegex.firstMatch(line);
        if (match == null) continue;
        final mins = int.parse(match.group(1)!);
        final secs = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();
        if (text.isEmpty) continue;
        final ms = (mins * 60 * 1000 + secs * 1000).round();
        result.add(LyricLine(text: text, timeMs: ms));
      }

      return result;
    } catch (e) {
      print('LRCLIB error: $e');
      return [];
    }
  }

  Future<List<LyricLine>> fetchLyrics(String videoId,
      {int songDurationMs = 210000}) async {
    try {
      // Step 1 — get the lyrics browseId from /next endpoint
      final nextResp = await _dio.post(
        '/next?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "videoId": videoId,
          "isAudioOnly": true,
        }),
      );

      String? browseId;

      // Try singleColumn layout (YouTube Music app layout)
      try {
        final tabs = nextResp.data['contents']
                ['singleColumnMusicWatchNextResultsRenderer']['tabbedRenderer']
            ['watchNextTabbedResultsRenderer']['tabs'];
        for (final tab in tabs) {
          final r = tab['tabRenderer'];
          if ((r?['title'] ?? '') == 'Lyrics') {
            browseId = r['endpoint']['browseEndpoint']['browseId'];
            break;
          }
        }
      } catch (_) {}

      // Try twoColumn layout fallback
      if (browseId == null) {
        try {
          // This block is a structural placeholder for alternate layouts
        } catch (_) {}
      }

      if (browseId == null || browseId.isEmpty) {
        print('No lyrics browseId for $videoId');
        return [];
      }

      // Step 2 — fetch the lyrics page
      final browseResp = await _dio.post(
        '/browse?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({"context": _context, "browseId": browseId}),
      );

      // Step 3 — extract text from response
      String? fullText;

      try {
        final runs = browseResp.data['contents']?['sectionListRenderer']
                ?['contents']?[0]?['musicDescriptionShelfRenderer']
            ?['description']?['runs'] as List?;
        if (runs != null && runs.isNotEmpty) {
          fullText = runs.map((r) => r['text'] as String).join('');
        }
      } catch (_) {}

      // Fallback path for different response structure
      if (fullText == null || fullText.isEmpty) {
        try {
          fullText = browseResp.data['contents']?['sectionListRenderer']
                  ?['contents']?[0]?['musicDescriptionShelfRenderer']
              ?['description']?['runs']?[0]?['text'];
        } catch (_) {}
      }

      if (fullText == null || fullText.isEmpty) return [];

      final rawLines = fullText.split('\n');
      final cleanLines =
          rawLines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

      // Return duration-aware assigned timings
      return _assignTimings(cleanLines, songDurationMs);
    } catch (e) {
      print('fetchLyrics error: $e');
      return [];
    }
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

      String _hqThumb(String url) {
        if (url.isEmpty) return url;
        url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w576-h576-l90-rj');
        url = url.replaceAll(RegExp(r'=s\d+'), '=s576');
        return url;
      }

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
                  thumbnail: _hqThumb(thumbnail)));
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

      String _hqThumb(String url) {
        if (url.isEmpty) return url;
        url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w576-h576-l90-rj');
        url = url.replaceAll(RegExp(r'=s\d+'), '=s576');
        return url;
      }

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
                thumbnail: _hqThumb(thumbnail),
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
    final hour = DateTime.now().hour;
    List<String> pool;
    if (hour >= 0 && hour < 7) {
      pool = [
        'late night chill songs',
        'midnight slow songs',
        '1am playlist',
        'night drive music',
        'slow romantic hindi night',
        'lofi beats late night',
        'sad songs midnight',
        'soft english songs night',
        'acoustic night vibes',
        'hindi soft songs 3am',
        'calm instrumental night',
        'neon lights chill',
      ];
    } else if (hour >= 7 && hour < 12) {
      pool = [
        'morning fresh hits ${DateTime.now().year}',
        'upbeat morning playlist',
        'good morning energy songs',
        'happy morning vibes',
        'pop morning hits',
        'bollywood morning songs',
        'fresh indie morning',
        'coffee shop morning music',
        'punjabi morning drive',
        'motivational morning songs',
        'sunrise playlist',
      ];
    } else if (hour >= 12 && hour < 17) {
      pool = [
        'top hits ${DateTime.now().year}',
        'trending songs today',
        'best bollywood ${DateTime.now().year}',
        'viral hits now',
        'top punjabi songs',
        'new english hits',
        'chart toppers this week',
        'popular songs afternoon',
        'best of arijit singh',
        'latest releases',
        'desi hip hop trending',
        'top global 50 songs',
      ];
    } else {
      pool = [
        'evening chill playlist',
        'sunset songs vibes',
        'after work relax music',
        'top hindi songs evening',
        'romantic evening songs',
        'best weekend playlist',
        'party songs trending',
        'dance hits ${DateTime.now().year}',
        'bollywood party songs',
        'groovy evening hits',
        'friday night playlist',
        'best of weekend vibes',
      ];
    }
    pool.shuffle();
    return freshSearch(pool.first);
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

      String _hqThumb(String url) {
        if (url.isEmpty) return url;
        url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w576-h576-l90-rj');
        url = url.replaceAll(RegExp(r'=s\d+'), '=s576');
        return url;
      }

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
                thumbnail: _hqThumb(thumbnail),
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

      String _hqThumb(String url) {
        if (url.isEmpty) return url;
        url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w576-h576-l90-rj');
        url = url.replaceAll(RegExp(r'=s\d+'), '=s576');
        return url;
      }

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
                thumbnail: _hqThumb(thumbnail),
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

      String _hqThumb(String url) {
        if (url.isEmpty) return url;
        url = url.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w576-h576-l90-rj');
        url = url.replaceAll(RegExp(r'=s\d+'), '=s576');
        return url;
      }

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
                    thumbnail: _hqThumb(thumb)));
              } else if (playlistId != null) {
                final owner =
                    songRenderer['subtitle']?['runs']?[0]?['text'] ?? '';
                items.add(PlaylistResult(
                    id: playlistId,
                    title: itemTitle,
                    owner: owner,
                    thumbnail: _hqThumb(thumb)));
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

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final url =
          'https://suggestqueries-clients.google.com/complete/search?client=youtube&hl=en&gl=us&q=${Uri.encodeComponent(query)}&ds=yt&oe=utf-8';
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        String body = response.data.toString();

        final startBracket = body.indexOf('[');
        final endBracket = body.lastIndexOf(']');
        if (startBracket == -1 || endBracket == -1) return [];

        final jsonStr = body.substring(startBracket, endBracket + 1);
        final data = jsonDecode(jsonStr);

        final List<String> suggestions = [];
        if (data is List && data.length > 1) {
          final sList = data[1];
          if (sList is List) {
            for (var item in sList) {
              if (item is List && item.isNotEmpty) {
                suggestions.add(item[0].toString());
              } else if (item is String) {
                suggestions.add(item);
              }
            }
          }
        }
        return suggestions;
      }
      return [];
    } catch (e) {
      debugPrint('Suggestions error: $e');
      return [];
    }
  }

  Future<List<ArtistResult>> searchArtists(String query) async {
    try {
      final response = await _dio.post(
        '/search?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "query": query,
          "params": "Eg-KAQwIABAAGAAgASgB" // Type: Artist filter
        }),
      );
      final List<ArtistResult> results = [];
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
                        ['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';
            final browseId = renderer['navigationEndpoint']?['browseEndpoint']
                    ?['browseId'] ??
                '';
            final thumb = renderer['thumbnail']?['musicThumbnailRenderer']
                        ?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';
            if (browseId.isNotEmpty && title.isNotEmpty) {
              results.add(ArtistResult(
                  id: browseId, name: title, thumbnail: _hqThumb(thumb)));
            }
          }
        }
      } catch (_) {}
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<List<AlbumResult>> searchAlbums(String query) async {
    try {
      final response = await _dio.post(
        '/search?key=$_apiKey&prettyPrint=false',
        data: jsonEncode({
          "context": _context,
          "query": query,
          "params": "Eg-KAQwIBAABGAAgACgB" // Type: Album filter
        }),
      );
      final List<AlbumResult> results = [];
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
                        ['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';
            final artist = renderer['flexColumns']?[1]
                        ['musicResponsiveListItemFlexColumnRenderer']?['text']
                    ?['runs']?[0]?['text'] ??
                '';
            final browseId = renderer['navigationEndpoint']?['browseEndpoint']
                    ?['browseId'] ??
                '';
            final thumb = renderer['thumbnail']?['musicThumbnailRenderer']
                        ?['thumbnail']?['thumbnails']
                    ?.last?['url'] ??
                '';
            if (browseId.isNotEmpty && title.isNotEmpty) {
              results.add(AlbumResult(
                  id: browseId,
                  title: title,
                  artist: artist,
                  thumbnail: _hqThumb(thumb)));
            }
          }
        }
      } catch (_) {}
      return results;
    } catch (_) {
      return [];
    }
  }
}

class LyricLine {
  final String text;
  final int timeMs;
  const LyricLine({required this.text, required this.timeMs});
}

class SongResult {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final bool isLocal;

  SongResult({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    this.isLocal = false,
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

class ArtistResult {
  final String id;
  final String name;
  final String thumbnail;
  ArtistResult({required this.id, required this.name, required this.thumbnail});
}

class AlbumResult {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  AlbumResult(
      {required this.id,
      required this.title,
      required this.artist,
      required this.thumbnail});
}
