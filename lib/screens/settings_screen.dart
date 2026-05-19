import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _sectionHeader('Playback'),
          _settingItem(
            title: 'Audio Quality',
            subtitle: player.audioQuality,
            icon: Icons.high_quality_rounded,
            onTap: () => _showQualitySelector(context, player),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto Play',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            subtitle: const Text('Play similar songs when queue ends',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: player.autoPlay,
            onChanged: (val) => player.setSetting('autoPlay', val),
            activeColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 30),
          _sectionHeader('Library & Cache'),
          _settingItem(
            title: 'Clear Cache',
            subtitle: 'Free up storage space (0 MB)',
            icon: Icons.delete_outline_rounded,
            color: Colors.redAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Cache cleared!'),
                backgroundColor: Color(0xFF8B5CF6),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
          _settingItem(
            title: 'YouTube Music Sync',
            subtitle: 'Connect your account',
            icon: Icons.sync_rounded,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  backgroundColor: Color(0xFF1A1A2E),
                  title: Text('Coming Soon',
                      style: TextStyle(color: Colors.white)),
                  content: Text(
                      'YouTube Music account sync will be available in the next update.',
                      style: TextStyle(color: Colors.white70)),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          _sectionHeader('About'),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('REVIX One Version',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            trailing: Text('v3.0.0 (Premium)',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          _settingItem(
            title: 'Legal',
            subtitle: 'Privacy Policy & Terms',
            icon: Icons.gavel_rounded,
            onTap: () {},
          ),
          _settingItem(
            title: 'Support',
            subtitle: 'Get help or report a bug',
            icon: Icons.help_outline_rounded,
            onTap: () {},
          ),
          const SizedBox(height: 50),
          Center(
            child: Text(
              'Made with \u2764 in REVIX Labs',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF8B5CF6),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _settingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing:
          const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
    );
  }

  void _showQualitySelector(BuildContext context, PlayerProvider player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('Audio Quality',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...['Normal', 'High', 'Lossless'].map((q) => ListTile(
                title: Text(q,
                    style: TextStyle(
                        color: player.audioQuality == q
                            ? const Color(0xFF8B5CF6)
                            : Colors.white)),
                onTap: () {
                  player.setAudioQuality(q);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
