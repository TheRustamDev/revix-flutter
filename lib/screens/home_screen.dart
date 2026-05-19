import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../innertube/innertube_client.dart';
import 'playlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedMood = 0;
  late AnimationController _waveController;
  late AnimationController _shimmerController;
  final ScrollController scrollController = ScrollController();
  Map<String, String> _playlistThumbs = {};
  final Map<String, Future<List<PlaylistResult>>> _homeFutures = {};
  late AnimationController _ringController;

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
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _ringController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = context.read<PlayerProvider>();
      player.search('top hindi songs 2024');
      player.fetchHomeSections();
      _loadPlaylistThumbnails();
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _shimmerController.dispose();
    _ringController.dispose();
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
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  SliverToBoxAdapter(child: _sectionHeader('Quick Picks')),
                  SliverToBoxAdapter(child: _quickPicks(player)),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
                  if (player.isLoadingHome && player.homeSections.isEmpty) ...[
                    SliverToBoxAdapter(
                        child: _sectionHeader('Finding some fire...')),
                    SliverToBoxAdapter(child: _skeletonRow()),
                    SliverToBoxAdapter(child: _skeletonRow()),
                  ] else if (player.homeSections.isEmpty) ...[
                    SliverToBoxAdapter(child: _sectionHeader('Trending Now')),
                    SliverToBoxAdapter(
                        child: _playlistQueryRow('trending hindi songs')),
                    SliverToBoxAdapter(child: _sectionHeader('New Releases')),
                    SliverToBoxAdapter(
                        child: _playlistQueryRow('new punjabi songs 2024')),
                    SliverToBoxAdapter(child: _sectionHeader('Global Charts')),
                    SliverToBoxAdapter(
                        child: _playlistQueryRow('top global 50 hits')),
                  ] else ...[
                    for (final entry in player.homeSections.entries) ...[
                      SliverToBoxAdapter(child: _sectionHeader(entry.key)),
                      SliverToBoxAdapter(
                          child: _dynamicSection(player, entry.key)),
                    ],
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 180)),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _revixLogo(),
          _circleBtn(Icons.search_rounded, onTap: _showSearchSheet),
        ],
      ),
    );
  }

  Widget _revixLogo({double fontSize = 26}) => ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: GestureDetector(
          onTap: () {
            scrollToTop();
            context.read<PlayerProvider>().refreshHomeRecommendations();
          },
          onLongPress: () => _showDevInfo(),
          child: Text(
            'REVIX ONE',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              fontFamily: 'sans-serif-condensed',
            ),
          ),
        ),
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
    if (items.isEmpty) return const SizedBox.shrink();
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
            onTap: () => player.playTrack(songToMediaItem(s)),
            onLongPress: () => _showTrackOptionsMenu(context, s, player),
            child: _songCardV2(s),
          );
        },
      ),
    );
  }

  Widget _skeletonRow() => SizedBox(
        height: 195,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 5,
          itemBuilder: (_, __) => _shimmerWrapper(
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withOpacity(0.04),
                      )),
                  const SizedBox(height: 5),
                  Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withOpacity(0.02),
                      )),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _shimmerWrapper({required Widget child}) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.0),
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              transform: _SlidingGradientTransform(
                  offset: _shimmerController.value * 2 - 1),
            ).createShader(bounds);
          },
          child: child,
        );
      },
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _shimmerWrapper(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 70,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withOpacity(0.05)),
            ),
          ),
        ),
      );
    }
    final results = player.searchResults.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 70,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final s = results[i];
        final isPlaying = player.currentSong?.id == s.id && player.isPlaying;
        return GestureDetector(
          onTap: () => player.playSong(s),
          onLongPress: () => _showTrackOptionsMenu(context, s, player),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1A1A2E),
                border: isPlaying
                    ? Border.all(color: const Color(0xFF8B5CF6), width: 1.5)
                    : Border.all(color: Colors.white10, width: 0.5)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                    imageUrl: s.thumbnail,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                        color: Colors.white10,
                        child: const Icon(Icons.music_note,
                            color: Colors.white24, size: 20))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isPlaying
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      Text(s.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10)),
                    ]),
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
            _revixLogo(fontSize: 32),
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

  Widget _playlistQueryRow(String query) {
    _homeFutures[query] ??=
        context.read<PlayerProvider>().innerTube.searchPlaylists(query);
    return FutureBuilder<List<PlaylistResult>>(
      future: _homeFutures[query],
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 180,
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
          );
        }
        final playlists = snapshot.data!;
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: min(playlists.length, 10),
            itemBuilder: (_, i) {
              final p = playlists[i];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => PlaylistScreen(
                              playlistId: p.id,
                              title: p.title,
                              thumbnail: p.thumbnail,
                              owner: p.owner)));
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: p.thumbnail,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        p.owner,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
            onTap: () async {
              final player = context.read<PlayerProvider>();
              final results =
                  await player.innerTube.searchPlaylists(p['query'] as String);
              if (results.isNotEmpty && mounted) {
                final playlist = results.first;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlaylistScreen(
                            playlistId: playlist.id,
                            title: p['title'] as String,
                            thumbnail: playlist.thumbnail,
                            owner: playlist.owner)));
              }
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
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Text(
                      p['icon'] as String,
                      style: const TextStyle(fontSize: 70),
                    ),
                  ),
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
          onChanged: (q) => player.getSuggestions(q),
          onSubmitted: (q) => player.search(q),
        ),
        const SizedBox(height: 10),
        if (!player.isSearching &&
            player.searchResults.isEmpty &&
            player.searchSuggestions.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: player.searchSuggestions.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.history_rounded,
                    color: Colors.white24, size: 20),
                title: Text(player.searchSuggestions[i],
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                onTap: () {
                  _ctrl.text = player.searchSuggestions[i];
                  player.search(_ctrl.text);
                },
              ),
            ),
          )
        else ...[
          const SizedBox(height: 10),
          Expanded(
            child: player.isSearching && player.searchResults.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : CustomScrollView(
                    slivers: [
                      if (player.foundArtists.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                            child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Artists',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        )),
                        SliverList(
                            delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final a = player.foundArtists[i];
                            return ListTile(
                              leading: ClipOval(
                                  child: CachedNetworkImage(
                                      imageUrl: a.thumbnail,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover)),
                              title: Text(a.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: const Text('Artist Playlist',
                                  style: TextStyle(color: Colors.white54)),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.white24),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => PlaylistScreen(
                                            playlistId: a.name,
                                            title: a.name,
                                            thumbnail: a.thumbnail,
                                            owner: 'Artist Playlist')));
                              },
                            );
                          },
                          childCount: player.foundArtists.length,
                        )),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                      if (player.foundAlbums.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                            child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Albums',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        )),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: player.foundAlbums.length,
                              itemBuilder: (_, i) {
                                final al = player.foundAlbums[i];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => PlaylistScreen(
                                                playlistId:
                                                    '${al.artist} ${al.title}',
                                                title: al.title,
                                                thumbnail: al.thumbnail,
                                                owner: al.artist)));
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                                imageUrl: al.thumbnail,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover)),
                                        const SizedBox(height: 6),
                                        Text(al.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                      if (player.searchResults.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                            child: Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('Songs',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        )),
                        SliverList(
                            delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final s = player.searchResults[i];
                            return ListTile(
                              leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
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
                          childCount: player.searchResults.length,
                        )),
                      ],
                    ],
                  ),
          ),
        ],
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
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    paint1.shader = const SweepGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF8B5CF6)],
    ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, paint1);
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

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.offset,
  });

  final double offset;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * offset, 0.0, 0.0);
  }
}
