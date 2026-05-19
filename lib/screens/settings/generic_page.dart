import 'package:flutter/material.dart';
import '../../widgets/revix_settings_widgets.dart';

class GenericSettingsPage extends StatelessWidget {
  final String title;
  final String section;

  const GenericSettingsPage({
    super.key,
    required this.title,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: title,
      children: [
        SettingsGroup(
          title: section,
          children: [
            SettingsTile(
              icon: Icons.construction_rounded,
              title: 'Standard Module',
              subtitle: 'Core systems active',
              onTap: () {},
            ),
            SettingsTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Advanced Control',
              subtitle: 'Optimized for REVIX ONE',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'MORE OPTIONS COMING SOON',
            style: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }
}
