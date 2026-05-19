import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/revix_hero_section.dart';
import '../widgets/revix_control_card.dart';
import 'settings/playback_audio_page.dart';
import 'settings/downloads_storage_page.dart';
import 'settings/notifications_page.dart';
import 'settings/appearance_visuals_page.dart';
import 'settings/about_page.dart';
import 'settings/generic_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.black,
            floating: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'CONTROL CENTER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RevixHeroSection(
                  username: 'Revix User',
                  quality: settings.audioQuality,
                  device: 'Android',
                  storage: '1.2 GB Cached',
                ),
                const SizedBox(height: 10),
                _sectionHeader('Core Systems'),
                RevixCategoryCard(
                  icon: Icons.audio_file_rounded,
                  title: 'Playback & Audio',
                  status: 'Quality: ${settings.audioQuality}',
                  glowColor: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PlaybackAudioPage()),
                  ),
                ),
                RevixCategoryCard(
                  icon: Icons.download_done_rounded,
                  title: 'Downloads & Storage',
                  status: 'Smart Downloads: Active',
                  glowColor: const Color(0xFF0EA5E9),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DownloadsStoragePage()),
                  ),
                ),
                RevixCategoryCard(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications',
                  status: 'All alerts enabled',
                  glowColor: const Color(0xFFEC4899),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsPage()),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionHeader('Customization'),
                RevixCategoryCard(
                  icon: Icons.palette_rounded,
                  title: 'Appearance & Visuals',
                  status: 'Theme: Dynamic Dark',
                  glowColor: const Color(0xFF00FFD1),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AppearanceVisualsPage()),
                  ),
                ),
                RevixCategoryCard(
                  icon: Icons.dns_rounded,
                  title: 'Library & Content',
                  status: 'History & Backup',
                  glowColor: const Color(0xFF00BFFF),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GenericSettingsPage(
                            title: 'Library & Content', section: 'Inventory')),
                  ),
                ),
                RevixCategoryCard(
                  icon: Icons.settings_input_component_rounded,
                  title: 'Experimental Labs',
                  status: '3 active tweaks',
                  glowColor: const Color(0xFFFFD700),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GenericSettingsPage(
                            title: 'Experimental Labs', section: 'Prototypes')),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionHeader('Security & Intelligence'),
                RevixCategoryCard(
                  icon: Icons.devices_other_rounded,
                  title: 'Devices & Connectivity',
                  status: '1 active pulse',
                  glowColor: const Color(0xFFA5F3FC),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GenericSettingsPage(
                            title: 'Devices & Connectivity', section: 'Node')),
                  ),
                ),
                RevixCategoryCard(
                  icon: Icons.security_rounded,
                  title: 'Privacy & Security',
                  status: 'Your data is encrypted',
                  glowColor: Colors.blueAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GenericSettingsPage(
                            title: 'Privacy & Security',
                            section: 'Encryption')),
                  ),
                ),
                RevixCategoryCard(
                  icon: Icons.info_outline_rounded,
                  title: 'About REVIX',
                  status: 'v3.0.0 (Premium)',
                  glowColor: Colors.white,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Opacity(
                    opacity: 0.3,
                    child: Column(
                      children: [
                        const Text(
                          'REVIX ONE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'BEYOND AUDIBLE',
                          style: TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
