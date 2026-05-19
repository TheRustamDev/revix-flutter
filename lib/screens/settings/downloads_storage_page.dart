import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/player_provider.dart';
import '../../widgets/revix_settings_widgets.dart';

class DownloadsStoragePage extends StatelessWidget {
  const DownloadsStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsProvider, PlayerProvider>(
      builder: (context, settings, player, _) {
        return SettingsSubPage(
          title: 'Downloads & Storage',
          children: [
            SettingsGroup(
              title: 'Downloads',
              children: [
                SettingsTile(
                  icon: Icons.wifi_off_rounded,
                  title: 'WiFi Only',
                  subtitle: 'Download songs only when connected to WiFi',
                  trailing: Switch(
                    value: settings.downloads.downloadOverWifiOnly,
                    onChanged: (v) => settings.setDownloadOverWifiOnly(v),
                    activeColor: const Color(0xFF0EA5E9),
                  ),
                ),
                SettingsTile(
                  icon: Icons.high_quality_rounded,
                  title: 'Download Quality',
                  subtitle: settings.downloads.quality,
                  onTap: () => _showDownloadQualitySelector(context, settings),
                ),
                SettingsTile(
                  icon: Icons.downloading_rounded,
                  title: 'Downloaded Songs',
                  subtitle: '${player.downloadsCount} tracks saved offline',
                  trailing: Text(
                    '${player.downloadsSize.toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Storage Management',
              children: [
                SettingsTile(
                  icon: Icons.storage_rounded,
                  title: 'Cache Usage',
                  subtitle: 'Optimizing app performance',
                  trailing: Text(
                    '${player.cacheSize.toStringAsFixed(1)} MB',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space safely',
                  onTap: () async {
                    await player.clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cache cleared successfully'),
                          backgroundColor: Color(0xFF1A1A2E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDownloadQualitySelector(
      BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('Download Quality',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...[
            {'q': 'Data Saver', 'd': 'Lowest file size (Basic)'},
            {'q': 'Normal', 'd': 'Balanced size & quality'},
            {'q': 'High', 'd': 'Premium audio fidelity'},
            {'q': 'Lossless', 'd': 'Untouched audio quality'},
          ].map((item) {
            final q = item['q']!;
            final d = item['d']!;
            return ListTile(
              title: Text(q,
                  style: TextStyle(
                      color: settings.downloads.quality == q
                          ? const Color(0xFF0EA5E9)
                          : Colors.white)),
              subtitle: Text(d,
                  style: TextStyle(color: Colors.white.withOpacity(0.5))),
              onTap: () {
                settings.setDownloadQuality(q);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
