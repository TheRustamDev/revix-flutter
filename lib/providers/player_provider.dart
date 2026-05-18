import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/music_service.dart';
import '../innertube/innertube_client.dart';
import '../innertube/recommendations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'theme_provider.dart';

MediaItem songToMediaItem(SongResult song) => MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: song.thumbnail.isNotEmpty ? Uri.parse(song.thumbnail) : null,
      extras: {'videoId': song.id},
    );

class PlayerProvider extends ChangeNotifier {
  final MusicHandler _handler;
  final InnerTubeClient _innerTube = InnerTubeClient();
  final YouTubeMusicRecommendations _recommendations =
      YouTubeMusicRecommendations();
  final yt_exp.YoutubeExplode _yt = yt_exp.YoutubeExplode();
  final Dio _dio = Dio();

  late final StreamSubscription<MediaItem?> _mediaItemSub;
  late final StreamSubscription<PlaybackState> _playbackSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  ThemeProvider? _themeProvider;
  void attachTheme(ThemeProvider t) => _themeProvider = t;

  MediaItem? currentSong;
  bool isPlaying = false;
  bool isLoading = false;
  bool isBuffering = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  List<MediaItem> queue = [];
  int currentIndex = 0;
  AudioServiceRepeatMode repeatMode = AudioServiceRepeatMode.none;
  bool shuffleEnabled = false;

  List<SongResult> searchResults = [];
  bool isSearching = false;
  String searchError = '';
  final List<MediaItem> recentlyPlayed = [];

  List<SongResult> quickPicks = [];
  bool isLoadingPicks = false;

  // Home Sections
  final Map<String, List<SongResult>> homeSections = {};
  final Map<String, List<PlaylistResult>> homePlaylists = {};
  bool isLoadingHome = false;

  // New Player Features
  String audioQuality = 'Normal'; // Normal, High, Lossless
  bool autoPlay = true;
  final Set<String> _likedIds = {};
  final Set<String> _downloadingIds = {};
  final Set<String> _downloadedIds = {};
  final Map<String, double> downloadProgress = {};
  final Map<String, String> _downloadPaths = {}; // videoId -> localPath
  final Map<String, Map<String, String>> _downloadedMetadata = {};
  final Map<String, Map<String, String>> _likedMetadata = {};

  // Sleep Timer
  Timer? _sleepTimer;
  int sleepTimerRemaining = 0; // seconds
  bool _sleepAfterSong = false;

  // Taste profile — persisted in Hive
  Box? _tasteBox;
  Box? _settingsBox;
  Box? _libraryBox;

  // In-memory taste weights
  final Map<String, double> _artistWeight = {};
  final Map<String, double> _genreWeight = {};
  final Set<String> _playedIds = {};

  // Track when current song started playing
  DateTime? _songStartTime;

  // Query history to avoid repeating
  final List<String> _usedQueries = [];
  int _sessionSeed = 0;
  bool _autoQueuing = false;

  // Lyrics
  List<LyricLine> lyricLines = [];
  bool isLyricsLoading = false;
  int currentLyricIndex = 0;

  PlayerProvider(this._handler) {
    Future.microtask(() {
      _initTaste();
      _initNotifications();
    });

    _mediaItemSub = _handler.mediaItem.listen((item) {
      if (item != null &&
          currentSong != null &&
          currentSong!.id != item.id &&
          _songStartTime != null) {
        // Check if previous song was skipped quickly
        final listenDuration =
            DateTime.now().difference(_songStartTime!).inSeconds;
        if (listenDuration < 30) {
          _penalizeSong(currentSong!.artist ?? '', currentSong!.title);
        } else {
          _boostSong(
              currentSong!.artist ?? '', currentSong!.title, currentSong!.id);
        }
      }

      currentSong = item;
      _songStartTime = DateTime.now();
      duration = item?.duration ?? Duration.zero;

      if (item != null) {
        recentlyPlayed.removeWhere((s) => s.id == item.id);
        recentlyPlayed.insert(0, item);
        if (recentlyPlayed.length > 50) recentlyPlayed.removeLast();
        _saveRecent();

        // Auto queue when less than 3 songs remaining
        final remaining = queue.length - currentIndex - 1;
        if (remaining < 3) Future.microtask(() => _smartAutoQueue());

        if (item.artUri != null) {
          Future.microtask(
              () => _themeProvider?.updateFromUrl(item.artUri.toString()));
        }
        Future.microtask(() => fetchLyrics(item.id));
      }
      notifyListeners();
    });

    _playbackSub = _handler.playbackState.listen((state) {
      isPlaying = state.playing;
      isLoading = state.processingState == AudioProcessingState.loading;
      isBuffering = state.processingState == AudioProcessingState.buffering;
      queue = _handler.currentQueue;
      currentIndex = _handler.currentIndex;

      if (state.processingState == AudioProcessingState.completed) {
        if (_sleepAfterSong) {
          pause();
          _sleepAfterSong = false;
          notifyListeners();
        } else if (autoPlay && currentSong != null) {
          Future.microtask(() => _smartAutoQueue());
        }
      }

      final d = _handler.player.duration;
      if (d != null && d.inMilliseconds > 0) {
        duration = d;
      }
      notifyListeners();
    });

    _durationSub = _handler.player.durationStream.listen((d) {
      if (d != null && d.inMilliseconds > 0) {
        duration = d;
        notifyListeners();
      }
    });

    _positionSub = AudioService.position.listen((pos) {
      position = pos;
      // Update active lyric line
      if (lyricLines.isNotEmpty) {
        final ms = pos.inMilliseconds;
        int newIndex = 0;
        for (int i = 0; i < lyricLines.length; i++) {
          if (lyricLines[i].startMs <= ms)
            newIndex = i;
          else
            break;
        }
        if (newIndex != currentLyricIndex) {
          currentLyricIndex = newIndex;
        }
      }
      notifyListeners();
    });

    fetchQuickPicks();
    fetchHomeSections();
  }

  Future<void> _initTaste() async {
    _tasteBox = await Hive.openBox('taste_profile');
    _settingsBox = await Hive.openBox('settings');
    _libraryBox = await Hive.openBox('library');

    // Load Settings
    audioQuality = _settingsBox!.get('audioQuality', defaultValue: 'Normal');
    autoPlay = _settingsBox!.get('autoPlay', defaultValue: true);

    // Load saved download paths
    final savedPaths = _libraryBox!.get('download_paths', defaultValue: {});
    (savedPaths as Map)
        .forEach((k, v) => _downloadPaths[k.toString()] = v.toString());
    final downloaded = _libraryBox!.get('downloaded_ids', defaultValue: []);
    _downloadedIds.addAll((downloaded as List).map((e) => e.toString()));
    final savedMetadata =
        _libraryBox!.get('download_metadata', defaultValue: {});
    (savedMetadata as Map).forEach((k, v) =>
        _downloadedMetadata[k.toString()] = Map<String, String>.from(v));

    final savedLikes = _libraryBox!.get('liked_ids', defaultValue: []);
    _likedIds.addAll(savedLikes.map((e) => e.toString()));
    final likedMeta = _libraryBox!.get('liked_metadata', defaultValue: {});
    (likedMeta as Map).forEach(
        (k, v) => _likedMetadata[k.toString()] = Map<String, String>.from(v));

    // Load Recently Played
    final savedRecent = _libraryBox!.get('recently_played', defaultValue: []);
    recentlyPlayed.clear();
    for (var m in savedRecent as List) {
      final map = Map<String, dynamic>.from(m);
      recentlyPlayed.add(MediaItem(
        id: map['id'],
        title: map['title'],
        artist: map['artist'],
        artUri: map['artUri'] != null ? Uri.parse(map['artUri']) : null,
        extras: Map<String, dynamic>.from(map['extras'] ?? {}),
      ));
    }

    // Load saved weights
    final savedArtist = _tasteBox!.get('artist_weights', defaultValue: {});
    final savedGenre = _tasteBox!.get('genre_weights', defaultValue: {});

    (savedArtist as Map)
        .forEach((k, v) => _artistWeight[k.toString()] = (v as num).toDouble());
    (savedGenre as Map)
        .forEach((k, v) => _genreWeight[k.toString()] = (v as num).toDouble());

    final played = _tasteBox!.get('played_ids', defaultValue: []);
    _playedIds.addAll((played as List).map((e) => e.toString()));

    // Unique session seed based on time
    _sessionSeed = DateTime.now().millisecondsSinceEpoch % 10000;
  }

  Future<void> _saveTaste() async {
    await _tasteBox?.put(
        'artist_weights', Map<String, double>.from(_artistWeight));
    await _tasteBox?.put(
        'genre_weights', Map<String, double>.from(_genreWeight));
    final recentPlayed = _playedIds.toList();
    if (recentPlayed.length > 200)
      recentPlayed.removeRange(0, recentPlayed.length - 200);
    await _tasteBox?.put('played_ids', recentPlayed);
  }

  Future<void> _saveRecent() async {
    final list = recentlyPlayed
        .map((m) => {
              'id': m.id,
              'title': m.title,
              'artist': m.artist,
              'artUri': m.artUri?.toString(),
              'extras': m.extras,
            })
        .toList();
    await _libraryBox?.put('recently_played', list);
  }

  void removeFromHistory(String id) {
    recentlyPlayed.removeWhere((s) => s.id == id);
    _saveRecent();
    notifyListeners();
  }

  void shareSong(String title, String artist, String videoId) {
    const platform = MethodChannel('com.revixone/share');
    try {
      platform.invokeMethod('share', {
        'text':
            'Listening to "$title" by $artist on REVIX One 🎵\nhttps://music.youtube.com/watch?v=$videoId',
      });
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }

  String _detectGenre(String title, String artist) {
    final text = '$title $artist'.toLowerCase();

    if (text.contains(RegExp(
        r'lofi|lo-fi|chill beat|study music|relax|ambient|coffee shop|mellow|calm')))
      return 'lofi';
    if (text.contains(RegExp(
        r'punjabi|bhangra|shubh|ap dhillon|diljit|sidhu|karan|babbal|amrit maan|gurinder|sidhu moose wala|jordan sandhu|nseeeb')))
      return 'punjabi';
    if (text.contains(RegExp(
        r'arijit|atif|armaan|jubin|romantic|ishq|dil|love song hindi|kumarsanu|udit narayan|alka yagnik|sonu nigam|shreya ghoshal')))
      return 'bollywood_romantic';
    if (text.contains(RegExp(
        r'rap|hip.?hop|trap|drake|kendrick|eminem|j cole|lil |kanye|21 savage|future|post malone|travis scott|badshah|raftaar|kr$na|divine|emiway')))
      return 'hiphop';
    if (text.contains(RegExp(
        r'weeknd|pop|taylor|ed sheeran|justin bieber|billie|ariana|dua lipa|shawn mendes|bruno mars|katy perry|rihanna')))
      return 'pop';
    if (text.contains(RegExp(
        r'edm|electronic|dj |remix|bass|techno|house|avicii|martin garrix|skrillex|tiesto|marshmello|alan walker|david guetta')))
      return 'electronic';
    if (text.contains(RegExp(
        r'indie|rock|nirvana|beatles|queen|pink floyd|coldplay|arctic monkeys|tame impala|alternative')))
      return 'rock_indie';
    if (text
        .contains(RegExp(r'kpop|bts|blackpink|twice|exo|stray kids|newjeans')))
      return 'kpop';
    if (text.contains(
        RegExp(r'bollywood|hindi|filmi|movie|film|kumar|singh|sharma')))
      return 'bollywood';
    if (text
        .contains(RegExp(r'workout|gym|energy|beast|power|motivation|hard')))
      return 'workout';
    if (text.contains(RegExp(r'r&b|rnb|soul|neo.?soul|slow jam'))) return 'rnb';
    if (text.contains(RegExp(r'classical|instrumental|piano|violin|orchestra')))
      return 'classical';
    return 'general';
  }

  void _boostSong(String artist, String title, String songId) {
    // Boost artist
    _artistWeight[artist] = (_artistWeight[artist] ?? 0) + 1.0;
    // Boost genre
    final genre = _detectGenre(title, artist);
    _genreWeight[genre] = (_genreWeight[genre] ?? 0) + 1.0;
    _playedIds.add(songId);
    Future.microtask(() => _saveTaste());
  }

  void _penalizeSong(String artist, String title) {
    // Skipped quickly — reduce weights slightly
    _artistWeight[artist] =
        ((_artistWeight[artist] ?? 0) - 0.3).clamp(-2.0, 100.0);
    final genre = _detectGenre(title, artist);
    _genreWeight[genre] = ((_genreWeight[genre] ?? 0) - 0.3).clamp(-2.0, 100.0);
    Future.microtask(() => _saveTaste());
  }

  String _buildQuery() {
    _sessionSeed++;

    // Sort genres and artists by weight, exclude negative weights
    final topGenres = _genreWeight.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topArtists = _artistWeight.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasGenre = topGenres.isNotEmpty;
    final hasArtist = topArtists.isNotEmpty;

    // Build candidate queries
    final candidates = <String>[];

    if (hasArtist && hasGenre) {
      final g = topGenres[_sessionSeed % topGenres.length.clamp(1, 5)].key;
      final a = topArtists[_sessionSeed % topArtists.length.clamp(1, 5)].key;
      candidates.addAll([
        'best $g songs',
        'songs like $a',
        '$a mix playlist',
        'top $g hits ${2022 + (_sessionSeed % 3)}',
        '$g artists like $a',
        'if you like $a',
        '$a similar songs',
        'best of $g ${2023 + (_sessionSeed % 2)}',
      ]);
    } else if (hasGenre) {
      final g = topGenres[_sessionSeed % topGenres.length.clamp(1, 3)].key;
      candidates.addAll([
        'top $g songs',
        'best $g playlist',
        '$g hits',
        'new $g music',
      ]);
    } else if (hasArtist) {
      final a = topArtists[0].key;
      candidates.addAll([
        'songs like $a',
        '$a type music',
        'artists similar to $a',
      ]);
    } else {
      // No taste data yet — diverse rotating defaults
      final defaults = [
        'trending songs today',
        'top hits right now',
        'viral music 2024',
        'best songs this week',
        'popular music trending',
        'new releases 2024',
        'top bollywood 2024',
        'best hip hop 2024',
        'chill playlist 2024',
        'top english hits',
        'top punjabi songs',
        'best romantic songs',
        'workout music 2024',
        'indie songs 2024',
        'top pop songs now',
      ];
      candidates.addAll(defaults);
    }

    // Pick one not recently used
    String chosen = candidates.first;
    for (final q in candidates) {
      if (!_usedQueries.contains(q)) {
        chosen = q;
        break;
      }
    }

    // Track used queries (keep last 20)
    _usedQueries.add(chosen);
    if (_usedQueries.length > 20) _usedQueries.removeAt(0);

    return chosen;
  }

  Future<void> _smartAutoQueue() async {
    if (_autoQueuing || !autoPlay) return;
    _autoQueuing = true;
    try {
      List<SongResult> candidates = [];

      // Step 1: Try YouTube Music's real recommendations for autoplay
      if (currentSong != null) {
        candidates = await _recommendations
            .getWatchNext(currentSong!.id)
            .timeout(const Duration(seconds: 10), onTimeout: () => []);
      }

      // Step 2: Fallback to smart search if empty
      if (candidates.isEmpty) {
        final query = _buildQuery();
        candidates = await _innerTube
            .freshSearch(query)
            .timeout(const Duration(seconds: 10), onTimeout: () => []);
      }

      // Step 3: Filter played + already in queue
      final queueIds = queue.map((q) => q.id).toSet();
      final filtered = candidates
          .where((s) =>
              !_playedIds.contains(s.id) &&
              !queueIds.contains(s.id) &&
              s.title.isNotEmpty)
          .toList();

      // Step 4: Add up to 10 recommendations to keep queue healthy
      for (final song in filtered.take(10)) {
        await _handler.addToQueue(songToMediaItem(song));
      }

      queue = _handler.currentQueue;
      Future.microtask(() => notifyListeners());
    } catch (e) {
      print('SmartAutoQueue error: $e');
    } finally {
      _autoQueuing = false;
    }
  }

  Future<void> fetchHomeSections() async {
    if (isLoadingHome) return;
    isLoadingHome = true;
    notifyListeners();

    try {
      final feed = await _innerTube.getHomeFeed();
      if (feed.isNotEmpty) {
        homeSections.clear();
        homePlaylists.clear();
        feed.forEach((title, items) {
          if (items.isNotEmpty) {
            final songs = items.whereType<SongResult>().toList();
            if (songs.isNotEmpty) homeSections[title] = songs;

            final playlists = items.whereType<PlaylistResult>().toList();
            if (playlists.isNotEmpty) homePlaylists[title] = playlists;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching home feed: $e');
    } finally {
      isLoadingHome = false;
      notifyListeners();
    }
  }

  Future<void> refreshHomeRecommendations() => fetchHomeSections();

  Future<void> fetchQuickPicks() async {
    isLoadingPicks = true;
    notifyListeners();
    try {
      quickPicks = await _innerTube.getQuickPicks();
    } catch (e) {
      debugPrint('Error fetching picks: $e');
    } finally {
      isLoadingPicks = false;
      notifyListeners();
    }
  }

  List<MediaItem> get downloadedSongs {
    return queue.where((item) => _downloadedIds.contains(item.id)).toList();
  }

  // If downloaded songs aren't in queue (unlikely in this logic but possible),
  // we would fetch them from a dedicated box. For now, we'll return recentlyPlayed as proxy
  List<MediaItem> get historySongs => recentlyPlayed;

  int get likedSongsCount => _likedIds.length;
  int get downloadedSongsCount => _downloadedIds.length;

  List<String> get topArtists {
    var sorted = _artistWeight.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(5).toList();
  }

  String get topGenre {
    if (_genreWeight.isEmpty) return 'General';
    var sorted = _genreWeight.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Future<void> playTrack(MediaItem item) async {
    final localPath = _downloadPaths[item.id];
    MediaItem itemToPlay = item;

    if (localPath != null && await File(localPath).exists()) {
      itemToPlay = item.copyWith(extras: {
        ...item.extras ?? {},
        'url': Uri.file(localPath).toString(),
        'isLocal': true,
      });
    }

    // History & Taste tracking
    if (!recentlyPlayed.any((s) => s.id == itemToPlay.id)) {
      recentlyPlayed.insert(0, itemToPlay);
      if (recentlyPlayed.length > 50) recentlyPlayed.removeLast();
      _saveRecent();
    }
    _boostSong(itemToPlay.artist ?? 'Unknown', itemToPlay.title, itemToPlay.id);

    if (!queue.any((q) => q.id == itemToPlay.id)) {
      await _handler.loadQueue([itemToPlay]);
    } else {
      final idx = queue.indexWhere((q) => q.id == itemToPlay.id);
      await _handler.skipToQueueItem(idx);
    }
    await _handler.play();
  }

  Future<void> playSong(SongResult song) async {
    final item = songToMediaItem(song);
    await playTrack(item);
  }

  Future<void> playSongList(List<SongResult> songs,
      {int startIndex = 0}) async {
    await _handler.loadQueue(songs.map(songToMediaItem).toList(),
        startIndex: startIndex);
  }

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> togglePlayPause() async =>
      isPlaying ? await pause() : await play();
  Future<void> skipToNext() => _handler.skipToNext();
  Future<void> skipToPrevious() => _handler.skipToPrevious();
  Future<void> skipToQueueItem(int index) async {
    await _handler.skipToQueueItem(index);
  }

  Future<void> seekTo(Duration position) => _handler.seek(position);

  Future<void> addToQueue(SongResult song) async {
    await _handler.addToQueue(songToMediaItem(song));
    queue = _handler.currentQueue;
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    repeatMode = switch (repeatMode) {
      AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
      AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.none,
    };
    await _handler.setRepeatMode(repeatMode);
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    shuffleEnabled = !shuffleEnabled;
    await _handler.setShuffleMode(
      shuffleEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
    );
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    // Learn from search query itself
    final genre = _detectGenre(query, '');
    if (genre != 'general') {
      _genreWeight[genre] = (_genreWeight[genre] ?? 0) + 0.5;
      Future.microtask(() => _saveTaste());
    }

    isSearching = true;
    searchError = '';
    searchResults = [];
    notifyListeners();
    try {
      final raw = await _innerTube
          .freshSearch(query)
          .timeout(const Duration(seconds: 12), onTimeout: () => []);
      // Filter already played if enough results
      if (raw.length > 6 && _playedIds.length > 3) {
        final filtered = raw.where((s) => !_playedIds.contains(s.id)).toList();
        searchResults = filtered.isNotEmpty ? filtered : raw;
      } else {
        searchResults = raw;
      }
    } catch (e) {
      searchError = 'Search failed: $e';
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<List<SongResult>> getSongVersions(String title, String artist) async {
    try {
      final query = "$title $artist versions";
      final results = await _innerTube.freshSearch(query);

      // Filter: must contain part of original title to be relevant
      final originalLower =
          title.toLowerCase().split(' (')[0].split(' - ')[0].trim();
      final versions = results.where((s) {
        final titleLower = s.title.toLowerCase();
        return titleLower.contains(originalLower);
      }).toList();

      // Sort: Prioritize strings with keywords
      const keywords = [
        'slowed',
        'reverb',
        'speed',
        'sped',
        '3d',
        '8d',
        'unplugged',
        'acoustic',
        'remix',
        'lofi'
      ];
      versions.sort((a, b) {
        int scoreA = keywords.fold(
            0, (prev, k) => prev + (a.title.toLowerCase().contains(k) ? 1 : 0));
        int scoreB = keywords.fold(
            0, (prev, k) => prev + (b.title.toLowerCase().contains(k) ? 1 : 0));
        return scoreB.compareTo(scoreA);
      });

      return versions;
    } catch (e) {
      debugPrint('Error fetching versions: $e');
      return [];
    }
  }

  Future<void> fetchPlaylistContent(String playlistId) async {
    isSearching = true;
    searchResults = [];
    notifyListeners();
    try {
      searchResults = await _innerTube.getPlaylistDetails(playlistId);
    } catch (e) {
      debugPrint('Playlist load error: $e');
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    searchResults = [];
    searchError = '';
    notifyListeners();
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  String get positionLabel => _fmt(position);
  String get durationLabel => _fmt(duration);
  String _fmt(Duration d) =>
      '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  // Quality & Likes
  void setAudioQuality(String val) {
    audioQuality = val;
    _settingsBox?.put('audioQuality', val);
    notifyListeners();
  }

  void setAutoPlay(bool val) {
    autoPlay = val;
    _settingsBox?.put('autoPlay', val);
    notifyListeners();
  }

  bool isLiked(String? id) => id != null && _likedIds.contains(id);
  void toggleLike(MediaItem? item) {
    if (item == null) return;
    if (_likedIds.contains(item.id)) {
      _likedIds.remove(item.id);
      _likedMetadata.remove(item.id);
    } else {
      _likedIds.add(item.id);
      _likedMetadata[item.id] = {
        'title': item.title,
        'artist': item.artist ?? 'Unknown',
        'thumbnail': item.artUri?.toString() ?? '',
      };
    }
    _libraryBox?.put('liked_ids', _likedIds.toList());
    _libraryBox?.put('liked_metadata', _likedMetadata);
    notifyListeners();
  }

  void toggleLikeSong(SongResult? song) {
    if (song == null) return;
    if (_likedIds.contains(song.id)) {
      _likedIds.remove(song.id);
      _likedMetadata.remove(song.id);
    } else {
      _likedIds.add(song.id);
      _likedMetadata[song.id] = {
        'title': song.title,
        'artist': song.artist,
        'thumbnail': song.thumbnail,
      };
    }
    _libraryBox?.put('liked_ids', _likedIds.toList());
    _libraryBox?.put('liked_metadata', _likedMetadata);
    notifyListeners();
  }

  bool isDownloaded(String? id) => id != null && _downloadedIds.contains(id);
  bool isDownloading(String? id) => id != null && _downloadingIds.contains(id);

  List<SongResult> getLikedSongs() {
    return _likedIds.map((id) {
      final meta = _likedMetadata[id]!;
      return SongResult(
        id: id,
        title: meta['title']!,
        artist: meta['artist']!,
        thumbnail: meta['thumbnail']!,
      );
    }).toList();
  }

  List<SongResult> getDownloadedSongs() {
    return _downloadPaths.entries.map((e) {
      final meta = _downloadedMetadata[e.key];
      if (meta != null) {
        return SongResult(
          id: e.key,
          title: meta['title'] ?? 'Unknown',
          artist: meta['artist'] ?? 'Unknown',
          thumbnail: meta['thumbnail'] ?? '',
        );
      }
      // Fallback
      return SongResult(
        id: e.key,
        title: 'Downloaded Song',
        artist: 'Offline',
        thumbnail: '',
      );
    }).toList();
  }

  Future<void> downloadTrack(MediaItem? item) async {
    if (item == null) return;
    if (_downloadedIds.contains(item.id)) return;
    if (_downloadingIds.contains(item.id)) return;

    if (Platform.isAndroid) {
      if (await Permission.notification.request().isDenied) {
        // Just a courtesy request
      }
      // For Android/media, we only need basic storage or audio permissions (or sometimes nothing at all on newer APIs)
      await Permission.audio.request();
      await Permission.storage.request();
    }

    _downloadingIds.add(item.id);
    downloadProgress[item.id] = 0.0;
    notifyListeners();

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(
        item.id,
        ytClients: [yt_exp.YoutubeApiClient.androidVr],
      ).timeout(const Duration(seconds: 20));

      yt_exp.AudioStreamInfo stream;
      if (audioQuality == 'Lossless' || audioQuality == 'High') {
        stream = manifest.audioOnly.withHighestBitrate();
      } else {
        stream = manifest.audioOnly.firstWhere(
          (s) =>
              s.bitrate.bitsPerSecond >= 120000 &&
              s.bitrate.bitsPerSecond <= 160000,
          orElse: () => manifest.audioOnly.withHighestBitrate(),
        );
      }

      String filePath;
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(p.join(dir.path, 'downloads'));
      if (!await downloadsDir.exists())
        await downloadsDir.create(recursive: true);
      filePath = p.join(downloadsDir.path, '${item.id}.rvx');

      int lastNotify = 0;
      await _dio.download(
        stream.url.toString(),
        filePath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            final prog = count / total;
            downloadProgress[item.id] = prog;
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - lastNotify > 1000) {
              lastNotify = now;
              _showDownloadNotification(item.title, (prog * 100).toInt());
            }
            notifyListeners();
          }
        },
      );

      _downloadingIds.remove(item.id);
      _downloadedIds.add(item.id);
      _downloadPaths[item.id] = filePath;
      downloadProgress.remove(item.id);

      _downloadedMetadata[item.id] = {
        'title': item.title,
        'artist': item.artist ?? 'Unknown',
        'thumbnail': item.artUri?.toString() ?? '',
      };

      await _libraryBox?.put('downloaded_ids', _downloadedIds.toList());
      await _libraryBox?.put('download_paths', _downloadPaths);
      await _libraryBox?.put('download_metadata', _downloadedMetadata);

      _notifications.show(
        0,
        'Download Complete',
        item.title,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'downloads',
            'Downloads',
            importance: Importance.low,
            priority: Priority.low,
          ),
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Download error: $e');
      _downloadingIds.remove(item.id);
      downloadProgress.remove(item.id);
      notifyListeners();
    }
  }

  // Sleep Timer logic
  void setSleepAfterSong() {
    _sleepTimer?.cancel();
    sleepTimerRemaining = 0;
    _sleepAfterSong = true;
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    _sleepAfterSong = false;

    _sleepTimer?.cancel();
    sleepTimerRemaining = duration.inSeconds;
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sleepTimerRemaining > 0) {
        sleepTimerRemaining--;
        if (sleepTimerRemaining % 10 == 0) notifyListeners();
      } else {
        pause();
        timer.cancel();
        sleepTimerRemaining = 0;
        notifyListeners();
      }
    });
  }

  void cancelSleepTimer() {
    _sleepAfterSong = false;
    _sleepTimer?.cancel();
    sleepTimerRemaining = 0;

    notifyListeners();
  }

  @override
  void dispose() {
    _mediaItemSub.cancel();
    _playbackSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('mipmap/ic_launcher');
    const initSetting = InitializationSettings(android: android);
    await _notifications.initialize(initSetting);
  }

  void _showDownloadNotification(String title, int progress) {
    _notifications.show(
      0,
      'Downloading...',
      title,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'downloads',
          'Downloads',
          channelDescription: 'Download status',
          importance: Importance.high,
          priority: Priority.high,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          onlyAlertOnce: true,
          ongoing: true,
        ),
      ),
    );
  }

  Future<void> fetchLyrics(String videoId) async {
    isLyricsLoading = true;
    lyricLines = [];
    currentLyricIndex = 0;
    notifyListeners();
    try {
      lyricLines = await _innerTube.getTimedLyrics(videoId);
    } catch (e) {
      lyricLines = [];
    } finally {
      isLyricsLoading = false;
      notifyListeners();
    }
  }
}
