import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import '../innertube/innertube_client.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;
  final String title;
  final String thumbnail;
  final String owner;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    required this.title,
    required this.thumbnail,
    this.owner = '',
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<SongResult> _playlistSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final player = context.read<PlayerProvider>();
      final songs =
          await player.innerTube.getPlaylistDetails(widget.playlistId);
      if (mounted) {
        setState(() {
          _playlistSongs = songs;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerProvider, ThemeProvider>(
      builder: (context, player, theme, _) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            color: Colors.transparent,
            child: CustomScrollView(
              slivers: [
                // Hero header
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.black45),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20)),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                      background: Stack(fit: StackFit.expand, children: [
                    // Thumbnail
                    widget.thumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            memCacheWidth: 576,
                            memCacheHeight: 576,
                            maxWidthDiskCache: 576,
                            maxHeightDiskCache: 576,
                            filterQuality: FilterQuality.high,
                            imageUrl: widget.thumbnail,
                            fit: BoxFit.cover)
                        : Container(
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFFEC4899)
                          ]))),
                    // Gradient overlay
                    Container(
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black],
                                stops: [0.4, 1.0]))),
                    // Title at bottom
                    Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900)),
                              if (widget.owner.isNotEmpty)
                                Text(widget.owner,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 14)),
                              const SizedBox(height: 12),
                              // Play All button
                              Row(children: [
                                GestureDetector(
                                    onTap: () {
                                      if (_playlistSongs.isNotEmpty) {
                                        player.playSongList(_playlistSongs,
                                            startIndex: 0);
                                      }
                                    },
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 28, vertical: 12),
                                        decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF8B5CF6),
                                                  Color(0xFFEC4899)
                                                ]),
                                            borderRadius:
                                                BorderRadius.circular(30)),
                                        child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 22),
                                              SizedBox(width: 6),
                                              Text('Play All',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                            ]))),
                                const SizedBox(width: 12),
                                GestureDetector(
                                    onTap: () {
                                      if (_playlistSongs.isNotEmpty) {
                                        for (final s in _playlistSongs) {
                                          player.addToQueue(s);
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content:
                                                    Text('Added all to queue'),
                                                backgroundColor:
                                                    Color(0xFF8B5CF6)));
                                      }
                                    },
                                    child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.white12,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white24)),
                                        child: const Icon(
                                            Icons.queue_music_rounded,
                                            color: Colors.white,
                                            size: 22))),
                              ]),
                            ])),
                  ])),
                ),

                // Song count header
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text('${_playlistSongs.length} songs',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)))),

                // Songs list
                _isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF8B5CF6))))
                    : _playlistSongs.isEmpty
                        ? const SliverFillRemaining(
                            child: Center(
                                child: Text('No songs found',
                                    style: TextStyle(color: Colors.white38))))
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((ctx, i) {
                            final s = _playlistSongs[i];
                            final isPlaying = player.currentSong?.id == s.id &&
                                player.isPlaying;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CachedNetworkImage(
                                            memCacheWidth: 576,
                                            memCacheHeight: 576,
                                            maxWidthDiskCache: 576,
                                            maxHeightDiskCache: 576,
                                            filterQuality: FilterQuality.high,
                                            imageUrl: s.thumbnail,
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                    width: 52,
                                                    height: 52,
                                                    color:
                                                        const Color(0xFF1A1A2E),
                                                    child: const Icon(
                                                        Icons.music_note,
                                                        color:
                                                            Colors.white24))),
                                        if (isPlaying)
                                          Container(
                                              width: 52,
                                              height: 52,
                                              color: Colors.black45,
                                              child: const Icon(
                                                  Icons.graphic_eq,
                                                  color: Color(0xFF8B5CF6),
                                                  size: 22)),
                                      ])),
                              title: Text(s.title,
                                  style: TextStyle(
                                      color: isPlaying
                                          ? const Color(0xFF8B5CF6)
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(s.artist,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                  maxLines: 1),
                              trailing: IconButton(
                                  icon: const Icon(Icons.more_vert_rounded,
                                      color: Colors.white24, size: 20),
                                  onPressed: () =>
                                      _showSongOptions(context, s, player)),
                              onTap: () => player.playTrack(songToMediaItem(s)),
                            );
                          }, childCount: _playlistSongs.length)),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSongOptions(
      BuildContext context, SongResult s, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          ListTile(
              leading:
                  const Icon(Icons.play_arrow_rounded, color: Colors.white),
              title:
                  const Text('Play Now', style: TextStyle(color: Colors.white)),
              onTap: () {
                player.playTrack(songToMediaItem(s));
                Navigator.pop(context);
              }),
          ListTile(
              leading: const Icon(Icons.queue_music_rounded,
                  color: Color(0xFF8B5CF6)),
              title: const Text('Add to Queue',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                player.addToQueue(s);
                Navigator.pop(context);
              }),
          ListTile(
              leading: Icon(
                  player.isLiked(s.id) ? Icons.favorite : Icons.favorite_border,
                  color: const Color(0xFFEC4899)),
              title: Text(
                  player.isLiked(s.id) ? 'Remove from Liked' : 'Add to Liked',
                  style: const TextStyle(color: Colors.white)),
              onTap: () {
                player.toggleLikeSong(s);
                Navigator.pop(context);
              }),
          ListTile(
              leading:
                  const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
              title:
                  const Text('Download', style: TextStyle(color: Colors.white)),
              onTap: () {
                player.downloadTrack(songToMediaItem(s));
                Navigator.pop(context);
              }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
