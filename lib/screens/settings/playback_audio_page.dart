import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/revix_settings_widgets.dart';

class PlaybackAudioPage extends StatelessWidget {
  const PlaybackAudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return SettingsSubPage(
      title: 'Playback & Audio',
      children: [
        SettingsGroup(
          title: 'Streaming Quality',
          children: [
            SettingsTile(
              icon: Icons.high_quality_rounded,
              title: 'Audio Quality',
              subtitle: 'Currently: ${settings.audioQuality}',
              onTap: () => _showQualitySelector(context, settings),
            ),
            SettingsTile(
              icon: Icons.speed_rounded,
              title: 'Dynamic Bitrate',
              subtitle: 'Adjust quality to network speed',
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: 'Playback Behavior',
          children: [
            SettingsTile(
              icon: Icons.shuffle_rounded,
              title: 'Auto-Play',
              subtitle: 'Play similar tracks automatically',
              trailing: Switch(
                value: settings.autoPlay,
                onChanged: (v) => settings.setAutoPlay(v),
                activeColor: const Color(0xFF8B5CF6),
              ),
            ),
            SettingsTile(
              icon: Icons.volume_up_rounded,
              title: 'Audio Normalization',
              subtitle: 'Consistent volume across all tracks',
              trailing: Switch(
                value: false,
                onChanged: (v) {},
                activeColor: const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showQualitySelector(BuildContext context, SettingsProvider settings) {
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
          ...[
            {'q': 'Data Saver', 'd': 'Lowest data usage (48-64kbps)'},
            {'q': 'Normal', 'd': 'Balanced everyday playback (96-128kbps)'},
            {'q': 'High', 'd': 'Improved clarity and stereo (160-192kbps)'},
            {'q': 'Very High', 'd': 'Premium high-quality (256kbps)'},
            {'q': 'Lossless', 'd': 'Best possible audio fidelity'},
          ].map((item) {
            final q = item['q']!;
            final d = item['d']!;
            return ListTile(
              title: Text(q,
                  style: TextStyle(
                      color: settings.audioQuality == q
                          ? const Color(0xFF8B5CF6)
                          : Colors.white)),
              subtitle: Text(d,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              onTap: () {
                settings.setAudioQuality(q);
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
