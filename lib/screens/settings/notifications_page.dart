import 'package:flutter/material.dart';
import '../../widgets/revix_settings_widgets.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubPage(
      title: 'Notifications',
      children: [
        SettingsGroup(
          title: 'Alerts',
          children: [
            SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Push Notifications',
              subtitle: 'New releases and activities',
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: const Color(0xFFEC4899),
              ),
            ),
            SettingsTile(
              icon: Icons.mail_outline_rounded,
              title: 'Email Updates',
              subtitle: 'Monthly recaps and news',
              trailing: Switch(
                value: false,
                onChanged: (v) {},
                activeColor: const Color(0xFFEC4899),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
