import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_exp;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/music_service.dart';
import '../innertube/innertube_client.dart';
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
  final yt_exp.YoutubeExplode _yt = yt_exp.YoutubeExplode();
  final Dio _dio = Dio();

  late final StreamSubscription<MediaItem?> _mediaItemSub;
  late final StreamSubscription<PlaybackState> _playbackSub;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;

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

  // Sleep Timer
  Timer? _sleepTimer;
  int sleepTimerRemaining = 0; // seconds

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

  PlayerProvider(this._handler) {
    Future.microtask(() => _initTaste()); // Load saved taste profile

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
        if (recentlyPlayed.length > 20) recentlyPlayed.removeLast();

        // Auto queue when less than 3 songs remaining
        final remaining = queue.length - currentIndex - 1;
        if (remaining < 3) Future.microtask(() => _smartAutoQueue());

        if (item.artUri != null) {
          Future.microtask(
              () => _themeProvider?.updateFromUrl(item.artUri.toString()));
        }
      }
      notifyListeners();
    });

    _playbackSub = _handler.playbackState.listen((state) {
      isPlaying = state.playing;
      isLoading = state.processingState == AudioProcessingState.loading;
      isBuffering = state.processingState == AudioProcessingState.buffering;
      queue = _handler.currentQueue;
      currentIndex = _handler.currentIndex;

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

    // Load Likes
    final likes = _libraryBox!.get('liked_ids', defaultValue: []);
    _likedIds.addAll((likes as List).map((e) => e.toString()));

    // Load saved download paths
    final savedPaths = _libraryBox!.get('download_paths', defaultValue: {});
    (savedPaths as Map)
        .forEach((k, v) => _downloadPaths[k.toString()] = v.toString());
    final downloaded = _libraryBox!.get('downloaded_ids', defaultValue: []);
    _downloadedIds.addAll((downloaded as List).map((e) => e.toString()));

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

  String _detectGenre(String title, String artist) {
    final text = '$title $artist'.toLowerCase();
    if (text.contains(RegExp(r'lofi|lo-fi|chill beat|study music')))
      return 'lofi';
    if (text.contains(
        RegExp(r'punjabi|bhangra|shubh|ap dhillon|diljit|sidhu|karan|babbal')))
      return 'punjabi';
    if (text.contains(
        RegExp(r'arijit|atif|armaan|jubin|romantic|ishq|dil|love song hindi')))
      return 'romantic_hindi';
    if (text.contains(
        RegExp(r'rap|hip.?hop|trap|drake|kendrick|eminem|j cole|lil ')))
      return 'hiphop';
    if (text.contains(
        RegExp(r'weeknd|pop|taylor|ed sheeran|justin bieber|billie|ariana')))
      return 'pop';
    if (text.contains(RegExp(
        r'edm|electronic|dj |remix|bass|techno|house|avicii|martin garrix')))
      return 'electronic';
    if (text.contains(
        RegExp(r'bollywood|hindi|filmi|movie|film|kumar|singh|sharma')))
      return 'bollywood';
    if (text
        .contains(RegExp(r'workout|gym|energy|beast|power|motivation|hard')))
      return 'workout';
    if (text.contains(RegExp(r'indie|alternative|acoustic|folk|unplugged')))
      return 'indie';
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
    if (_autoQueuing) return;
    _autoQueuing = true;
    try {
      List<SongResult> candidates = [];

      // Step 1: Try YouTube Music's real "Up Next"
      if (currentSong != null) {
        candidates = await _innerTube
            .getUpNext(currentSong!.id)
            .timeout(const Duration(seconds: 10), onTimeout: () => []);
      }

      // Step 2: If UpNext failed or too few, use smart search
      if (candidates.length < 3) {
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

      // Step 4: Shuffle slightly for variety
      filtered.shuffle();

      // Add up to 5
      for (final song in filtered.take(5)) {
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

    // Use a temporary session set to keep songs unique across row sections
    final Set<String> sessionSeenIds = {};

    final playlistQueries = {
      'Top Charts': 'Official Music Charts India Today',
      'Global Hits': 'Top 50 Global Billboard Official',
      'iPop India': 'Official iPop India Top Hits Playlist',
    };

    final songQueries = {
      'Winner Energy': 'high energy workout motivational songs 2024',
      'Bollywood Party': 'best bollywood party songs 2024 latest',
      'Bollywood Fire': 'latest trending bollywood fire songs hits',
      'Haryanvi Party': 'non stop haryanvi party mashup 2024',
      'Tollywood': 'top 50 tollywood telugu hits 2024',
      'Mollywood': 'top 50 mollywood malayalam hits 2024',
      'Instagram Hits': 'viral trending instagram reels songs hits',
      'Mashups': 'best bollywood lofi mashup songs long',
      'Lofi India': 'bollywood lofi chill beats hindi 2024',
    };

    try {
      // 1. Fetch Playlists
      for (var entry in playlistQueries.entries) {
        final results = await _innerTube
            .searchPlaylists(entry.value)
            .timeout(const Duration(seconds: 12), onTimeout: () => []);
        if (results.isNotEmpty) {
          homePlaylists[entry.key] = results;
          notifyListeners();
        }
      }

      // 2. Fetch Songs with session-based uniqueness
      for (var entry in songQueries.entries) {
        final results = await _innerTube
            .freshSearch(entry.value)
            .timeout(const Duration(seconds: 15), onTimeout: () => []);

        final filtered = results.where((s) {
          if (sessionSeenIds.contains(s.id)) return false;
          sessionSeenIds.add(s.id);
          return true;
        }).toList();

        if (filtered.isNotEmpty) {
          homeSections[entry.key] = filtered;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching home sections: $e');
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
    } else {
      _likedIds.add(item.id);
    }
    _libraryBox?.put('liked_ids', _likedIds.toList());
    notifyListeners();
  }

  void toggleLikeSong(SongResult? song) {
    if (song == null) return;
    if (_likedIds.contains(song.id)) {
      _likedIds.remove(song.id);
    } else {
      _likedIds.add(song.id);
    }
    _libraryBox?.put('liked_ids', _likedIds.toList());
    notifyListeners();
  }

  bool isDownloaded(String? id) => id != null && _downloadedIds.contains(id);
  bool isDownloading(String? id) => id != null && _downloadingIds.contains(id);

  Future<void> downloadTrack(MediaItem? item) async {
    if (item == null) return;
    if (_downloadedIds.contains(item.id)) return;
    if (_downloadingIds.contains(item.id)) return;

    // Request permissions
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final extStatus = await Permission.manageExternalStorage.request();
        if (!extStatus.isGranted) return;
      }
    }

    _downloadingIds.add(item.id);
    downloadProgress[item.id] = 0.0;
    notifyListeners();

    try {
      // 1. Get Stream Manifest
      final manifest = await _yt.videos.streamsClient.getManifest(item.id);

      // 2. Select stream based on quality
      yt_exp.AudioStreamInfo stream;
      if (audioQuality == 'Lossless' || audioQuality == 'High') {
        stream = manifest.audioOnly.withHighestBitrate();
      } else {
        // Find a medium quality around 128kbps or fallback
        stream = manifest.audioOnly.firstWhere(
          (s) =>
              s.bitrate.bitsPerSecond >= 120000 &&
              s.bitrate.bitsPerSecond <= 160000,
          orElse: () => manifest.audioOnly.withHighestBitrate(),
        );
      }

      // 3. Prepare local path
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists())
        await downloadsDir.create(recursive: true);

      final filePath = '${downloadsDir.path}/${item.id}.m4a';

      // 4. Download with Dio
      await _dio.download(
        stream.url.toString(),
        filePath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            downloadProgress[item.id] = count / total;
            notifyListeners();
          }
        },
      );

      // 5. Success
      _downloadingIds.remove(item.id);
      _downloadedIds.add(item.id);
      _downloadPaths[item.id] = filePath;
      downloadProgress.remove(item.id);

      // Persist
      await _libraryBox?.put('downloaded_ids', _downloadedIds.toList());
      await _libraryBox?.put('download_paths', _downloadPaths);

      notifyListeners();
    } catch (e) {
      debugPrint('Download error: $e');
      _downloadingIds.remove(item.id);
      downloadProgress.remove(item.id);
      notifyListeners();
    }
  }

  // Sleep Timer logic
  void setSleepTimer(Duration duration) {
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
}
