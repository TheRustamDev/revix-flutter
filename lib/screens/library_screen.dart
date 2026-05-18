import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          decoration: BoxDecoration(gradient: theme.bg),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _topBar()),
                SliverToBoxAdapter(child: _header()),
                SliverToBoxAdapter(child: _tabs()),
                SliverToBoxAdapter(child: _statsGrid(player)),
                SliverToBoxAdapter(child: _sectionHeader('Recently Added')),
                SliverToBoxAdapter(child: _recentlyAdded(player)),
                SliverToBoxAdapter(child: _sectionHeader('Your Playlists')),
                SliverToBoxAdapter(child: _playlistsRow()),
                SliverToBoxAdapter(child: _sectionHeader('Albums')),
                SliverToBoxAdapter(child: _albumsRow()),
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
          RichText(
              text: const TextSpan(children: [
            TextSpan(
                text: '·REVIX ',
                style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5)),
            TextSpan(
                text: 'ONE',
                style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6)),
          ])),
          const Spacer(),
          _circleBtn(Icons.search),
          const SizedBox(width: 12),
          _circleBtn(Icons.person_outline_rounded),
        ]),
      );

  Widget _circleBtn(IconData icon) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A2E),
            border: Border.all(color: Colors.white12, width: 0.5)),
        child: Icon(icon, color: Colors.white, size: 20),
      );

  Widget _header() => const Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Library",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800)),
          Text("All your music. One place.",
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ]),
      );

  Widget _tabs() => Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF8B5CF6),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
                child: Row(children: [
              Icon(Icons.music_note, size: 18),
              SizedBox(width: 8),
              Text("Music")
            ])),
            Tab(
                child: Row(children: [
              Icon(Icons.queue_music, size: 18),
              SizedBox(width: 8),
              Text("Playlists")
            ])),
            Tab(
                child: Row(children: [
              Icon(Icons.album, size: 18),
              SizedBox(width: 8),
              Text("Albums")
            ])),
            Tab(
                child: Row(children: [
              Icon(Icons.person, size: 18),
              SizedBox(width: 8),
              Text("Artists")
            ])),
            Tab(
                child: Row(children: [
              Icon(Icons.download, size: 18),
              SizedBox(width: 8),
              Text("Downloads")
            ])),
          ],
        ),
      );

  Widget _statsGrid(PlayerProvider player) {
    final stats = [
      {
        'val': player.recentlyPlayed.length.toString(),
        'lab': 'Songs',
        'icon': Icons.music_note_rounded,
        'color': const Color(0xFF8B5CF6),
        'query': 'all songs'
      },
      {
        'val': player.likedSongsCount.toString(),
        'lab': 'Liked',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFEC4899),
        'query': 'liked songs'
      },
      {
        'val': player.downloadedSongsCount.toString(),
        'lab': 'Downloads',
        'icon': Icons.download_done_rounded,
        'color': const Color(0xFF10B981),
        'query': 'downloads'
      },
      {
        'val': player.historySongs.length.toString(),
        'lab': 'History',
        'icon': Icons.history_rounded,
        'color': const Color(0xFF3B82F6),
        'query': 'history'
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14),
        itemCount: 4,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _showCollection(
              stats[i]['lab'] as String, stats[i]['query'] as String),
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ]),
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: (stats[i]['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(stats[i]['icon'] as IconData,
                      color: stats[i]['color'] as Color, size: 20)),
              const Spacer(),
              Text(stats[i]['val'] as String,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900)),
              Text(stats[i]['lab'] as String,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5)),
            ]),
          ),
        ),
      ),
    );
  }

  void _showCollection(String title, String query) {
    if (title == 'Songs') {
      _showSortSheet();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening $title vault...'),
      backgroundColor: const Color(0xFF8B5CF6),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Sort Collection',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.access_time_rounded, color: Colors.white),
            title: const Text('Recently Added',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_outline_rounded,
                color: Colors.white),
            title: const Text('Most Played',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading:
                const Icon(Icons.sort_by_alpha_rounded, color: Colors.white),
            title: const Text('Alphabetical',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading:
                const Icon(Icons.person_outline_rounded, color: Colors.white),
            title: const Text('Artist', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _recentlyAdded(PlayerProvider player) {
    final items = player.recentlyPlayed;
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.isEmpty ? 4 : (items.length > 5 ? 5 : items.length),
        itemBuilder: (_, i) {
          if (items.isEmpty) return _placeholderCard(i);
          final song = items[i];
          return GestureDetector(
            onTap: () => player.playTrack(song),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(children: [
                        CachedNetworkImage(
                            imageUrl: song.artUri?.toString() ?? '',
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: Colors.white.withOpacity(0.05)),
                            errorWidget: (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.1))),
                        Container(
                            width: 140,
                            height: 140,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                  Colors.transparent,
                                  Colors.black54
                                ]))),
                        Positioned(
                            bottom: 10,
                            right: 10,
                            child: Icon(
                                player.isDownloaded(song.id)
                                    ? Icons.download_done_rounded
                                    : (player.isLiked(song.id)
                                        ? Icons.favorite_rounded
                                        : Icons.music_note_rounded),
                                color: player.isDownloaded(song.id)
                                    ? const Color(0xFF10B981)
                                    : (player.isLiked(song.id)
                                        ? const Color(0xFFEC4899)
                                        : Colors.white24),
                                size: 14)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Text(song.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Row(children: [
                      const Icon(Icons.person_rounded,
                          color: Color(0xFF8B5CF6), size: 10),
                      const SizedBox(width: 4),
                      Text(song.artist ?? 'Unknown Artist',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ]),
                  ]),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholderCard(int i) {
    final colors = [
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]
    ];
    return Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
                colors: colors[i % 2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)));
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
        child: Row(children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          GestureDetector(
            onTap: () => _handleSeeAll(title),
            child: const Text('SEE ALL ›',
                style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ),
        ]),
      );

  Widget _playlistsRow() {
    final playlists = [
      {
        'title': 'Late Night Vibes',
        'count': '24',
        'icon': Icons.nightlight_round,
        'colors': [const Color(0xFF2D0A4E), const Color(0xFF1A0A2E)]
      },
      {
        'title': 'Workout Hits',
        'count': '32',
        'icon': Icons.fitness_center_rounded,
        'colors': [const Color(0xFFFACC15), const Color(0xFFCA8A04)]
      },
      {
        'title': 'Chill Drive',
        'count': '18',
        'icon': Icons.drive_eta_rounded,
        'colors': [const Color(0xFF0EA5E9), const Color(0xFF0284C7)]
      },
    ];
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: playlists.length,
        itemBuilder: (_, i) {
          final p = playlists[i];
          return GestureDetector(
            onLongPress: () => _showPlaylistOptions(p['title'] as String),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                      colors: p['colors'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  boxShadow: [
                    BoxShadow(
                        color: (p['colors'] as List<Color>)[0].withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              padding: const EdgeInsets.all(20),
              child: Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(p['icon'] as IconData,
                      color: Colors.white.withOpacity(0.3), size: 30),
                  const Spacer(),
                  Text(p['title'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14)),
                ]),
                Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(p['count'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)))),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _albumsRow() {
    final albums = [
      {'name': 'Starboy', 'art': 'The Weeknd', 'tracks': '18'},
      {'name': 'Justice', 'art': 'Justin Bieber', 'tracks': '16'},
      {'name': 'Views', 'art': 'Drake', 'tracks': '20'}
    ];
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _handleSeeAll('Album: ${albums[i]['name']}'),
          child: Container(
            width: 140,
            margin: const EdgeInsets.only(right: 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: const Color(0xFF1A1A2E),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.05))),
                  child: const Center(
                      child: Icon(Icons.album_rounded,
                          color: Colors.white12, size: 60))),
              const SizedBox(height: 10),
              Text(albums[i]['name']!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text("${albums[i]['art']} • ${albums[i]['tracks']} tracks",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1),
            ]),
          ),
        ),
      ),
    );
  }

  void _handleSeeAll(String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Exploring all $title...'),
      backgroundColor: const Color(0xFF8B5CF6),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showPlaylistOptions(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: Colors.white),
            title: const Text('Edit Playlist',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded, color: Colors.white),
            title: const Text('Download All',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent),
            title: const Text('Delete Playlist',
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
