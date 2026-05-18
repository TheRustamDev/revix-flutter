import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../innertube/innertube_client.dart';
import 'playlist_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedCategory = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  bool _hasSearched = false;

  final List<Map<String, dynamic>> _discoveryCards = [
    {
      'label': 'Trending',
      'icon': Icons.trending_up_rounded,
      'query': 'trending music india 2024',
      'color': const Color(0xFFEC4899),
      'desc': 'Viral hits now'
    },
    {
      'label': 'New Releases',
      'icon': Icons.new_releases_rounded,
      'query': 'latest 2024 official music videos',
      'color': const Color(0xFF8B5CF6),
      'desc': 'Fresh for you'
    },
    {
      'label': 'Charts',
      'icon': Icons.bar_chart_rounded,
      'query': 'global billboard top 100',
      'color': const Color(0xFF0EA5E9),
      'desc': 'Ranking hits'
    },
    {
      'label': 'Live & Events',
      'icon': Icons.live_tv_rounded,
      'query': 'official live concert recordings',
      'color': const Color(0xFF10B981),
      'desc': 'Real-time vibes'
    },
    {
      'label': 'Podcasts',
      'icon': Icons.mic_external_on_rounded,
      'query': 'ted talks story telling',
      'color': const Color(0xFFF59E0B),
      'desc': 'Listen & learn'
    },
    {
      'label': 'Genres',
      'icon': Icons.grid_view_rounded,
      'query': 'popular music mix',
      'color': const Color(0xFF6366F1),
      'desc': 'All music styles'
    },
  ];

  final List<Map<String, dynamic>> _vibeStations = [
    {
      'title': 'Midnight Drive',
      'subtitle': 'Neon city lights',
      'colors': [const Color(0xFF2D0A4E), const Color(0xFF1A0A2E)],
      'query': 'synthwave night driving'
    },
    {
      'title': 'Dreamscape',
      'subtitle': 'Ethereal melodies',
      'colors': [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
      'query': 'ethereal chill mix'
    },
    {
      'title': 'Main Character',
      'subtitle': 'Walk like a boss',
      'colors': [const Color(0xFFFF6B00), const Color(0xFFEC4899)],
      'query': 'powerful phonk 2024'
    },
    {
      'title': 'Chill Radar',
      'subtitle': 'Calm your mind',
      'colors': [const Color(0xFF0EA5E9), const Color(0xFF2D0A4E)],
      'query': 'lofi relax study'
    },
    {
      'title': 'Energy',
      'subtitle': 'Power up your soul',
      'colors': [const Color(0xFFFF3D00), const Color(0xFFFF6B00)],
      'query': 'hype workout tracks'
    },
  ];

  final List<Map<String, dynamic>> _genres = [
    {
      'label': 'Hip Hop',
      'count': '2.5k tracks',
      'colors': [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
      'query': 'hip hop hits'
    },
    {
      'label': 'Lo-Fi',
      'count': '1.8k tracks',
      'colors': [const Color(0xFF0EA5E9), const Color(0xFF2D0A4E)],
      'query': 'lofi beats'
    },
    {
      'label': 'Electronic',
      'count': '3k tracks',
      'colors': [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      'query': 'electronic dance'
    },
    {
      'label': 'Punjabi',
      'count': '1.2k tracks',
      'colors': [const Color(0xFFFF6B00), const Color(0xFFEC4899)],
      'query': 'punjabi songs'
    },
    {
      'label': 'Rock',
      'count': '900 tracks',
      'colors': [const Color(0xFFFF3D00), const Color(0xFFFF6B00)],
      'query': 'rock classics'
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerProvider>().search('trending music 2024');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q, PlayerProvider player) {
    _searchDebounce?.cancel();
    if (q.isEmpty) return;
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!_hasSearched) setState(() => _hasSearched = true);
      player.search(q);
    });
  }

  void _openPlaylistModal(BuildContext ctx, PlayerProvider player, String query,
      String title) async {
    player.search(query);
    Navigator.push(
        ctx,
        MaterialPageRoute(
            builder: (_) => PlaylistScreen(
                  playlistId: query,
                  title: title,
                  thumbnail: '',
                  owner: '',
                )));
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
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
            const Row(
              children: [
                Icon(Icons.notifications_rounded,
                    color: Color(0xFF8B5CF6), size: 24),
                SizedBox(width: 10),
                Text('Notifications',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _notifTile(
                      'New Release',
                      'AP Dhillon just dropped a new album!',
                      Icons.album_rounded,
                      '2m ago'),
                  _notifTile(
                      'Trending Now',
                      'Arijit Singh is #1 on charts today',
                      Icons.trending_up_rounded,
                      '15m ago'),
                  _notifTile(
                      'Playlist Ready',
                      'Your Daily Pulse is ready to play',
                      Icons.playlist_play_rounded,
                      '1h ago'),
                  _notifTile(
                      'New Arrivals',
                      '50 new Tamil songs added this week',
                      Icons.new_releases_rounded,
                      '3h ago'),
                  _notifTile('Weekly Mix', 'Your weekend vibe playlist is live',
                      Icons.headphones_rounded, 'Yesterday'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(String title, String body, IconData icon, String time) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.15),
          child: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 11)),
          ],
        ),
        isThreeLine: true,
      );

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 44,
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
              child: const Icon(Icons.person_rounded,
                  color: Color(0xFF8B5CF6), size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Melophile',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const Text('REVIX One Member',
                style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 13)),
            const SizedBox(height: 28),
            _profileOption('Edit Profile', Icons.edit_rounded,
                () => Navigator.pop(context)),
            _profileOption('Liked Songs', Icons.favorite_rounded,
                () => Navigator.pop(context)),
            _profileOption('My Playlists', Icons.queue_music_rounded,
                () => Navigator.pop(context)),
            const Divider(color: Colors.white12, height: 32),
            _profileOption(
              'Sign Out',
              Icons.logout_rounded,
              () => Navigator.pop(context),
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileOption(String label, IconData icon, VoidCallback onTap,
          {Color? color}) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color ?? Colors.white70, size: 22),
        title: Text(label,
            style: TextStyle(color: color ?? Colors.white, fontSize: 15)),
        onTap: onTap,
      );

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
          decoration: BoxDecoration(gradient: theme.bg),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _topBar()),
                SliverToBoxAdapter(child: _header(player)),
                SliverToBoxAdapter(child: _discoveryCardGrid(player)),
                SliverToBoxAdapter(child: _sectionHeader('Vibe Stations')),
                SliverToBoxAdapter(child: _vibeStationsRow(player)),
                SliverToBoxAdapter(child: _sectionHeader('Top Picks For You')),
                SliverToBoxAdapter(child: _topPicksGrid(player)),
                SliverToBoxAdapter(child: _sectionHeader('Explore by Genre')),
                SliverToBoxAdapter(child: _genreGrid(player)),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(children: [
          Image.asset(
            'assets/images/revix.official.png',
            height: 28,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showNotificationsSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(color: Colors.white12)),
              child: const Icon(Icons.notifications_none_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showProfileSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.5))),
              child: const Icon(Icons.person_outline_rounded,
                  color: Color(0xFF8B5CF6), size: 22),
            ),
          ),
        ]),
      );

  Widget _header(PlayerProvider player) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Explore",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800)),
          const Text("Find your next vibe",
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (q) => _onSearchChanged(q, player),
                  onSubmitted: (q) {
                    if (!_hasSearched) setState(() => _hasSearched = true);
                    player.search(q);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Search songs, artists...",
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: Color(0xFF8B5CF6), size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _iconBtn(Icons.search_rounded, () {
              if (!_hasSearched) setState(() => _hasSearched = true);
              player.search(_searchCtrl.text);
            }),
            const SizedBox(width: 8),
            _iconBtn(Icons.tune_rounded, () => _showFilterSheet()),
          ]),
        ]),
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF8B5CF6)),
        ),
      );

  Widget _discoveryCardGrid(PlayerProvider player) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _discoveryCards.length,
        itemBuilder: (_, i) {
          final cat = _discoveryCards[i];
          final isSelected = _selectedCategory == i;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = i);
              _openPlaylistModal(context, player, cat['query'] as String,
                  cat['label'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: cat['color'] as Color, width: 2)
                    : Border.all(color: Colors.white10, width: 1),
                gradient: LinearGradient(colors: [
                  (cat['color'] as Color).withOpacity(0.15),
                  const Color(0xFF1A1A2E)
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Stack(children: [
                Positioned(
                  top: 15,
                  left: 15,
                  child: Icon(cat['icon'] as IconData,
                      color: cat['color'] as Color, size: 28),
                ),
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat['label'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        Text(cat['desc'] as String,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 10)),
                      ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Discovery Filters',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _filterGroup('Vibe', ['Energetic', 'Chill', 'Mood Boost', 'Focus']),
            _filterGroup('Language', ['English', 'Punjabi', 'Hindi', 'K-Pop']),
            _filterGroup('Popularity', ['All', 'Charts', 'Underground']),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: const Text('Apply Filters',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterGroup(String label, List<String> options) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: options
                    .map((opt) => Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF1A1A2E),
                              border: Border.all(color: Colors.white10)),
                          child: Text(opt,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ))
                    .toList()),
          ),
        ]),
      );

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
        child: Row(children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          GestureDetector(
            onTap: () => _handleSeeAll(title),
            child: const Text('EXPLORE ALL  ›',
                style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ),
        ]),
      );

  Widget _vibeStationsRow(PlayerProvider player) => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _vibeStations.length,
          itemBuilder: (_, i) {
            final station = _vibeStations[i];
            return Container(
              width: 170,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: RadialGradient(
                      colors: station['colors'] as List<Color>,
                      center: Alignment.topLeft,
                      radius: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: (station['colors'] as List<Color>)[0]
                            .withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8))
                  ]),
              clipBehavior: Clip.hardEdge,
              child: Stack(children: [
                Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(20)),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.waves_rounded,
                            color: Colors.white, size: 10),
                        SizedBox(width: 4),
                        Text('LIVE RADIO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ]),
                    )),
                Positioned(
                    bottom: 15,
                    left: 15,
                    right: 50,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station['title'] as String,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900)),
                          Text(station['subtitle'] as String,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ])),
                Positioned(
                    bottom: 15,
                    right: 15,
                    child: GestureDetector(
                      onTap: () => _openPlaylistModal(
                          context,
                          player,
                          station['query'] as String? ?? 'chill lofi mix',
                          station['title'] as String),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black38,
                            border:
                                Border.all(color: Colors.white54, width: 1)),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 24),
                      ),
                    )),
              ]),
            );
          },
        ),
      );

  Widget _topPicksGrid(PlayerProvider player) {
    // Prefer recently played history, fall back to search results
    final recentItems = player.recentlyPlayed;
    final hasRecent = recentItems.isNotEmpty && !_hasSearched;
    final count = hasRecent
        ? (recentItems.length > 5 ? 5 : recentItems.length)
        : (player.searchResults.length > 5 ? 5 : player.searchResults.length);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: count == 0 ? 3 : count,
      itemBuilder: (_, i) {
        if (count == 0) return _placeholderRow(i);
        final SongResult s = hasRecent
            ? SongResult(
                id: recentItems[i].id,
                title: recentItems[i].title,
                artist: recentItems[i].artist ?? '',
                thumbnail: recentItems[i].artUri?.toString() ?? '')
            : player.searchResults[i];
        final isPlaying = player.currentSong?.id == s.id && player.isPlaying;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => player.playSong(s),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isPlaying
                        ? const Color(0xFF8B5CF6)
                        : Colors.white.withOpacity(0.05)),
              ),
              child: Row(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(alignment: Alignment.center, children: [
                      s.thumbnail.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: s.thumbnail,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover)
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899)
                              ]))),
                      Container(width: 50, height: 50, color: Colors.black26),
                      Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 22),
                    ])),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(s.title,
                          style: TextStyle(
                              color: isPlaying
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(s.artist,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ])),
                IconButton(
                  icon: const Icon(Icons.favorite_border_rounded,
                      color: Colors.white38, size: 20),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white38, size: 20),
                  onPressed: () => _showTrackOptionsMenu(s),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderRow(int i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  Widget _genreGrid(PlayerProvider player) => SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _genres.length,
          itemBuilder: (_, i) {
            final g = _genres[i];
            return GestureDetector(
              onTap: () => _openPlaylistModal(
                  context, player, g['query'] as String, g['label'] as String),
              child: Container(
                width: 140,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                      colors: g['colors'] as List<Color>,
                      begin: Alignment.bottomRight,
                      end: Alignment.topLeft),
                  boxShadow: [
                    BoxShadow(
                        color: (g['colors'] as List<Color>)[0].withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g['label'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                      Text(g['count'] as String,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ]),
              ),
            );
          },
        ),
      );

  void _handleSeeAll(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Exploring all $title...'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF8B5CF6),
    ));
  }

  void _showTrackOptionsMenu(SongResult s) {
    final player = context.read<PlayerProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
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
                      imageUrl: s.thumbnail, width: 40, height: 40)),
              title: Text(s.title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle:
                  Text(s.artist, style: const TextStyle(color: Colors.white54)),
            ),
            const Divider(color: Colors.white10),
            _profileOption('Play Next', Icons.play_arrow_rounded, () {
              player.playSong(s);
              Navigator.pop(context);
            }),
            _profileOption(
                player.isLiked(s.id) ? 'Remove from Liked' : 'Add to Liked',
                player.isLiked(s.id) ? Icons.favorite : Icons.favorite_border,
                () {
              player.toggleLikeSong(s);
              Navigator.pop(context);
            }),
            _profileOption('Share Song', Icons.share, () {
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// PLAYLIST MODAL — used by all category/vibe/genre cards
// ──────────────────────────────────────────────
