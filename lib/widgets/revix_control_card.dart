import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class RevixCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final VoidCallback onTap;
  final Color glowColor;

  const RevixCategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.status,
    required this.onTap,
    this.glowColor = const Color(0xFF8B5CF6),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final app = settings.appearance;
        final intensity = app.glowIntensity;
        final isAmoled = app.amoledMode;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAmoled
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFF1A1A2E).withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: glowColor.withOpacity(0.15 * intensity),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icon Container with Glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: glowColor.withOpacity(0.1 * intensity),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: glowColor.withOpacity(0.3 * intensity)),
                      boxShadow: [
                        if (intensity > 0.1)
                          BoxShadow(
                            color: glowColor.withOpacity(0.2 * intensity),
                            blurRadius: 10 * intensity,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Icon(icon, color: glowColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.2), size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
