import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import '../providers/player_provider.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'profile_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  DateTime? _lastHomeTap;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    const ExploreScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  bool _isNavVisible = false;
  Timer? _navTimer;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.explore_outlined, 'label': 'Explore'},
    {'icon': Icons.library_music_outlined, 'label': 'Library'},
    {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
  ];

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    if (index == 0 && _selectedIndex == 0) {
      final now = DateTime.now();
      if (_lastHomeTap != null &&
          now.difference(_lastHomeTap!) < const Duration(milliseconds: 500)) {
        _homeKey.currentState?.scrollToTop();
      }
      _lastHomeTap = now;
    }
    setState(() => _selectedIndex = index);
    _resetTimer();
  }

  void _toggleNav() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isNavVisible = !_isNavVisible;
      if (_isNavVisible) _resetTimer();
    });
  }

  void _resetTimer() {
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _isNavVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final theme = context.watch<ThemeProvider>();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.bgColor1,
              theme.bgColor2,
              theme.bgColor3,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Screens
            IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),

            // Mini Player — sits above nav bar
            if (player.currentSong != null)
              Positioned(
                bottom: 88 + bottomPad,
                left: 0,
                right: 0,
                child: _MiniPlayer(player: player),
              ),

            // FLOATING NAV BAR
            Positioned(
              bottom: 20 + bottomPad,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  height: 64,
                  width: _isNavVisible
                      ? MediaQuery.of(context).size.width - 32
                      : 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: _isNavVisible
                        ? const Color(0xFF0D0D1A).withOpacity(0.96)
                        : Colors.transparent,
                    boxShadow: _isNavVisible
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ]
                        : [],
                    border: _isNavVisible
                        ? Border.all(
                            color: Colors.white.withOpacity(0.08), width: 0.5)
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: _isNavVisible ? 20 : 0,
                          sigmaY: _isNavVisible ? 20 : 0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // THE ORB (Persistent in center)
                            GestureDetector(
                              onTap: _toggleNav,
                              onLongPress: () {
                                HapticFeedback.heavyImpact();
                                _toggleNav();
                              },
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6)
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'R',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // EXPANDING NAV ITEMS
                            if (_isNavVisible) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children:
                                      List.generate(_navItems.length, (i) {
                                    final item = _navItems[i];
                                    final isSelected = _selectedIndex == i;
                                    return _NavButton(
                                      icon: item['icon'],
                                      label: item['label'],
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() => _selectedIndex = i);
                                        _onTabTapped(i);
                                        _resetTimer();
                                      },
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white38,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// GLASSMORPHIC MINI PLAYER
// ──────────────────────────────────────────────
class _MiniPlayer extends StatelessWidget {
  final PlayerProvider player;
  const _MiniPlayer({required this.player});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF0D0D1A).withOpacity(0.92),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          // Album art + waveform
                          Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: player.currentSong?.artUri != null
                                    ? CachedNetworkImage(
                                        memCacheWidth: 576,
                                        memCacheHeight: 576,
                                        maxWidthDiskCache: 576,
                                        maxHeightDiskCache: 576,
                                        filterQuality: FilterQuality.high,
                                        imageUrl: player.currentSong!.artUri
                                            .toString(),
                                        width: 46,
                                        height: 46,
                                        fit: BoxFit.cover)
                                    : Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                            gradient: LinearGradient(colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFFEC4899)
                                        ]))),
                              ),
                              // Waveform overlay at bottom of art
                              Positioned(
                                bottom: 4,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                      4,
                                      (i) => AnimatedContainer(
                                            duration: Duration(
                                                milliseconds: 200 + i * 80),
                                            width: 2,
                                            height: player.isPlaying
                                                ? (4.0 + i * 3.0)
                                                : 2.0,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEC4899),
                                              borderRadius:
                                                  BorderRadius.circular(1),
                                            ),
                                          )),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Title + artist + progress
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.currentSong?.title ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(children: [
                                  Flexible(
                                    child: Text(
                                      player.currentSong?.artist ?? '',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified,
                                      color: Color(0xFF8B5CF6), size: 10),
                                  if (player.autoPlay) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6)
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: const Color(0xFF8B5CF6)
                                                .withOpacity(0.5),
                                            width: 0.5),
                                      ),
                                      child: const Text('AUTO',
                                          style: TextStyle(
                                              color: Color(0xFF8B5CF6),
                                              fontSize: 7,
                                              fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 5),
                                // Pink progress bar no thumb
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: player.progress,
                                    backgroundColor: Colors.white12,
                                    valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFFEC4899)),
                                    minHeight: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Controls
                          GestureDetector(
                              onTap: player.skipToPrevious,
                              child: const Icon(Icons.skip_previous_rounded,
                                  color: Colors.white60, size: 22)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              player.togglePlayPause();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF8B5CF6), width: 1.5),
                              ),
                              child: Icon(
                                player.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                              onTap: player.skipToNext,
                              child: const Icon(Icons.skip_next_rounded,
                                  color: Colors.white60, size: 22)),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: player.toggleRepeat,
                            child: Icon(
                              Icons.repeat_rounded,
                              color: player.repeatMode !=
                                      AudioServiceRepeatMode.none
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white24,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
