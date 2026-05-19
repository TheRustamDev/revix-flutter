import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../innertube/innertube_client.dart';
import 'profile_screen.dart';
// import 'package:on_audio_query/on_audio_query.dart';
import 'playlist_screen.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
          color: Colors.transparent,
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
                      _localTabView(player),
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
            Tab(
                child: Row(children: [
              Icon(Icons.folder_open_rounded, size: 18),
              SizedBox(width: 8),
              Text("Local")
            ])),
          ],
        ),
      );

  // Tab View Implementation
  Widget _musicTabView(PlayerProvider player) {
    final likedMedia = player.getLikedSongs().map((s) => MediaItem(
          id: s.id,
          title: s.title,
          artist: s.artist,
          artUri: Uri.tryParse(s.thumbnail),
        ));
    final allItems = [...player.recentlyPlayed, ...likedMedia];
    final uniqueIds = <String>{};
    final uniqueItems = allItems.where((s) => uniqueIds.add(s.id)).toList();

    if (uniqueItems.isEmpty) {
      return const Center(
          child: Text('No music yet', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: uniqueItems.length,
      itemBuilder: (context, i) {
        final song = uniqueItems[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              memCacheWidth: 576,
              memCacheHeight: 576,
              maxWidthDiskCache: 576,
              maxHeightDiskCache: 576,
              filterQuality: FilterQuality.high,
              imageUrl: song.artUri?.toString() ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: Colors.white10, width: 48, height: 48),
            ),
          ),
          title: Text(song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          subtitle: Text(song.artist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: const Icon(Icons.more_vert_rounded,
              color: Colors.white38, size: 20),
          onTap: () => player.playTrack(song),
          onLongPress: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Options menu coming soon...'),
              backgroundColor: Color(0xFF8B5CF6),
              behavior: SnackBarBehavior.floating,
            ));
          },
        );
      },
    );
  }

  Widget _playlistsTabView(PlayerProvider player) {
    final playlists = player.homePlaylists.isNotEmpty
        ? player.homePlaylists.values.first
        : <PlaylistResult>[];

    if (playlists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music_rounded, color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            Text('No playlists yet',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Playlists from your home feed\nwill appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: playlists.length,
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
                          owner: p.owner,
                        )));
          },
          onLongPress: () => _showPlaylistOptions(p.title, p, player),
          child: Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              // Square thumbnail 72x72
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14)),
                child: p.thumbnail.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: p.thumbnail,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _thumbPlaceholder())
                    : Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFF2A1A4E),
                        child: const Icon(Icons.music_note,
                            color: Colors.white24, size: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(p.owner.isNotEmpty ? p.owner : 'Playlist',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              )),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white24, size: 14),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _albumsTabView(PlayerProvider player) {
    final allPlaylists = player.homePlaylists.values.toList();
    final albums = allPlaylists.length > 1
        ? allPlaylists[1]
        : allPlaylists.isNotEmpty
            ? allPlaylists[0]
            : <PlaylistResult>[];

    if (albums.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album_rounded, color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            Text('No albums found',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 8),
            Text('Albums from your home feed\nwill appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      physics: const BouncingScrollPhysics(),
      itemCount: albums.length,
      itemBuilder: (_, i) {
        final a = albums[i];
        return GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PlaylistScreen(
                          playlistId: a.id,
                          title: a.title,
                          thumbnail: a.thumbnail,
                          owner: a.owner,
                        )));
          },
          onLongPress: () => _showPlaylistOptions(a.title, a, player),
          child: Container(
            height: 72,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14)),
                child: a.thumbnail.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: a.thumbnail,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _thumbPlaceholder())
                    : Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFF2A1A4E),
                        child: const Icon(Icons.music_note,
                            color: Colors.white24, size: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(a.owner.isNotEmpty ? a.owner : 'Album',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 1),
                ],
              )),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white24, size: 14),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _artistsTabView(PlayerProvider player) {
    if (player.topArtists.isEmpty) {
      return const Center(
          child: Text('Play some music to see your top artists',
              style: TextStyle(color: Colors.white38)));
    }
    return ListView(
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
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Top Artist',
                  style: TextStyle(color: Colors.white38)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white24, size: 16),
              onTap: () {
                player.search(name);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: const Color(0xFF0D0D1A),
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => const _SearchSheet(),
                );
              },
            )),
      ],
    );
  }

  Widget _downloadsTabView(PlayerProvider player) {
    final downloads = player.getDownloadedSongs();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: downloads.length,
      itemBuilder: (_, i) => _SongTile(song: downloads[i], player: player),
    );
  }

  Widget _thumbPlaceholder() => Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.music_note_rounded,
            color: Colors.white54, size: 24),
      );

  void _showPlaylistOptions(
      String title, PlaylistResult p, PlayerProvider player) {
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
            leading:
                const Icon(Icons.play_arrow_rounded, color: Color(0xFF8B5CF6)),
            title: const Text('Play Playlist',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PlaylistScreen(
                          playlistId: p.id,
                          title: p.title,
                          thumbnail: p.thumbnail,
                          owner: p.owner)));
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.queue_music_rounded, color: Color(0xFF0EA5E9)),
            title: const Text('Add All to Queue',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              final songs = await player.innerTube.getPlaylistDetails(p.id);
              for (final s in songs) {
                player.addToQueue(s);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Added ${songs.length} songs to queue'),
                  backgroundColor: const Color(0xFF8B5CF6),
                ));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded, color: Color(0xFF10B981)),
            title: const Text('Share Playlist',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              player.shareSong(title, 'Playlist', p.id);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _localTabView(PlayerProvider player) {
    if (player.isLoadingLocal) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }
    if (player.localSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_rounded,
                color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            const Text('No local songs found',
                style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => player.fetchLocalSongs(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Scan Device',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: player.localSongs.length,
      itemBuilder: (context, i) {
        final song = player.localSongs[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.white10,
              child: const Icon(Icons.music_note, color: Colors.white24),
            ),
          ),
          title: Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          trailing: const Icon(Icons.more_vert_rounded,
              color: Colors.white38, size: 20),
          onTap: () {
            player.playSong(song);
          },
        );
      },
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
          memCacheWidth: 576,
          memCacheHeight: 576,
          maxWidthDiskCache: 576,
          maxHeightDiskCache: 576,
          filterQuality: FilterQuality.high,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
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
