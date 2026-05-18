import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/theme_provider.dart';
import '../providers/player_provider.dart';

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
            decoration: BoxDecoration(gradient: theme.bg),
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
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  _vAction(
                                      Icons.graphic_eq,
                                      player.audioQuality,
                                      const Color(0xFF8B5CF6), onTap: () {
                                    final next = player.audioQuality == 'Normal'
                                        ? 'High'
                                        : player.audioQuality == 'High'
                                            ? 'Lossless'
                                            : 'Normal';
                                    player.setAudioQuality(next);
                                  }),
                                  _vAction(
                                      player.isLiked(player.currentSong?.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      'Liked',
                                      const Color(0xFFEC4899),
                                      onTap: () => player
                                          .toggleLike(player.currentSong)),
                                  _vAction(Icons.share_outlined, 'Share',
                                      const Color(0xFFFF6B00),
                                      onTap: _showShareSheet),
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
                          onTap: _showSleepTimerSheet,
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
                        // Lyrics
                        Expanded(
                          child: GestureDetector(
                            onTap: _showLyricsView,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text('Add to Playlist',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Adding to Playlist...'),
                    behavior: SnackBarBehavior.floating));
              }),
          ListTile(
              leading: const Icon(Icons.timer_outlined, color: Colors.white),
              title: const Text('Sleep Timer',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSleepTimerSheet();
              }),
          ListTile(
              leading: const Icon(Icons.equalizer_rounded, color: Colors.white),
              title: const Text('Equalizer',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context)),
          ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('Song Infos',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showSongInfo();
              }),
          ListTile(
              leading: const Icon(Icons.report_problem_outlined,
                  color: Colors.redAccent),
              title: const Text('Report Track',
                  style: TextStyle(color: Colors.redAccent))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showSongInfo() {
    final player = context.read<PlayerProvider>();
    final s = player.currentSong;
    if (s == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Track Information',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _infoRow('Title', s.title),
            _infoRow('Artist', s.artist ?? 'Unknown'),
            _infoRow('Album', s.album ?? 'Single'),
            _infoRow('Duration', player.durationLabel),
            _infoRow('Source', 'REVIX One Tube'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38)),
            Text(val, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );

  void _showArtistProfile(String artist) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Opening $artist profile...'),
          behavior: SnackBarBehavior.floating));

  void _showShareSheet() =>
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Generating smart share link...'),
          behavior: SnackBarBehavior.floating));

  void _showQueueSheet() {
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
        builder: (_, scrollCtrl) => Consumer<PlayerProvider>(
          builder: (context, player, _) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Up Next',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: player.queue.isEmpty
                    ? const Center(
                        child: Text('Queue is empty',
                            style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: player.queue.length,
                        itemBuilder: (ctx, i) {
                          final item = player.queue[i];
                          final isCurrent = player.currentSong?.id == item.id;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.artUri.toString(),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(item.title,
                                style: TextStyle(
                                    color: isCurrent
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.white,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                            subtitle: Text(item.artist ?? 'Unknown',
                                style: const TextStyle(color: Colors.white38)),
                            onTap: () => player.playTrack(item),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Consumer<PlayerProvider>(
        builder: (context, player, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Sleep Timer',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            if (player.sleepTimerRemaining > 0)
              ListTile(
                leading:
                    const Icon(Icons.timer_rounded, color: Color(0xFFEC4899)),
                title: Text(
                    '${(player.sleepTimerRemaining / 60).ceil()} minutes remaining',
                    style: const TextStyle(color: Colors.white)),
                trailing: const Text('CANCEL',
                    style: TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  player.cancelSleepTimer();
                  Navigator.pop(context);
                },
              ),
            ...[15, 30, 45, 60].map((m) => ListTile(
                  leading:
                      const Icon(Icons.nightlight_round, color: Colors.white54),
                  title: Text('$m minutes',
                      style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    player.setSleepTimer(Duration(minutes: m));
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLyricsView() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Lyrics',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: const [
                    Text(
                      "Lyircs are currently being synchronized for this track.\n\nREVIX One uses advanced Neural matching to fetch high-quality lyrics from our global database.\n\nCheck back in a few moments.",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          height: 1.6,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF8B5CF6))),
                  ],
                ),
              ),
            ],
          ),
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
