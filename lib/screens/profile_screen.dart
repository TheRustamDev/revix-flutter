import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _visualizerController;
  String _selectedTimeframe = 'This Month';

  @override
  void initState() {
    super.initState();
    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _visualizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // TOP HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'REVIX ONE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: [
                    _iconBtn(Icons.notifications_none_rounded, hasBadge: true,
                        onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Notifications: No new messages'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Color(0xFF8B5CF6),
                      ));
                    }),
                    const SizedBox(width: 15),
                    _iconBtn(Icons.settings_outlined, onTap: () {
                      _showSettingsSheet(context);
                    }),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // PROFILE CARD
            _profileCard(player),

            const SizedBox(height: 25),

            // STATS BAR
            _statsBar(player),

            const SizedBox(height: 35),

            // LISTENING TIME SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Listening Time', style: _sectionStyle),
                GestureDetector(
                  onTap: _showTimeframeSheet,
                  child: Row(
                    children: [
                      Text(_selectedTimeframe,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13)),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _listeningTimeCard(player),

            const SizedBox(height: 35),

            // MUSIC PERSONALITY SECTION
            const Text('Music Personality', style: _sectionStyle),
            const SizedBox(height: 15),
            _personalityCard(player),

            const SizedBox(height: 35),

            // BADGES SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Badges', style: _sectionStyle),
                GestureDetector(
                  onTap: _showAllBadges,
                  child: const Text('View All',
                      style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _badgesGrid(player),

            const SizedBox(height: 35),

            // TOP ARTISTS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Artists', style: _sectionStyle),
                GestureDetector(
                  onTap: _showAllArtists,
                  child: const Text('See All',
                      style: TextStyle(
                          color: Color(0xFF8B5CF6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _topArtistsList(player),

            const SizedBox(height: 120), // Bottom padding for mini player
          ],
        ),
      ),
    );
  }

  static const _sectionStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  Widget _iconBtn(IconData icon, {bool hasBadge = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (hasBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileCard(PlayerProvider player) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        children: [
          // Waveform Background
          Positioned(
            right: 0,
            top: 10,
            child: AnimatedBuilder(
              animation: _visualizerController,
              builder: (_, __) => CustomPaint(
                size: const Size(120, 60),
                painter: _WavePainter(_visualizerController.value),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar with glow
                  GestureDetector(
                    onTap: _showAvatarOptions,
                    onLongPress: _showStatusSelector,
                    child: Container(
                      width: 80,
                      height: 80,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                        ),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.black,
                        child: ClipOval(
                          child:
                              Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Melophile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.check_circle,
                                color: Color(0xFF8B5CF6), size: 16),
                          ],
                        ),
                        const Text(
                          '@melophile.one',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Music is not what I do, it\'s who I am. \u266B',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  _badgeInfo('Premium', 'Member', Icons.diamond_outlined,
                      onTap: _showPremiumDetails),
                  const SizedBox(width: 12),
                  _badgeInfo(
                      'Joined', 'May 2023', Icons.calendar_month_outlined,
                      onTap: _showJoinedHistory),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showProfileEditor,
                    child: const Text(
                      'Edit Profile >',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeInfo(String top, String bottom, IconData icon,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(top,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
                Text(bottom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsBar(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statItem(
            Icons.music_note_rounded,
            player.recentlyPlayed.length.toString(),
            'Songs',
            const Color(0xFF8B5CF6),
            'all songs'),
        _statItem(Icons.favorite_rounded, player.likedSongsCount.toString(),
            'Liked', const Color(0xFFEC4899), 'liked songs'),
        _statItem(Icons.playlist_play_rounded, '0', 'Playlists',
            const Color(0xFF00C2FF), 'playlists'),
        _statItem(
            Icons.download_rounded,
            player.downloadedSongsCount.toString(),
            'Downloads',
            const Color(0xFFFFA800),
            'downloads'),
      ],
    );
  }

  Widget _statItem(
      IconData icon, String val, String label, Color color, String query) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleStatTap(label, query),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(val,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _handleStatTap(String label, String query) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening $label...'),
      backgroundColor: const Color(0xFF8B5CF6),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showAvatarOptions() {
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
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Profile Photo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Change Photo',
                  style: TextStyle(color: Colors.white))),
          ListTile(
              leading:
                  const Icon(Icons.face_unlock_rounded, color: Colors.white),
              title: const Text('Customize Avatar',
                  style: TextStyle(color: Colors.white))),
          ListTile(
              leading: const Icon(Icons.palette_outlined, color: Colors.white),
              title: const Text('Profile Themes',
                  style: TextStyle(color: Colors.white))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showStatusSelector() {
    final statuses = [
      '🎧 Listening',
      '🔥 Vibing',
      '😴 Chilling',
      '🚀 Exploring'
    ];
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
            child: Text('Select Status',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          ...statuses.map((s) => ListTile(
                title: Text(s, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showPremiumDetails() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Plan: REVIX One Premium Gold'),
        behavior: SnackBarBehavior.floating));
  }

  void _showJoinedHistory() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Account Milestone: 1 Year Anniversary in 2 months!'),
        behavior: SnackBarBehavior.floating));
  }

  void _showSettingsSheet(BuildContext context) {
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
              child: Text('Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              secondary:
                  const Icon(Icons.flash_on_rounded, color: Color(0xFF8B5CF6)),
              title: const Text('Auto-play',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Play similar songs automatically',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
              value: player.autoPlay,
              onChanged: (v) => player.setAutoPlay(v),
            ),
            ListTile(
              leading: const Icon(Icons.high_quality_rounded,
                  color: Color(0xFFEC4899)),
              title: const Text('Audio Quality',
                  style: TextStyle(color: Colors.white)),
              trailing: Text(player.audioQuality,
                  style: const TextStyle(color: Color(0xFFEC4899))),
              onTap: () {
                final qualities = ['Normal', 'High', 'Lossless'];
                final next = qualities[
                    (qualities.indexOf(player.audioQuality) + 1) %
                        qualities.length];
                player.setAudioQuality(next);
              },
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading:
                  const Icon(Icons.delete_sweep_rounded, color: Colors.white60),
              title: const Text('Clear History',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showProfileEditor() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Opening Profile Editor...'),
        behavior: SnackBarBehavior.floating));
  }

  void _showTimeframeSheet() {
    final options = [
      'This Week',
      'This Month',
      'Last Month',
      'Yearly',
      'All Time'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map((o) => ListTile(
                  title: Text(o,
                      style: TextStyle(
                          color: _selectedTimeframe == o
                              ? const Color(0xFF8B5CF6)
                              : Colors.white)),
                  onTap: () {
                    setState(() => _selectedTimeframe = o);
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  Widget _listeningTimeCard(PlayerProvider player) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Circular Chart
          Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(100, 100),
                painter: _CircleChartPainter(),
              ),
              const Column(
                children: [
                  Text('32h 45m',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text('Total Listening',
                      style: TextStyle(color: Colors.white38, fontSize: 8)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 25),
          // Bar Chart
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('More than last month',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                    SizedBox(width: 5),
                    Text('\u2191 18%',
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _bar('Mon', 0.4),
                    _bar('Tue', 0.6),
                    _bar('Wed', 0.3),
                    _bar('Thu', 0.8),
                    _bar('Fri', 0.5),
                    _bar('Sat', 1.0, isSpecial: true),
                    _bar('Sun', 0.7),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('M',
                        style: TextStyle(color: Colors.white38, fontSize: 8)),
                    Text('T',
                        style: TextStyle(color: Colors.white38, fontSize: 8)),
                    Text('W',
                        style: TextStyle(color: Colors.white38, fontSize: 8)),
                    Text('T',
                        style: TextStyle(color: Colors.white38, fontSize: 8)),
                    Text('F',
                        style: TextStyle(color: Colors.white38, fontSize: 8)),
                    Text('S',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                    Text('S',
                        style: TextStyle(color: Colors.white38, fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(String day, double heightFactor, {bool isSpecial = false}) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$day: ${(heightFactor * 10).toStringAsFixed(1)} listening hours'),
        backgroundColor:
            isSpecial ? const Color(0xFFEC4899) : const Color(0xFF0F0F1E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      )),
      child: Container(
        width: 14,
        height: 60 * heightFactor,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            colors: isSpecial
                ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                : [
                    const Color(0xFF8B5CF6).withOpacity(0.5),
                    const Color(0xFF8B5CF6).withOpacity(0.8)
                  ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ),
    );
  }

  Widget _personalityCard(PlayerProvider player) {
    final genre = player.topGenre;
    String personality = 'The Explorer';
    String desc = 'You love discovering fresh sounds and trending hits.';
    if (genre.toLowerCase().contains('punjabi')) {
      personality = 'Desi Vibe';
      desc = 'You carry the energy of Punjab in your soul.';
    } else if (genre.toLowerCase().contains('lofi')) {
      personality = 'Chill Soul';
      desc = 'You find peace in the most gentle melodies.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.15),
            const Color(0xFFEC4899).withOpacity(0.15)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: Color(0xFFEC4899), size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(personality,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllBadges() =>
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Opening Achievements Collection...'),
          behavior: SnackBarBehavior.floating));
  void _showAllArtists() =>
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Opening Artist Ranking History...'),
          behavior: SnackBarBehavior.floating));

  Widget _badgesGrid(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _badgeItem(Icons.headphones_rounded, 'VIBE MASTER', '50 Hours',
            [const Color(0xFF8B5CF6), const Color(0xFF00C2FF)], 'Legendary'),
        _badgeItem(
            Icons.local_fire_department_rounded,
            'TREND SETTER',
            '100 Songs',
            [const Color(0xFFFF6B00), const Color(0xFFFFB800)],
            'Epic'),
        _badgeItem(Icons.star_rounded, 'EARLY EXPLORER', 'New Release',
            [const Color(0xFFEC4899), const Color(0xFF8B5CF6)], 'Rare'),
        _badgeItem(Icons.album_rounded, 'GENRE LOVER', '10+ Genres',
            [const Color(0xFF00C2FF), const Color(0xFF8B5CF6)], 'Rare'),
      ],
    );
  }

  Widget _badgeItem(IconData icon, String title, String subtitle,
      List<Color> colors, String rarity) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showBadgeDetails(title, subtitle, rarity),
        child: Column(
          children: [
            CustomPaint(
              size: const Size(60, 65),
              painter: _HexagonPainter(colors),
              child: SizedBox(
                width: 60,
                height: 65,
                child: Center(child: Icon(icon, color: Colors.white, size: 24)),
              ),
            ),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetails(String title, String subtitle, String rarity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 30),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(rarity,
              style: TextStyle(
                  color: rarity == 'Legendary'
                      ? Colors.orangeAccent
                      : Colors.white38,
                  fontSize: 13)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(
                value: 0.8,
                backgroundColor: Colors.white10,
                color: const Color(0xFF8B5CF6)),
          ),
          const SizedBox(height: 10),
          const Text('80% to next milestone',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _topArtistsList(PlayerProvider player) {
    final artists = player.topArtists;
    if (artists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Listen to music to see your top artists!',
            style: TextStyle(color: Colors.white24, fontSize: 13)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: artists.asMap().entries.map((e) {
          final idx = e.key;
          final name = e.value;
          final colors = [
            const Color(0xFF8B5CF6),
            const Color(0xFFEC4899),
            const Color(0xFF00C2FF),
            const Color(0xFFFF6B00),
            const Color(0xFF10B981)
          ];
          return _artistItem(
              (idx + 1).toString(),
              name,
              'Top Artist',
              'https://music.youtube.com/img/artist_placeholder.png',
              colors[idx % colors.length]);
        }).toList(),
      ),
    );
  }

  Widget _artistItem(
      String rank, String name, String subtitle, String img, Color glow) {
    return GestureDetector(
      onTap: () => _showArtistProfile(name),
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: glow, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: glow.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 1),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF1A1A2E),
                    child: Icon(Icons.person, color: Colors.white24, size: 30),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: glow,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Text(rank,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  void _showArtistProfile(String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              title: Text(name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Top Artist')),
          ListTile(
              leading: const Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white),
              title: const Text('Artist Radio',
                  style: TextStyle(color: Colors.white))),
          ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded,
                  color: Colors.white),
              title: const Text('Follow Artist',
                  style: TextStyle(color: Colors.white))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  _WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    for (int i = 0; i < 20; i++) {
      double x = i * 6.0;
      // Use animationValue to create movement
      double seed = (animationValue * pi * 2) + (i * 0.5);
      double h = (sin(seed).abs() * 0.7 + 0.3) * size.height;
      path.moveTo(x, size.height / 2 - h / 2);
      path.lineTo(x, size.height / 2 + h / 2);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _CircleChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF8B5CF6),
          Color(0xFFEC4899),
          Color(0xFFFFA800),
          Color(0xFF8B5CF6)
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        4.5, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexagonPainter extends CustomPainter {
  final List<Color> colors;
  _HexagonPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    double w = size.width;
    double h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(colors: colors).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader =
          LinearGradient(colors: colors.map((e) => e.withOpacity(0.1)).toList())
              .createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
