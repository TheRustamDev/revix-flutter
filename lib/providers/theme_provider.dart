import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ThemeProvider extends ChangeNotifier {
  Color bgColor1 = const Color(0xFF0D0820);
  Color bgColor2 = const Color(0xFF000000);
  String? _lastUrl;
  bool _processing = false;

  LinearGradient get bg => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          bgColor1,
          Color.lerp(bgColor1, Colors.black, 0.6)!,
          Colors.black,
        ],
        stops: const [0.0, 0.55, 1.0],
      );

  Future<void> updateFromUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    if (url == _lastUrl) return;
    if (_processing) return;
    _processing = true;
    _lastUrl = url;

    try {
      // Use CachedNetworkImageProvider — safer on Android
      final generator = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
        size: const Size(112, 112),
        maximumColorCount: 16,
        timeout: const Duration(seconds: 8),
      );

      Color? base = generator.vibrantColor?.color ??
          generator.dominantColor?.color ??
          generator.mutedColor?.color;

      if (base != null) {
        bgColor1 = _darken(base, 0.10);
        bgColor2 = _darken(
          generator.darkVibrantColor?.color ??
              generator.darkMutedColor?.color ??
              base,
          0.05,
        );
        notifyListeners();
      }
    } catch (e) {
      print('ThemeProvider error: $e');
      // Keep previous colors on error — no crash
    } finally {
      _processing = false;
    }
  }

  Color _darken(Color color, double lightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(lightness.clamp(0.05, 0.22))
        .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
        .toColor();
  }

  void reset() {
    bgColor1 = const Color(0xFF0D0820);
    bgColor2 = const Color(0xFF000000);
    _lastUrl = null;
    notifyListeners();
  }
}
