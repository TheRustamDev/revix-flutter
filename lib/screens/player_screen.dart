import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/theme_provider.dart';
import '../providers/player_provider.dart';
import '../innertube/innertube_client.dart';
import 'canvas_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  bool _isVisualizerMode = true;
  double _rotationSpeedMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Stable as requested
    // final isPlaying = context.read<PlayerProvider>().isPlaying;
    // if (isPlaying) _spinController.repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(builder: (context, player, _) {
      // Rotation disabled as requested
      // if (player.isPlaying) {
      //   if (!_spinController.isAnimating) _spinController.repeat();
      // } else {
      //   if (_spinController.isAnimating) _spinController.stop();
      // }

      return Consumer<ThemeProvider>(builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            color: Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TOP BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A1A2E),
                            ),
                            child: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        Column(children: [
                          Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.graphic_eq,
                                color: Color(0xFFEC4899), size: 14),
                            SizedBox(width: 8),
                            Text('NOW PLAYING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                )),
                            SizedBox(width: 8),
                            Icon(Icons.graphic_eq,
                                color: Color(0xFFEC4899), size: 14),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            player.currentSong?.title ?? '',
                            style: const TextStyle(
                              color: Color(0xFFEC4899),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                        GestureDetector(
                          onTap: _showAdvancedOptions,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1A1A2E),
                            ),
                            child: const Icon(Icons.more_vert,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),

                    // MAIN CONTENT ROW (Artwork & Actions)
                    Expanded(
                      child: Center(
                        child: Row(
                          children: [
                            // LEFT: Artwork with Disco Orb
                            Expanded(
                              flex: 11,
                              child: Center(
                                child: SizedBox(
                                  width: 340,
                                  height: 340,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Beating Disco Orb
                                      if (_isVisualizerMode)
                                        AnimatedBuilder(
                                          animation: Listenable.merge([
                                            _spinController,
                                            _pulseController
                                          ]),
                                          builder: (_, __) => CustomPaint(
                                            size: const Size(320, 320),
                                            painter: _DiscoOrbPainter(
                                                _spinController.value,
                                                _pulseController.value),
                                          ),
                                        ),
                                      // ARTWORK GLOW
                                      Consumer<ThemeProvider>(
                                        builder: (_, theme, __) => Container(
                                          width: 260,
                                          height: 260,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.bgColor1
                                                    .withOpacity(0.8),
                                                blurRadius: 60,
                                                spreadRadius: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Core artwork
                                      GestureDetector(
                                        onTap: () => setState(() =>
                                            _isVisualizerMode =
                                                !_isVisualizerMode),
                                        onLongPress: _toggleImmersiveMode,
                                        child: RotationTransition(
                                          turns: _spinController,
                                          child: Container(
                                            width: 240,
                                            height: 240,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white12,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  blurRadius: 30,
                                                  spreadRadius: 5,
                                                )
                                              ],
                                            ),
                                            clipBehavior: Clip.hardEdge,
                                            child: player.currentSong?.artUri !=
                                                    null
                                                ? CachedNetworkImage(
                                                    memCacheWidth: 576,
                                                    memCacheHeight: 576,
                                                    maxWidthDiskCache: 576,
                                                    maxHeightDiskCache: 576,
                                                    filterQuality:
                                                        FilterQuality.high,
                                                    imageUrl: player
                                                        .currentSong!.artUri
                                                        .toString(),
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    color: const Color(
                                                        0xFF1A1A2E)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // RIGHT: Metadata & Vertical Options
                            Expanded(
                              flex: 9,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: _showSongInfo,
                                    child: Text(
                                      player.currentSong?.title ?? 'No Song',
                                      style: const TextStyle(
                                        color: Color(0xFFEC4899),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _showArtistProfile(
                                        player.currentSong?.artist ??
                                            'Unknown'),
                                    child: Text(
                                      player.currentSong?.artist ??
                                          'Unknown Artist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _vAction(Icons.auto_awesome_motion,
                                      'VERSIONS', const Color(0xFF8B5CF6),
                                      onTap: _showVersionsSheet),
                                  _vAction(
                                      player.isLiked(player.currentSong?.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      'Liked',
                                      const Color(0xFFEC4899), onTap: () {
                                    setState(() {});
                                    player.toggleLike(player.currentSong);
                                  }),
                                  _vAction(Icons.share_outlined, 'Share',
                                      const Color(0xFFFF6B00), onTap: () {
                                    context.read<PlayerProvider>().shareSong(
                                          player.currentSong?.title ?? '',
                                          player.currentSong?.artist ?? '',
                                          player.currentSong?.id ?? '',
                                        );
                                  }),
                                  _vAction(
                                      player.isDownloading(
                                              player.currentSong?.id)
                                          ? Icons.downloading
                                          : (player.isDownloaded(
                                                  player.currentSong?.id)
                                              ? Icons.download_done
                                              : Icons.download_outlined),
                                      player.isDownloading(
                                              player.currentSong?.id)
                                          ? 'Downloading...'
                                          : (player.isDownloaded(
                                                  player.currentSong?.id)
                                              ? 'Downloaded'
                                              : 'Download'),
                                      const Color(0xFF10B981),
                                      onTap: () => player
                                          .downloadTrack(player.currentSong),
                                      progress: player.downloadProgress[
                                          player.currentSong?.id]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // WAVEFORM & SEEKER
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(player.positionLabel,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                            Expanded(
                              child: SizedBox(
                                height: 30,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(40, (i) {
                                    final h = 2 +
                                        sin(i * 0.2 +
                                                    _waveController.value *
                                                        pi *
                                                        2)
                                                .abs() *
                                            (player.isPlaying ? 18 : 2);
                                    return Container(
                                      width: 2.5,
                                      height: h,
                                      decoration: BoxDecoration(
                                        color: i < 20
                                            ? const Color(0xFF8B5CF6)
                                                .withOpacity(0.6)
                                            : const Color(0xFFEC4899)
                                                .withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            Text(player.durationLabel,
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: SliderComponentShape.noOverlay,
                            activeTrackColor: Colors.white70,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFFEC4899),
                          ),
                          child: Slider(
                            value: player.duration.inMilliseconds > 0
                                ? player.progress.clamp(0.0, 1.0)
                                : 0.0,
                            onChanged: (v) {
                              if (player.duration.inMilliseconds > 0) {
                                player.seekTo(Duration(
                                  milliseconds:
                                      (v * player.duration.inMilliseconds)
                                          .round(),
                                ));
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // PLAYBACK CONTROLS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _cBtn(Icons.shuffle,
                            toggled: player.shuffleEnabled,
                            onTap: player.toggleShuffle),
                        _cBtn(Icons.skip_previous,
                            size: 28, onTap: player.skipToPrevious),

                        // Play/Pause with Glowing Ring
                        GestureDetector(
                          onTap: player.togglePlayPause,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, _) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEC4899).withOpacity(
                                        0.3 * _pulseController.value),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ],
                                border: Border.all(
                                  color:
                                      const Color(0xFFEC4899).withOpacity(0.8),
                                  width: 2,
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFEC4899).withOpacity(0.2),
                                    const Color(0xFF8B5CF6).withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                player.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),

                        _cBtn(Icons.skip_next,
                            size: 28, onTap: player.skipToNext),
                        _cBtn(Icons.repeat,
                            toggled: player.repeatMode !=
                                AudioServiceRepeatMode.none,
                            onTap: player.toggleRepeat),
                      ],
                    ),

                    const SizedBox(height: 100),

                    // BOTTOM ACCESSORY ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Queue with Badge
                        Expanded(
                          child: GestureDetector(
                            onTap: _showQueueSheet,
                            child: _accPill(Icons.queue_music, 'Queue',
                                const Color(0xFF8B5CF6),
                                badge: player.queue.length.toString()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sleep (Moon)
                        GestureDetector(
                          onTap: _showSleepTimerFromPlayer,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A1A2E),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Icon(Icons.nightlight_round,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Canvas
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CanvasScreen())),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A1A2E),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Icon(Icons.palette_outlined,
                                color: Color(0xFF0EA5E9), size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Lyrics
                        Expanded(
                          child: GestureDetector(
                            onTap: _showLyricsSheet,
                            child: _accPill(Icons.chat_bubble_outline, 'Lyrics',
                                const Color(0xFFFF6B00)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 10), // Minimal bottom margin for accessories
                  ],
                ),
              ),
            ),
          ),
        );
      });
    });
  }

  void _showAdvancedOptions() {
    final player = context.read<PlayerProvider>();
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgColor1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Consumer<PlayerProvider>(
        builder: (ctx, p, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              // Song header
              Row(children: [
                if (p.currentSong?.artUri != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                        memCacheWidth: 576,
                        memCacheHeight: 576,
                        maxWidthDiskCache: 576,
                        maxHeightDiskCache: 576,
                        filterQuality: FilterQuality.high,
                        imageUrl: p.currentSong!.artUri.toString(),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover),
                  ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.currentSong?.title ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(p.currentSong?.artist ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                )),
              ]),
              const Divider(color: Colors.white10, height: 28),
              _optionTile(
                  Icons.favorite_border_rounded,
                  p.isLiked(p.currentSong?.id)
                      ? 'Remove from Liked'
                      : 'Add to Liked',
                  const Color(0xFFEC4899), () {
                p.toggleLike(p.currentSong);
                Navigator.pop(context);
              }),
              _optionTile(Icons.download_rounded, 'Download Song',
                  const Color(0xFF8B5CF6), () {
                p.downloadTrack(p.currentSong);
                Navigator.pop(context);
              }),
              _optionTile(
                  Icons.share_rounded, 'Share Song', const Color(0xFF0EA5E9),
                  () {
                Navigator.pop(context);
                context.read<PlayerProvider>().shareSong(
                      p.currentSong?.title ?? '',
                      p.currentSong?.artist ?? '',
                      p.currentSong?.id ?? '',
                    );
              }),
              _optionTile(Icons.queue_music_rounded, 'Add to Queue',
                  const Color(0xFF10B981), () {
                if (p.currentSong != null) {
                  final s = SongResult(
                      id: p.currentSong!.id,
                      title: p.currentSong!.title,
                      artist: p.currentSong!.artist ?? '',
                      thumbnail: p.currentSong!.artUri?.toString() ?? '');
                  p.addToQueue(s);
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Added to queue'),
                    backgroundColor: Color(0xFF8B5CF6)));
              }),
              _optionTile(
                  Icons.timer_rounded, 'Sleep Timer', const Color(0xFFFFD700),
                  () {
                Navigator.pop(context);
                _showSleepTimerFromPlayer();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20)),
        title: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
        onTap: onTap,
      );

  void _showSleepTimerFromPlayer() {
    final player = context.read<PlayerProvider>();
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgColor1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Sleep Timer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Music will stop after selected time.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            ...[
              '15 minutes',
              '30 minutes',
              '45 minutes',
              '60 minutes',
              'End of song'
            ].map((t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timer_outlined,
                      color: Color(0xFF8B5CF6), size: 22),
                  title: Text(t,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 15)),
                  onTap: () {
                    final mins = int.tryParse(t.split(' ')[0]);
                    if (mins != null && mins > 0) {
                      player.setSleepTimer(Duration(minutes: mins));
                    } else {
                      // End of song — handled by processingState listener
                      player.setSleepTimer(const Duration(hours: 99));
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Sleep timer set for $t'),
                        backgroundColor: const Color(0xFF8B5CF6)));
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showQueueSheet() {
    final player = context.read<PlayerProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Consumer<PlayerProvider>(
        builder: (ctx, p, _) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Text('Queue',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${p.queue.length} songs',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: p.queue.isEmpty
                  ? const Center(
                      child: Text('Queue is empty',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: p.queue.length,
                      itemBuilder: (_, i) {
                        final item = p.queue[i];
                        final isCurrent = i == p.currentIndex;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.artUri != null
                                  ? CachedNetworkImage(
                                      memCacheWidth: 576,
                                      memCacheHeight: 576,
                                      maxWidthDiskCache: 576,
                                      maxHeightDiskCache: 576,
                                      filterQuality: FilterQuality.high,
                                      imageUrl: item.artUri.toString(),
                                      width: 46,
                                      height: 46,
                                      fit: BoxFit.cover)
                                  : Container(
                                      width: 46,
                                      height: 46,
                                      color: const Color(0xFF1A1A2E),
                                      child: const Icon(Icons.music_note,
                                          color: Colors.white24))),
                          title: Text(item.title,
                              style: TextStyle(
                                  color: isCurrent
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(item.artist ?? '',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                          trailing: isCurrent
                              ? const Icon(Icons.graphic_eq,
                                  color: Color(0xFF8B5CF6), size: 20)
                              : null,
                          onTap: () {
                            p.skipToQueueItem(i);
                            Navigator.pop(context);
                          },
                        );
                      }),
            ),
          ]),
        ),
      ),
    );
  }

  void _showLyricsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _LyricsSheet(),
    );
  }

  void _showVersionsSheet() {
    final player = context.read<PlayerProvider>();
    final current = player.currentSong;
    if (current == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => FutureBuilder<List<SongResult>>(
          future: player.getSongVersions(current.title, current.artist ?? ''),
          builder: (context, snapshot) {
            final versions = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('SONG VERSIONS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text('Alternative cuts of ${current.title}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF8B5CF6)))
                      : versions.isEmpty
                          ? const Center(
                              child: Text('No versions found',
                                  style: TextStyle(color: Colors.white38)))
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: versions.length,
                              itemBuilder: (ctx, i) {
                                final item = versions[i];
                                return ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      memCacheWidth: 576,
                                      memCacheHeight: 576,
                                      maxWidthDiskCache: 576,
                                      maxHeightDiskCache: 576,
                                      filterQuality: FilterQuality.high,
                                      imageUrl: item.thumbnail,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(item.title,
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  subtitle: Text(item.artist,
                                      style: const TextStyle(
                                          color: Colors.white38)),
                                  onTap: () {
                                    player.playTrack(songToMediaItem(item));
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggleImmersiveMode() {
    setState(() {
      _rotationSpeedMultiplier = _rotationSpeedMultiplier == 1.0 ? 3.0 : 1.0;
      _spinController.duration =
          Duration(seconds: (8 / _rotationSpeedMultiplier).round());
      if (_spinController.isAnimating) {
        _spinController.repeat();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_rotationSpeedMultiplier > 1.0
            ? 'Immersive Mode Active'
            : 'Normal Mode'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating));
  }

  Widget _cBtn(IconData icon,
      {double size = 22, bool toggled = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon,
            color: toggled ? const Color(0xFF8B5CF6) : Colors.white70,
            size: size),
      ),
    );
  }

  Widget _vAction(IconData icon, String label, Color color,
      {VoidCallback? onTap, double? progress}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                if (progress != null && progress > 0 && progress < 1)
                  Text('${(progress * 100).toInt()}%',
                      style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
              ],
            ),
            if (progress != null && progress > 0 && progress < 1) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accPill(IconData icon, String label, Color color, {String? badge}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 20),
              if (badge != null)
                Positioned(
                  top: -8,
                  right: -12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A2E),
                      shape: BoxShape.circle,
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSongInfo() {
    final player = context.read<PlayerProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(player.currentSong?.title ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(player.currentSong?.artist ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 8),
          Text('ID: ${player.currentSong?.id ?? ''}',
              style: const TextStyle(color: Colors.white24, fontSize: 11)),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  void _showArtistProfile(String artist) {
    final player = context.read<PlayerProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 20),
        CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
            child: const Icon(Icons.person_rounded,
                color: Color(0xFF8B5CF6), size: 40)),
        const SizedBox(height: 12),
        Text(artist,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ListTile(
            leading: const Icon(Icons.play_circle_fill_rounded,
                color: Color(0xFF8B5CF6)),
            title: const Text('Artist Radio',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              player.search('$artist songs playlist');
              Navigator.pop(context);
            }),
        ListTile(
            leading: const Icon(Icons.search_rounded, color: Colors.white70),
            title: const Text('See All Songs',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              player.search(artist);
              Navigator.pop(context);
              Navigator.pop(context);
            }),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _DiscoOrbPainter extends CustomPainter {
  final double progress; // Driven by spin controller (0-1)
  final double pulse; // Driven by pulse controller (0-1)

  _DiscoOrbPainter(this.progress, this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    final colors = [
      const Color(0xFF8B5CF6).withOpacity(0.6), // Violet
      const Color(0xFFEC4899).withOpacity(0.6), // Pink
      const Color(0xFF3B82F6).withOpacity(0.5), // Blue
      const Color(0xFFFF6B00).withOpacity(0.5), // Orange
      const Color(0xFF10B981).withOpacity(0.4), // Emerald
    ];

    for (int i = 0; i < colors.length; i++) {
      // Each blob has a unique orbital path and phase
      final double phase = i * (2 * pi / colors.length);
      final double angle = (progress * 2 * pi) + phase;

      // "Moving here there": Oscillating orbit radius
      final double orbitRadius =
          radius * (0.4 + 0.15 * sin(progress * 3 * pi + i));

      final Offset blobOffset = Offset(
        center.dx + cos(angle) * orbitRadius,
        center.dy + sin(angle) * orbitRadius,
      );

      // "Beating": Size varies with pulse and individual rotation
      final double blobSize =
          radius * (0.45 + 0.25 * pulse + 0.1 * cos(progress * 2 * pi + i));

      final paint = Paint()
        ..color = colors[i]
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25 + 10 * pulse);

      canvas.drawCircle(blobOffset, blobSize, paint);
    }

    // Add a central white-ish core for the "sphere" look
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.15 + 0.1 * pulse)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 + 5 * pulse);
    canvas.drawCircle(center, radius * (0.3 + 0.1 * pulse), corePaint);
  }

  @override
  bool shouldRepaint(_DiscoOrbPainter old) =>
      old.progress != progress || old.pulse != pulse;
}

class _LyricsSheet extends StatefulWidget {
  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  final ScrollController _scrollCtrl = ScrollController();
  int _lastIndex = -1;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToActive(int index) {
    if (!_scrollCtrl.hasClients) return;
    final itemHeight = 56.0;
    final target = (index * itemHeight) -
        (_scrollCtrl.position.viewportDimension / 2) +
        itemHeight / 2;
    _scrollCtrl.animateTo(
      target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (ctx, player, _) {
        // Auto scroll when lyric changes
        if (player.currentLyricIndex != _lastIndex) {
          _lastIndex = player.currentLyricIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToActive(player.currentLyricIndex);
          });
        }

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Icon(Icons.lyrics_rounded,
                      color: Color(0xFFEC4899), size: 20),
                  const SizedBox(width: 10),
                  const Text('Lyrics',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(player.currentSong?.title ?? '',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ])),
            const SizedBox(height: 16),
            Expanded(
              child: player.isLyricsLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                            strokeWidth: 2,
                          ),
                          SizedBox(height: 16),
                          Text('Loading lyrics...',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ],
                      ),
                    )
                  : player.lyricLines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFFEC4899)
                                  ],
                                ).createShader(b),
                                child: const Icon(Icons.lyrics_outlined,
                                    color: Colors.white, size: 80),
                              ),
                              const SizedBox(height: 20),
                              const Text('No lyrics found',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Lyrics work best for popular\nHindi and English songs',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 13)),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () => context
                                    .read<PlayerProvider>()
                                    .fetchLyrics(context
                                            .read<PlayerProvider>()
                                            .currentSong
                                            ?.id ??
                                        ''),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 12),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFFEC4899)
                                      ])),
                                  child: const Text('Try Again',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        )
                      // PREMIUM SYNCED LYRICS LIST
                      : ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.08, 0.92, 1.0],
                          ).createShader(bounds),
                          blendMode: BlendMode.dstIn,
                          child: ListView.builder(
                            controller: _scrollCtrl,
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.32,
                            ),
                            itemCount: player.lyricLines.length,
                            itemBuilder: (_, i) {
                              final isCurrent = i == player.currentLyricIndex;
                              final distance =
                                  (i - player.currentLyricIndex).abs();

                              final opacity = isCurrent
                                  ? 1.0
                                  : (0.45 - distance * 0.08).clamp(0.08, 0.45);

                              final scale = isCurrent
                                  ? 1.0
                                  : (1.0 - distance * 0.05).clamp(0.85, 0.95);

                              return GestureDetector(
                                onTap: () => player.seekTo(Duration(
                                    milliseconds: player.lyricLines[i].timeMs)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOutCubic,
                                  margin: EdgeInsets.symmetric(
                                      vertical: isCurrent ? 12 : 6),
                                  child: Transform.scale(
                                    scale: scale,
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      style: TextStyle(
                                        fontSize: isCurrent ? 28 : 20,
                                        fontWeight: isCurrent
                                            ? FontWeight.w900
                                            : FontWeight.w600,
                                        color:
                                            Colors.white.withOpacity(opacity),
                                        height: 1.3,
                                      ),
                                      child: isCurrent
                                          ? ShaderMask(
                                              shaderCallback: (bounds) =>
                                                  const LinearGradient(
                                                colors: [
                                                  Color(0xFFFFFFFF),
                                                  Color(0xFFEC4899),
                                                ],
                                              ).createShader(bounds),
                                              child: Text(
                                                player.lyricLines[i].text,
                                                style: const TextStyle(
                                                    color: Colors.white),
                                              ),
                                            )
                                          : Text(player.lyricLines[i].text),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ]),
        );
      },
    );
  }
}
