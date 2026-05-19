import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/revix_settings_widgets.dart';

class AppearanceVisualsPage extends StatelessWidget {
  const AppearanceVisualsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final app = settings.appearance;

        return SettingsSubPage(
          title: 'Appearance & Visuals',
          children: [
            SettingsGroup(
              title: 'Theme Identity',
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'AMOLED Mode',
                  subtitle: 'True black backgrounds for OLED screens',
                  trailing: Switch(
                    value: app.amoledMode,
                    onChanged: (v) => settings.setAmoledMode(v),
                    activeColor: app.accentColor,
                  ),
                ),
                SettingsTile(
                  icon: Icons.color_lens_rounded,
                  title: 'Accent Color',
                  subtitle: 'Global primary color theme',
                  onTap: () => _showColorPicker(context, settings),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: app.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: app.accentColor
                              .withOpacity(0.5 * app.glowIntensity),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Visual Effects',
              children: [
                _sliderTile(
                  icon: Icons.blur_on_rounded,
                  title: 'Glass Blur Intensity',
                  value: app.blurIntensity,
                  min: 0,
                  max: 50,
                  onChanged: (v) => settings.setBlurIntensity(v),
                ),
                _sliderTile(
                  icon: Icons.wb_iridescent_rounded,
                  title: 'Glow Intensity',
                  value: app.glowIntensity,
                  onChanged: (v) => settings.setGlowIntensity(v),
                ),
                SettingsTile(
                  icon: Icons.waves_rounded,
                  title: 'Visualizer Style',
                  subtitle: app.visualizerStyle,
                  onTap: () => _showVisualizerPicker(context, settings),
                ),
              ],
            ),
            SettingsGroup(
              title: 'Motion & Animations',
              children: [
                SettingsTile(
                  icon: Icons.motion_photos_off_rounded,
                  title: 'Reduced Motion',
                  subtitle: 'Disable heavy animations and parallax',
                  trailing: Switch(
                    value: app.reducedMotion,
                    onChanged: (v) => settings.setReducedMotion(v),
                    activeColor: app.accentColor,
                  ),
                ),
                _sliderTile(
                  icon: Icons.speed_rounded,
                  title: 'Animation Speed',
                  subtitle: 'Scale: ${app.animationSpeed.toStringAsFixed(1)}x',
                  value: app.animationSpeed,
                  min: 0.2,
                  max: 2.0,
                  onChanged: (v) => settings.setAnimationSpeed(v),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _sliderTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required double value,
    double min = 0.0,
    double max = 1.0,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                ],
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: const Color(0xFF8B5CF6).withOpacity(0.8),
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, SettingsProvider settings) {
    final colors = [
      0xFF8B5CF6, // Violet (Default)
      0xFFEC4899, // Pink
      0xFF0EA5E9, // Blue
      0xFF00FFD1, // Cyan
      0xFFFFD700, // Gold
      0xFFFF4500, // Orange Red
      0xFF32CD32, // Lime Green
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Accent Color',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: colors.map((c) {
                final isSelected = settings.appearance.accentColorValue == c;
                return GestureDetector(
                  onTap: () {
                    settings.setAccentColor(c);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Color(c).withOpacity(0.5),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showVisualizerPicker(BuildContext context, SettingsProvider settings) {
    final styles = ['Waveform', 'Cyber Pulse', 'Orbital', 'Minimal Bar'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          const Text('Visualizer Style',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...styles.map((s) => ListTile(
                title: Text(s,
                    style: TextStyle(
                        color: settings.appearance.visualizerStyle == s
                            ? settings.appearance.accentColor
                            : Colors.white)),
                onTap: () {
                  settings.setVisualizerStyle(s);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
