import 'package:flutter/material.dart';
import '../../widgets/revix_settings_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: 'About REVIX',
      children: [
        const SettingsGroup(
          title: 'Application',
          children: [
            SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Release Version',
              subtitle: 'v3.0.0 (Premium Build)',
            ),
            SettingsTile(
              icon: Icons.history_rounded,
              title: 'Changelog',
              subtitle: 'See what\'s new',
            ),
          ],
        ),
        SettingsGroup(
          title: 'Legal',
          children: [
            SettingsTile(
              icon: Icons.gavel_rounded,
              title: 'Terms of Service',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.privacy_tip_rounded,
              title: 'Privacy Policy',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Opacity(
            opacity: 0.3,
            child: Column(
              children: [
                const Text(
                  'REVIX Labs',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  'BEYOND AUDIBLE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
