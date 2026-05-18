import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
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

class _MainWrapperState extends State<MainWrapper>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? _lastHomeTap;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  bool _isNavVisible = false;
  Timer? _navHideTimer;
  late AnimationController _navAnimCtrl;
  late Animation<double> _navFade;

  @override
  void initState() {
    super.initState();
    _navAnimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _navFade = CurvedAnimation(parent: _navAnimCtrl, curve: Curves.easeOut);
  }

  void _toggleNav() {
    _navHideTimer?.cancel();
    if (_isNavVisible) {
      _navAnimCtrl.reverse();
      setState(() => _isNavVisible = false);
    } else {
      _navAnimCtrl.forward();
      setState(() => _isNavVisible = true);
      _navHideTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isNavVisible) {
          _navAnimCtrl.reverse();
          setState(() => _isNavVisible = false);
        }
      });
    }
  }

  void _resetHideTimer() {
    _navHideTimer?.cancel();
    _navHideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isNavVisible) {
        _navAnimCtrl.reverse();
        setState(() => _isNavVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _navHideTimer?.cancel();
    _navAnimCtrl.dispose();
    super.dispose();
  }

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey),
    const ExploreScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.explore_outlined, label: 'Explore'),
    _NavItem(icon: Icons.library_music_outlined, label: 'Library'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  void _onTabTapped(int index) {
    if (index == 0 && _selectedIndex == 0) {
      final now = DateTime.now();
      if (_lastHomeTap != null &&
          now.difference(_lastHomeTap!) < const Duration(milliseconds: 500)) {
        _homeKey.currentState?.scrollToTop();
      }
      _lastHomeTap = now;
    }
    setState(() => _selectedIndex = index);
    _resetHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Screens
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),

          // Mini Player
          if (player.currentSong != null)
            Positioned(
              bottom: 88 + bottomPad,
              left: 12,
              right: 12,
              child: _MiniPlayer(player: player),
            ),

          // Floating Nav — only circle visible by default
          Positioned(
            bottom: 16 + bottomPad,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nav items row — fades in/out
                FadeTransition(
                  opacity: _navFade,
                  child: IgnorePointer(
                    ignoring: !_isNavVisible,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D1A).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white10, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 24,
                              spreadRadius: 2),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Left side items (Home, Explore)
                          ..._navItems
                              .sublist(0, 2)
                              .asMap()
                              .entries
                              .map((e) => _NavButton(
                                    item: e.value,
                                    selected: _selectedIndex == e.key,
                                    onTap: () => _onTabTapped(e.key),
                                  )),
                          // Center spacer
                          const SizedBox(width: 56),
                          // Right side items (Library, Profile)
                          ..._navItems
                              .sublist(2)
                              .asMap()
                              .entries
                              .map((e) => _NavButton(
                                    item: e.value,
                                    selected: _selectedIndex == e.key + 2,
                                    onTap: () => _onTabTapped(e.key + 2),
                                  )),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Center floating circle — always visible
                GestureDetector(
                  onTap: _toggleNav,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isNavVisible
                            ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]
                            : [
                                const Color(0xFF5A3A9E),
                                const Color(0xFF9B3070)
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6)
                              .withOpacity(_isNavVisible ? 0.5 : 0.25),
                          blurRadius: _isNavVisible ? 20 : 12,
                          spreadRadius: _isNavVisible ? 2 : 0,
                        )
                      ],
                    ),
                    child: Icon(
                      _isNavVisible ? Icons.close_rounded : Icons.apps_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: selected ? const Color(0xFF8B5CF6) : Colors.white38,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                color: selected ? const Color(0xFF8B5CF6) : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// MINI PLAYER
// ──────────────────────────────────────────────
class _MiniPlayer extends StatelessWidget {
  final PlayerProvider player;
  const _MiniPlayer({required this.player});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1A2E),
          border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: player.currentSong?.artUri != null
                      ? CachedNetworkImage(
                          imageUrl: player.currentSong!.artUri.toString(),
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.currentSong?.title ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        player.currentSong?.artist ?? '',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: Colors.white, size: 26),
                  onPressed: player.skipToPrevious,
                  padding: EdgeInsets.zero,
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF8B5CF6), width: 2),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      player.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: player.togglePlayPause,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded,
                      color: Colors.white, size: 26),
                  onPressed: player.skipToNext,
                  padding: EdgeInsets.zero,
                ),
                if (player.sleepTimerRemaining > 0)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.timer_rounded,
                            color: Color(0xFFFFD700), size: 12),
                        const SizedBox(width: 4),
                        Text('${player.sleepTimerRemaining ~/ 60}m',
                            style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.bold))
                      ])),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: SliderComponentShape.noOverlay,
                trackHeight: 2.5,
                activeTrackColor: const Color(0xFF8B5CF6),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFFEC4899),
              ),
              child: Slider(
                value: player.progress,
                onChanged: (v) => player.seekTo(Duration(
                    milliseconds:
                        (v * player.duration.inMilliseconds).round())),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
