import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:ui' show Color;

Future<MusicHandler> initMusicService() async {
  return await AudioService.init(
    builder: () => MusicHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.revixone.app.channel.audio',
      androidNotificationChannelName: 'REVIX One',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      notificationColor: Color(0xFF8B5CF6),
      artDownscaleHeight: 300,
      artDownscaleWidth: 300,
    ),
  );
}

class MusicHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeExplode _yt = YoutubeExplode();
  final List<MediaItem> _queue = [];
  int _currentIndex = 0;

  MusicHandler() {
    _initPlayerListeners();
  }

  void _initPlayerListeners() {
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (e) => print('Playback event error: $e'),
    );

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) {
        _currentIndex = index;
        mediaItem.add(_queue[index]);
      }
    });

    // Keep alive — prevent system from killing service
    _player.playingStream.listen((playing) {
      _broadcastState();
    });
  }

  void _broadcastState() {
    final playing = _player.playing;
    final processingState = {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[_player.processingState]!;

    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  Future<void> playFromId(String videoId) async {
    // Set loading state
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
    ));

    int retries = 0;
    while (retries < 3) {
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(
          videoId,
          ytClients: [YoutubeApiClient.androidVr], // NEVER CHANGE
        ).timeout(const Duration(seconds: 20));

        final streamInfo = manifest.audioOnly.withHighestBitrate();

        await _player.setUrl(
          streamInfo.url.toString(),
          headers: {
            'User-Agent':
                'com.google.android.youtube/17.36.4 (Linux; U; Android 13) gzip',
            'Range': 'bytes=0-',
          },
        );

        // Update media item with duration once known
        if (_currentIndex < _queue.length) {
          final duration = _player.duration;
          if (duration != null) {
            final updated = _queue[_currentIndex].copyWith(
              duration: duration,
            );
            _queue[_currentIndex] = updated;
            mediaItem.add(updated);
          }
        }

        await _player.play();
        return; // success
      } catch (e) {
        retries++;
        print('Play attempt $retries failed: $e');
        if (retries >= 3) {
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
          ));
          rethrow;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> loadQueue(List<MediaItem> items, {int startIndex = 0}) async {
    _queue
      ..clear()
      ..addAll(items);
    queue.add(List.unmodifiable(_queue));
    if (_queue.isEmpty) return;
    _currentIndex = startIndex.clamp(0, _queue.length - 1);
    mediaItem.add(_queue[_currentIndex]);
    await playFromId(_queue[_currentIndex].id);
  }

  Future<void> loadPlaylist(List<MediaItem> items, {int startIndex = 0}) async {
    await loadQueue(items, startIndex: startIndex);
  }

  Future<void> addToQueue(MediaItem item) async {
    _queue.add(item);
    queue.add(List.unmodifiable(_queue));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      mediaItem.add(_queue[_currentIndex]);
      await playFromId(_queue[_currentIndex].id);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      mediaItem.add(_queue[_currentIndex]);
      await playFromId(_queue[_currentIndex].id);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    mediaItem.add(_queue[_currentIndex]);
    await playFromId(_queue[_currentIndex].id);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      default:
        await _player.setLoopMode(LoopMode.all);
    }
    await super.setRepeatMode(repeatMode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player
        .setShuffleModeEnabled(shuffleMode != AudioServiceShuffleMode.none);
    await super.setShuffleMode(shuffleMode);
  }

  // CRITICAL: do NOT stop on task removed — keep playing
  @override
  Future<void> onTaskRemoved() async {
    // Do nothing — music keeps playing when app is swiped away
  }

  // Keep service alive
  @override
  Future<void> onNotificationDeleted() async {
    await pause();
  }

  AudioPlayer get player => _player;
  List<MediaItem> get currentQueue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
}
