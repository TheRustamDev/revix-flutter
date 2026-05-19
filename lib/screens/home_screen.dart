import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../innertube/innertube_client.dart';
import 'package:path_provider/path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedMood = 0;
  late AnimationController _ringController;
  late AnimationController _waveController;
  final ScrollController scrollController = ScrollController();
  Map<String, String> _playlistThumbs = {};

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(0,
          duration: const Duration(milliseconds: 600), curve: Curves.easeOut);
    }
  }

  final List<Map<String, String>> _moods = [
    {'label': 'All'},
    {'label': 'Moods'},
    {'label': 'Workout'},
    {'label': 'Focus'},
    {'label': 'Chill'},
    {'label': 'Party'},
    {'label': 'Sleep'},
    {'label': 'Romance'},
    {'label': 'Decades'},
    {'label': 'Classical'},
    {'label': 'Anime'},
  ];

  final List<Map<String, dynamic>> _madeForYou = [
    {
      'title': 'Daily Pulse',
      'subtitle': 'Your daily mix of new hits',
      'c1': const Color(0xFF2D0A4E),
      'c2': const Color(0xFF1A0A2E),
      'accent': const Color(0xFFEC4899),
      'query': 'youtube music top hits this week india',
      'type': 'wave'
    },
    {
      'title': 'Late Night',
      'subtitle': 'Vibes for your midnight soul',
      'c1': const Color(0xFF0A0A2E),
      'c2': const Color(0xFF0A0A18),
      'accent': Colors.white,
      'query': 'late night slow sad songs hindi',
      'type': 'orb'
    },
    {
      'title': 'Punjabi',
      'subtitle': 'The finest from Punjab',
      'c1': const Color(0xFF1A0A00),
      'c2': const Color(0xFF2A1500),
      'accent': const Color(0xFFEC4899),
      'query': 'new punjabi songs 2024 latest',
      'type': 'khanda'
    },
    {
      'title': 'Romance',
      'subtitle': 'For the romantic soul',
      'c1': const Color(0xFF2A0A1A),
      'c2': const Color(0xFF1A0510),
      'accent': const Color(0xFFEC4899),
      'query': 'best romantic songs hindi 2024',
      'type': 'heart'
    },
    {
      'title': 'Flashback',
      'subtitle': 'Best of the decades',
      'c1': const Color(0xFF1A1A00),
      'c2': const Color(0xFF000000),
      'accent': const Color(0xFFFFD700),
      'query': '90s bollywood hits collection',
      'type': 'wave'
    },
    {
      'title': 'K-Pop Fresh',
      'subtitle': 'Latest from Seoul',
      'c1': const Color(0xFF001A1A),
      'c2': const Color(0xFF000000),
      'accent': const Color(0xFF0EA5E9),
      'query': 'new kpop releases 2024 hits',
      'type': 'orb'
    },
    {
      'title': 'Soulful Sufi',
      'subtitle': 'Divine melodies',
      'c1': const Color(0xFF1A0A00),
      'c2': const Color(0xFF000000),
      'accent': const Color(0xFFEC4899),
      'query': 'best sufi songs arijit nusrat rabbi',
      'type': 'wave'
    },
  ];

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'GOOD MORNING';
    if (h < 17) return 'GOOD AFTERNOON';
    return 'GOOD EVENING';
  }

  @override
  void initState() {
    super.initState();
    _ringController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = context.read<PlayerProvider>();
      player.search('top hindi songs 2024');
      player.fetchHomeSections();
      _loadPlaylistThumbnails();
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final player = context.watch<PlayerProvider>();
    return Consumer<ThemeProvider>(builder: (context, theme, _) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFF1A1A2E),
              onRefresh: () async {
                final p = context.read<PlayerProvider>();
                final pool = [
                  'top bollywood 2024',
                  'best punjabi hits',
                  'trending indie songs',
                  'arijit singh hits',
                  'ap dhillon new songs',
                  'lofi chill beats',
                  'shubh latest songs',
                  'diljit dosanjh mix',
                  'best of weeknd',
                  'global top 50'
                ];
                pool.shuffle();
                p.search(pool.first);
                await p.fetchHomeSections();
              },
              child: CustomScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _topBar()),
                  SliverToBoxAdapter(child: _heroRow(player)),
                  SliverToBoxAdapter(child: _moodChips(player)),
                  SliverToBoxAdapter(child: _sectionHeader('Recently Played')),
                  SliverToBoxAdapter(child: _recentlyPlayed(player)),
                  SliverToBoxAdapter(
                      child: _sectionHeader('Featured Playlists')),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: _playlistCardsRow(player),
                    ),
                  ),
                  SliverToBoxAdapter(child: _sectionHeader('Made For You')),
                  SliverToBoxAdapter(child: _madeForYouRow(player)),
                  for (final entry in player.homeSections.entries) ...[
                    SliverToBoxAdapter(child: _sectionHeader(entry.key)),
                    SliverToBoxAdapter(
                        child: _dynamicSection(player, entry.key)),
                  ],
                  SliverToBoxAdapter(child: _sectionHeader('Quick Picks')),
                  SliverToBoxAdapter(child: _quickPicks(player)),
                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          GestureDetector(
            onTap: () {
              scrollToTop();
              context.read<PlayerProvider>().refreshHomeRecommendations();
            },
            onLongPress: () => _showDevInfo(),
            child: Image.asset(
              'assets/images/revix.official.png',
              height: 28,
              fit: BoxFit.contain,
            ),
          ),
          const Spacer(),
          _circleBtn(Icons.search_rounded, onTap: () => _showSearchSheet()),
          const SizedBox(width: 10),
          _topMenu(),
        ]),
      );

  Widget _topMenu() => PopupMenuButton<String>(
        onSelected: (v) => _handleMenu(v),
        icon: _circleBtn(Icons.more_vert_rounded),
        padding: EdgeInsets.zero,
        offset: const Offset(0, 50),
        color: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (_) => [
          _menuItem('Settings', Icons.settings_rounded),
          _menuItem('Sleep Timer', Icons.timer_rounded),
          _menuItem('Downloads', Icons.download_done_rounded),
          _menuItem('Equalizer', Icons.graphic_eq_rounded),
          _menuItem('App Info', Icons.info_outline_rounded),
        ],
      );

  PopupMenuItem<String> _menuItem(String title, IconData icon) =>
      PopupMenuItem<String>(
        value: title,
        child: Row(children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ]),
      );

  void _handleMenu(String v) {
    switch (v) {
      case 'Settings':
        _showSettingsSheet();
        break;
      case 'Sleep Timer':
        _showSleepTimerSheet();
        break;
      case 'Downloads':
        _showDownloadsSheet(context.read<PlayerProvider>());
        break;
      case 'Equalizer':
        _showEqualizerSheet();
        break;
      case 'App Info':
        _showDevInfo();
        break;
    }
  }

  void _showSettingsSheet() {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgColor1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Container(
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
              const Text('Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _settingsTile('Audio Quality', Icons.high_quality_rounded,
                  trailing: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1A1A2E),
                    value: context.watch<PlayerProvider>().audioQuality,
                    style: const TextStyle(color: Colors.white),
                    underline: const SizedBox(),
                    items: ['Normal', 'High', 'Lossless']
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e,
                                style: const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null)
                        context.read<PlayerProvider>().setAudioQuality(v);
                    },
                  )),
              _settingsTile('Auto-Play', Icons.play_arrow_rounded,
                  trailing: Switch(
                    value: context.watch<PlayerProvider>().autoPlay,
                    onChanged: (v) =>
                        context.read<PlayerProvider>().setAutoPlay(v),
                    activeColor: const Color(0xFF8B5CF6),
                  )),
              _settingsTile('Equalizer', Icons.graphic_eq_rounded, onTap: () {
                Navigator.pop(context);
                _showEqualizerSheet();
              }),
              _settingsTile('Notifications', Icons.notifications_rounded,
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeColor: const Color(0xFF8B5CF6),
                  )),
              _settingsTile('Clear Cache', Icons.cleaning_services_rounded,
                  onTap: () {
                Navigator.pop(context);
                _clearCache();
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _settingsTile(String label, IconData icon,
      {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF8B5CF6), size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }

  void _showSleepTimerSheet() {
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
            const Text('Music stops automatically after selected time.',
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
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () {
                    if (t == 'End of song') {
                      context.read<PlayerProvider>().setSleepAfterSong();
                    } else {
                      final mins = int.tryParse(t.split(' ')[0]) ?? 0;
                      if (mins > 0) {
                        context
                            .read<PlayerProvider>()
                            .setSleepTimer(Duration(minutes: mins));
                      }
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

  void _showDownloadsSheet(PlayerProvider player) {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgColor1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
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
            const Text('Local Downloads',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('All offline content is stored securely on your device.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 24),
            Expanded(
              child: player.downloadedSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download_done_rounded,
                              color: Colors.white.withOpacity(0.05), size: 100),
                          const SizedBox(height: 16),
                          const Text('Nothing downloaded yet',
                              style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: player.downloadedSongs.length,
                      itemBuilder: (ctx, i) {
                        final s = player.downloadedSongs[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                  memCacheWidth: 576,
                                  memCacheHeight: 576,
                                  maxWidthDiskCache: 576,
                                  maxHeightDiskCache: 576,
                                  filterQuality: FilterQuality.high,
                                  imageUrl: s.artUri.toString(),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover)),
                          title: Text(s.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          subtitle: Text(s.artist ?? 'REVIX One',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                          trailing: const Icon(Icons.download_done_rounded,
                              color: Color(0xFF10B981), size: 20),
                          onTap: () => player.playTrack(s),
                        );
                      }),
            ),
          ],
        ),
      ),
    );
  }

  void _showEqualizerSheet() {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgColor1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        double bass = 0, mid = 0, treble = 0;
        return Padding(
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
              const Text('Equalizer',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _eqSlider('Bass', bass, (v) => setS(() => bass = v)),
              _eqSlider('Mid', mid, (v) => setS(() => mid = v)),
              _eqSlider('Treble', treble, (v) => setS(() => treble = v)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => setS(() => bass = mid = treble = 0),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        );
      }),
    );
  }

  Widget _eqSlider(String label, double value, ValueChanged<double> onChange) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text('${value.toStringAsFixed(1)} dB',
                  style:
                      const TextStyle(color: Color(0xFF8B5CF6), fontSize: 13)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF8B5CF6),
                thumbColor: const Color(0xFFEC4899),
                inactiveTrackColor: Colors.white12,
                trackHeight: 3),
            child: Slider(min: -10, max: 10, value: value, onChanged: onChange),
          ),
        ],
      );

  Widget _circleBtn(IconData icon, {VoidCallback? onTap}) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A2E),
            border: Border.all(color: Colors.white12, width: 0.5)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(21),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      );

  Widget _heroRow(PlayerProvider player) {
    final songs = player.searchResults;
    final featured = songs.isNotEmpty ? songs[0] : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            flex: 55,
            child: GestureDetector(
              onTap: featured != null ? () => player.playSong(featured) : null,
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1A0A2E)),
                clipBehavior: Clip.hardEdge,
                child: Stack(fit: StackFit.expand, children: [
                  if (featured != null && featured.thumbnail.isNotEmpty)
                    CachedNetworkImage(
                        memCacheWidth: 576,
                        memCacheHeight: 576,
                        maxWidthDiskCache: 576,
                        maxHeightDiskCache: 576,
                        filterQuality: FilterQuality.high,
                        imageUrl: featured.thumbnail,
                        fit: BoxFit.cover)
                  else
                    Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight))),
                  Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black],
                              stops: [0.35, 1.0]))),
                  Positioned(
                      bottom: 48,
                      left: 12,
                      right: 48,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                player.sleepTimerRemaining > 0
                                    ? 'OFF IN ${player.sleepTimerRemaining ~/ 60}m'
                                    : 'NEW MIX',
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(featured?.title ?? 'Loading...',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(featured?.artist ?? '',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11),
                                maxLines: 1),
                          ])),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 48,
                    child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (_, __) => Row(
                                children: List.generate(20, (i) {
                              final h = (sin((i * 0.5) +
                                              _waveController.value * pi * 2) *
                                          6 +
                                      8)
                                  .abs();
                              return Container(
                                  width: 2,
                                  height: h,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                      color: i < 8
                                          ? const Color(0xFFEC4899)
                                          : Colors.white24,
                                      borderRadius: BorderRadius.circular(2)));
                            }))),
                  ),
                  Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: featured != null
                            ? () => player.togglePlayPause()
                            : null,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFFEC4899), width: 2),
                              color: Colors.black26),
                          child: Icon(
                              player.isPlaying &&
                                      player.currentSong?.id == featured?.id
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20),
                        ),
                      )),
                ]),
              ),
            )),
        const SizedBox(width: 10),
        Expanded(
            flex: 45,
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFF0D0D1A),
                  border: Border.all(color: Colors.white10, width: 0.5)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                        animation: _ringController,
                        builder: (_, __) => CustomPaint(
                            size: const Size(100, 100),
                            painter: _RingPainter(_ringController.value))),
                    const SizedBox(height: 10),
                    Text(_greeting,
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    const Text('Melophile',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text("Let's vibe with\nsomething epic.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 10)),
                    const SizedBox(height: 10),
                    GestureDetector(
                        onTap: () {
                          final queries = [
                            'arijit singh',
                            'punjabi 2024',
                            'lofi chill',
                            'ap dhillon',
                            'shubh songs',
                            'weeknd hits'
                          ];
                          context.read<PlayerProvider>().search(
                              queries[Random().nextInt(queries.length)]);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12)),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    color: Color(0xFFFFD700), size: 13),
                                SizedBox(width: 5),
                                Text('Surprise Me',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ]),
                        )),
                  ]),
            )),
      ]),
    );
  }

  Widget _moodChips(PlayerProvider player) => SizedBox(
        height: 42,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _moods.length,
          itemBuilder: (_, i) {
            final selected = i == _selectedMood;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedMood = i);
                final queries = [
                  'top hits 2024',
                  'mood songs',
                  'workout music',
                  'focus music',
                  'chill vibes',
                  'party songs'
                ];
                context.read<PlayerProvider>().search(queries[i]);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)])
                      : null,
                  color: selected ? null : const Color(0xFF1A1A2E),
                  border: Border.all(
                      color: selected ? Colors.transparent : Colors.white24,
                      width: 0.5),
                ),
                child: Text(_moods[i]['label']!,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400)),
              ),
            );
          },
        ),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(
            onTap: () => _handleSeeAll(title),
            child: const Text('See All  ›',
                style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13)),
          ),
        ]),
      );

  Widget _recentlyPlayed(PlayerProvider player) {
    final items = player.recentlyPlayed;
    if (items.isEmpty) {
      return SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount:
              player.searchResults.length > 5 ? 5 : player.searchResults.length,
          itemBuilder: (_, i) {
            final s = player.searchResults[i];
            return GestureDetector(
                onTap: () => player.playSong(s),
                onLongPress: () => _showTrackOptionsMenu(context, s, player),
                child: _recentCard(s.thumbnail, s.title, s.artist));
          },
        ),
      );
    }
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => player.playSong(SongResult(
              id: items[i].id,
              title: items[i].title,
              artist: items[i].artist ?? '',
              thumbnail: items[i].artUri?.toString() ?? '')),
          onLongPress: () => _showTrackOptionsMenu(
              context,
              SongResult(
                  id: items[i].id,
                  title: items[i].title,
                  artist: items[i].artist ?? '',
                  thumbnail: items[i].artUri?.toString() ?? ''),
              player),
          child: _recentCard(items[i].artUri?.toString() ?? '', items[i].title,
              items[i].artist ?? ''),
        ),
      ),
    );
  }

  Widget _recentCard(String thumb, String title, String artist) => Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF1A1A2E)),
            clipBehavior: Clip.hardEdge,
            child: thumb.isNotEmpty
                ? CachedNetworkImage(
                    memCacheWidth: 576,
                    memCacheHeight: 576,
                    maxWidthDiskCache: 576,
                    maxHeightDiskCache: 576,
                    filterQuality: FilterQuality.high,
                    imageUrl: thumb,
                    fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight))),
          ),
          const SizedBox(height: 6),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(artist,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _dynamicSection(PlayerProvider player, String sectionKey) {
    final items = player.homeSections[sectionKey] ?? [];
    return SizedBox(
      height: 190,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final s = items[i];
          return GestureDetector(
            onTap: () => player.playSong(s),
            onLongPress: () => _showTrackOptionsMenu(context, s, player),
            child: _songCardV2(s),
          );
        },
      ),
    );
  }

  Widget _songCardV2(SongResult song) => Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              memCacheWidth: 576,
              memCacheHeight: 576,
              maxWidthDiskCache: 576,
              maxHeightDiskCache: 576,
              filterQuality: FilterQuality.high,
              imageUrl: song.thumbnail,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          const SizedBox(height: 8),
          Text(song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          Text(song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      );
  Widget _madeForYouRow(PlayerProvider player) => SizedBox(
        height: 170,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _madeForYou.length,
          itemBuilder: (_, i) {
            final item = _madeForYou[i];
            return GestureDetector(
              onTap: () => player.search(item['query']),
              child: Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                        colors: [item['c1'] as Color, item['c2'] as Color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight)),
                padding: const EdgeInsets.all(14),
                child: Stack(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title'],
                            style: TextStyle(
                                color: item['accent'] as Color,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(item['subtitle'],
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11)),
                      ]),
                  Positioned(bottom: 0, left: 0, child: _madeForYouArt(item)),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => player.search(item['query']),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white54, width: 1.5),
                              color: Colors.black26),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 16),
                        ),
                      )),
                ]),
              ),
            );
          },
        ),
      );

  Widget _madeForYouArt(Map<String, dynamic> item) {
    if (item['type'] == 'wave') {
      return AnimatedBuilder(
        animation: _waveController,
        builder: (_, __) => Row(
          children: List.generate(8, (i) {
            final h =
                (sin(i * 0.7 + _waveController.value * pi * 2) * 10 + 14).abs();
            return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(2)));
          }),
        ),
      );
    }
    return Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [Color(0xFF8B5CF6), Colors.transparent])));
  }

  Widget _quickPicks(PlayerProvider player) {
    if (player.isLoading || player.isSearching) {
      return const SizedBox(
          height: 200,
          child: Center(
              child: CircularProgressIndicator(color: Color(0xFF8B5CF6))));
    }
    final results = player.searchResults.take(10).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final s = results[i];
        final isPlaying = player.currentSong?.id == s.id && player.isPlaying;
        return GestureDetector(
          onTap: () => player.playSong(s),
          onLongPress: () => _showTrackOptionsMenu(context, s, player),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF1A1A2E),
                border: isPlaying
                    ? Border.all(color: const Color(0xFF8B5CF6), width: 1)
                    : Border.all(color: Colors.white10, width: 0.5)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: s.thumbnail.isNotEmpty
                    ? CachedNetworkImage(
                        memCacheWidth: 576,
                        memCacheHeight: 576,
                        maxWidthDiskCache: 576,
                        maxHeightDiskCache: 576,
                        filterQuality: FilterQuality.high,
                        imageUrl: s.thumbnail,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover)
                    : Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899)
                        ]))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isPlaying
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(s.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ]),
              ),
              Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: isPlaying ? const Color(0xFF8B5CF6) : Colors.white24,
                size: 30,
              ),
            ]),
          ),
        );
      },
    );
  }

  void _showSearchSheet() {
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgColor1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SearchSheet(),
    );
  }

  void _handleSeeAll(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Viewing all $title coming in next update!'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF8B5CF6),
    ));
  }

  void _showTrackOptionsMenu(
      BuildContext context, SongResult song, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                      memCacheWidth: 576,
                      memCacheHeight: 576,
                      maxWidthDiskCache: 576,
                      maxHeightDiskCache: 576,
                      filterQuality: FilterQuality.high,
                      imageUrl: song.thumbnail,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                          width: 40, height: 40, color: Colors.white10))),
              title: Text(song.title,
                  maxLines: 1,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(song.artist,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            const Divider(color: Colors.white10),
            _actionItem('Add to Liked', Icons.favorite_border, () {
              player.toggleLikeSong(song);
              Navigator.pop(context);
            }),
            _actionItem('Queue Next', Icons.queue_music_rounded, () {
              player.addToQueue(song);
              Navigator.pop(context);
            }),
            _actionItem('Download', Icons.download_rounded, () {
              player.downloadTrack(songToMediaItem(song));
              Navigator.pop(context);
            }),
            _actionItem('Share', Icons.share_rounded, () {
              context.read<PlayerProvider>().shareSong(
                    song.title,
                    song.artist,
                    song.id,
                  );
              Navigator.pop(context);
            }),
            _actionItem('Remove from History', Icons.delete_outline_rounded,
                () {
              player.removeFromHistory(song.id);
              Navigator.pop(context);
            }, isDangerous: true),
          ],
        ),
      ),
    );
  }

  void _showDevInfo() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withOpacity(0.1)),
              child: Image.asset('assets/images/revix.official.png',
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.music_note_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 40)),
            ),
            const SizedBox(height: 20),
            const Text('REVIX ONE v3.0.0',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
            const SizedBox(height: 10),
            const Text('The Future of Audio Presence',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const Divider(color: Colors.white10, height: 40),
            _devRow('Developer', 'Ayaz Ahmad'),
            _devRow('UI Designer', 'Antigravity AI'),
            _devRow('Engine', 'InnerTube Hybrid'),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.pop(context),
                child: const Text('STAY BOLD',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _devRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            Text(v,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _actionItem(String label, IconData icon, VoidCallback onTap,
          {bool isDangerous = false}) =>
      ListTile(
        leading: Icon(icon,
            color: isDangerous ? Colors.redAccent : Colors.white70, size: 22),
        title: Text(label,
            style: TextStyle(
                color: isDangerous ? Colors.redAccent : Colors.white,
                fontSize: 14)),
        onTap: onTap,
      );

  Future<void> _loadPlaylistThumbnails() async {
    final queries = {
      'Bollywood Fire': 'bollywood fire hits playlist',
      'Party Mode': 'party songs dance playlist',
      'Arijit World': 'arijit singh best songs',
      'Punjabi Heat': 'punjabi hits playlist 2024',
      'Lo-Fi Study': 'lofi study beats playlist',
      'Sad Hours': 'sad hindi songs playlist',
    };
    final client = context.read<PlayerProvider>().innerTube;
    for (final entry in queries.entries) {
      try {
        final results = await client.search(entry.value);
        if (results.isNotEmpty && mounted) {
          setState(() {
            _playlistThumbs[entry.key] = results.first.thumbnail;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cache cleared successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to clear cache: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _playlistCardsRow(PlayerProvider player) {
    final playlists = [
      {
        'title': 'Bollywood Fire',
        'subtitle': 'Hot Hindi Hits',
        'query': 'bollywood hits 2024 top songs',
        'gradient': [const Color(0xFFEC4899), const Color(0xFFFF6B00)],
        'icon': '🔥',
      },
      {
        'title': 'Party Mode',
        'subtitle': 'Dance floor bangers',
        'query': 'party songs hindi 2024 dance',
        'gradient': [const Color(0xFF8B5CF6), const Color(0xFF3B82F6)],
        'icon': '🎉',
      },
      {
        'title': 'Arijit World',
        'subtitle': 'Best of Arijit Singh',
        'query': 'arijit singh best songs hits',
        'gradient': [const Color(0xFF0EA5E9), const Color(0xFF8B5CF6)],
        'icon': '🎤',
      },
      {
        'title': 'Punjabi Heat',
        'subtitle': 'Top Punjabi tracks',
        'query': 'new punjabi songs 2024 top hits',
        'gradient': [const Color(0xFFFFD700), const Color(0xFFEC4899)],
        'icon': '⚡',
      },
      {
        'title': 'Lo-Fi Study',
        'subtitle': 'Focus & chill beats',
        'query': 'lofi hip hop study chill beats',
        'gradient': [const Color(0xFF10B981), const Color(0xFF0EA5E9)],
        'icon': '📚',
      },
      {
        'title': 'Sad Hours',
        'subtitle': 'Feel every word',
        'query': 'sad hindi songs emotional 2024',
        'gradient': [const Color(0xFF6366F1), const Color(0xFFEC4899)],
        'icon': '💔',
      },
    ];

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        itemBuilder: (_, i) {
          final p = playlists[i];
          return GestureDetector(
            onTap: () {
              context
                  .read<PlayerProvider>()
                  .search(p['query'] as String)
                  .then((_) {
                final results = context.read<PlayerProvider>().searchResults;
                if (results.isNotEmpty) {
                  context
                      .read<PlayerProvider>()
                      .playSongList(results, startIndex: 0);
                }
              });
              _showPlaylistSheet(
                p['title'] as String,
                p['query'] as String,
              );
            },
            child: Container(
              width: 155,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF1A1A2E),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  // Real thumbnail background
                  if (_playlistThumbs.containsKey(p['title']))
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: _playlistThumbs[p['title']!]!,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: p['gradient'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  // Dark overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Background emoji art
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Text(
                      p['icon'] as String,
                      style: const TextStyle(fontSize: 70),
                    ),
                  ),
                  // Text bottom left
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play button top right
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black26,
                        border: Border.all(color: Colors.white54, width: 1),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPlaylistSheet(String title, String query) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _PlaylistSheet(title: title, query: query),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 24),
        TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search songs or artists...',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF8B5CF6)),
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
          ),
          onSubmitted: (q) => player.search(q),
        ),
        const SizedBox(height: 20),
        Expanded(
            child: player.isSearching
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : ListView.builder(
                    itemCount: player.searchResults.length,
                    itemBuilder: (_, i) {
                      final s = player.searchResults[i];
                      return ListTile(
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                                memCacheWidth: 576,
                                memCacheHeight: 576,
                                maxWidthDiskCache: 576,
                                maxHeightDiskCache: 576,
                                filterQuality: FilterQuality.high,
                                imageUrl: s.thumbnail,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover)),
                        title: Text(s.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                            maxLines: 1),
                        subtitle: Text(s.artist,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        trailing: const Icon(Icons.play_circle_fill,
                            color: Color(0xFF8B5CF6)),
                        onTap: () {
                          Navigator.pop(context);
                          player.playSong(s);
                        },
                      );
                    },
                  )),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer Ring
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    paint1.shader = const SweepGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF8B5CF6)],
    ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, paint1);

    // Inner Ring (Dual Ring)
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    paint2.shader = const SweepGradient(
      colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ).createShader(Rect.fromCircle(center: center, radius: size.width / 2 - 8));
    canvas.drawCircle(center, size.width / 2 - 8, paint2);
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

class _PlaylistSheet extends StatefulWidget {
  final String title;
  final String query;
  const _PlaylistSheet({required this.title, required this.query});
  @override
  State<_PlaylistSheet> createState() => _PlaylistSheetState();
}

class _PlaylistSheetState extends State<_PlaylistSheet> {
  List<SongResult> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final player = context.read<PlayerProvider>();
    final results = await player.innerTube.search(widget.query);
    if (mounted) {
      setState(() {
        _songs = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerProvider>();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 12),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Expanded(
                child: Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800))),
            if (_songs.isNotEmpty)
              GestureDetector(
                  onTap: () {
                    player.playSongList(_songs);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Play All',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
              : _songs.isEmpty
                  ? const Center(
                      child: Text('No songs found',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      controller: ctrl,
                      itemCount: _songs.length,
                      itemBuilder: (_, i) {
                        final s = _songs[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: s.thumbnail,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: const Color(0xFF1A1A2E),
                                  child: const Icon(Icons.music_note,
                                      color: Colors.white24)),
                            ),
                          ),
                          title: Text(s.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          subtitle: Text(s.artist,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                              maxLines: 1),
                          trailing: const Icon(Icons.play_circle_fill_rounded,
                              color: Color(0xFF8B5CF6), size: 28),
                          onTap: () {
                            player.playSong(s);
                            Navigator.pop(context);
                          },
                        );
                      }),
        ),
      ]),
    );
  }
}
