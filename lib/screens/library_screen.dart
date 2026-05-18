import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../innertube/innertube_client.dart';
import 'profile_screen.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(),
                _header(),
                _tabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _musicTabView(player),
                      _playlistsTabView(player),
                      _albumsTabView(player),
                      _artistsTabView(player),
                      _downloadsTabView(player),
                    ],
                  ),
                ),
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
          _circleBtn(Icons.search, onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF0D0D1A),
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32))),
              builder: (_) => const _SearchSheet(),
            );
          }),
          const SizedBox(width: 12),
          _circleBtn(Icons.person_outline_rounded, onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }),
        ]),
      );

  Widget _circleBtn(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A2E),
              border: Border.all(color: Colors.white12, width: 0.5)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
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

  // Tab View Implementation
  Widget _musicTabView(PlayerProvider player) => ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _statsGrid(player),
          _sectionHeader('Recently Played'),
          _recentlyAdded(player),
          _sectionHeader('Quick Picks'),
          _quickPicksView(player),
        ],
      );

  Widget _playlistsTabView(PlayerProvider player) => ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _sectionHeader('Your Playlists'),
          _playlistsGrid(player),
        ],
      );

  Widget _albumsTabView(PlayerProvider player) => ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _sectionHeader('Recent Albums'),
          _albumsGrid(player),
        ],
      );

  Widget _artistsTabView(PlayerProvider player) => ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text('Top Artists',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...player.topArtists.map((name) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1A1A2E),
                  radius: 30,
                  backgroundImage: const NetworkImage(
                      'https://music.youtube.com/img/artist_placeholder.png'),
                ),
                title: Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Top Artist',
                    style: TextStyle(color: Colors.white38)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white24, size: 16),
              )),
        ],
      );

  Widget _downloadsTabView(PlayerProvider player) {
    final downloads = player.getDownloadedSongs();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: downloads.length,
      itemBuilder: (_, i) => _SongTile(song: downloads[i], player: player),
    );
  }

  // Grid/List Helpers
  Widget _playlistsGrid(PlayerProvider player) {
    if (player.homePlaylists.isEmpty) return _placeholderRow();
    final playlists = player.homePlaylists.values.first;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8),
      itemCount: playlists.length,
      itemBuilder: (_, i) {
        final p = playlists[i];
        return _playlistItem(p, player);
      },
    );
  }

  Widget _albumsGrid(PlayerProvider player) {
    if (player.homePlaylists.length < 2) return _placeholderRow();
    final albums = player.homePlaylists.values.elementAt(1);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8),
      itemCount: albums.length,
      itemBuilder: (_, i) {
        final a = albums[i];
        return _playlistItem(a, player);
      },
    );
  }

  Widget _playlistItem(PlaylistResult p, PlayerProvider player) =>
      GestureDetector(
        onTap: () => player.fetchPlaylistContent(p.id),
        onLongPress: () => _showPlaylistOptions(p.title),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: p.thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF1A1A2E),
                    child:
                        const Icon(Icons.queue_music, color: Colors.white24)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(p.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(p.owner,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      );

  Widget _quickPicksView(PlayerProvider player) => Column(
        children: player.quickPicks
            .take(5)
            .map((s) => _SongTile(song: s, player: player))
            .toList(),
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
                border: Border.all(color: Colors.white.withOpacity(0.05))),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => _CollectionModal(title: title),
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
              width: 110,
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(children: [
                        CachedNetworkImage(
                            imageUrl: song.artUri?.toString() ?? '',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover),
                        Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                  Colors.transparent,
                                  Colors.black87
                                ]))),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(song.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(song.artist ?? 'Unknown Artist',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
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
            gradient: LinearGradient(colors: colors[i % 2])));
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

  Widget _placeholderRow() => const SizedBox(
      height: 180,
      child: Center(
          child: Text("Finding your playlists...",
              style: TextStyle(color: Colors.white30))));

  void _handleSeeAll(String title) {
    if (title == 'Recently Played' ||
        title == 'Downloads' ||
        title == 'Quick Picks') {
      _showCollection(title, title.toLowerCase());
    } else if (title == 'Your Playlists') {
      _tabController.animateTo(1);
    } else if (title == 'Albums') {
      _tabController.animateTo(2);
    } else if (title == 'Recent Albums') {
      _tabController.animateTo(2);
    }
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

class _SearchSheet extends StatefulWidget {
  const _SearchSheet();
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

class _CollectionModal extends StatelessWidget {
  final String title;
  const _CollectionModal({required this.title});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    List<SongResult> songs;

    if (title == 'Liked') {
      songs = player.getLikedSongs();
    } else if (title == 'Downloads') {
      songs = player.getDownloadedSongs();
    } else if (title == 'History') {
      songs = player.historySongs
          .map((m) => SongResult(
                id: m.id,
                title: m.title,
                artist: m.artist ?? '',
                thumbnail: m.artUri?.toString() ?? '',
              ))
          .toList();
    } else if (title == 'Quick Picks') {
      songs = player.quickPicks;
    } else {
      songs = player.recentlyPlayed
          .map((m) => SongResult(
                id: m.id,
                title: m.title,
                artist: m.artist ?? '',
                thumbnail: m.artUri?.toString() ?? '',
              ))
          .toList();
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${songs.length} songs',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ]),
          const SizedBox(height: 20),
          Expanded(
            child: songs.isEmpty
                ? const Center(
                    child: Text("Empty vault",
                        style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    controller: controller,
                    itemCount: songs.length,
                    itemBuilder: (_, i) =>
                        _SongTile(song: songs[i], player: player),
                  ),
          ),
        ]),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongResult song;
  final PlayerProvider player;
  const _SongTile({required this.song, required this.player});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => player.playSong(song),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: song.thumbnail,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.white10),
          errorWidget: (_, __, ___) =>
              const Icon(Icons.music_note, color: Colors.white24),
        ),
      ),
      title: Text(song.title,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          maxLines: 1),
      subtitle: Text(song.artist,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          maxLines: 1),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.isDownloaded(song.id))
            const Icon(Icons.download_done_rounded,
                color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
                player.isLiked(song.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: player.isLiked(song.id)
                    ? const Color(0xFFEC4899)
                    : Colors.white38,
                size: 20),
            onPressed: () => player.toggleLikeSong(song),
          ),
        ],
      ),
    );
  }
}
