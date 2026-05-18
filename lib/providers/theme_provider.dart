import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:typed_data';

class ThemeProvider extends ChangeNotifier {
  Color bgColor1 = const Color(0xFF0D0820);
  Color bgColor2 = const Color(0xFF000000);
  Color accentColor = const Color(0xFF8B5CF6);
  String? _lastUrl;
  bool _processing = false;

  LinearGradient get bg => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomCenter,
        colors: [
          bgColor1,
          Color.lerp(bgColor1, Colors.black, 0.5)!,
          Colors.black,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

  Future<void> updateFromUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    if (url == _lastUrl) return;
    if (_processing) return;
    _processing = true;
    _lastUrl = url;

    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return;

      final bytes = response.bodyBytes;
      final colors = await _sampleColors(bytes);

      if (colors.isNotEmpty) {
        bgColor1 = _darken(colors[0], 0.12);
        bgColor2 = colors.length > 1
            ? _darken(colors[1], 0.06)
            : _darken(colors[0], 0.18);
        accentColor = colors[0];
        notifyListeners();
      }
    } catch (e) {
      print('ThemeProvider error: $e');
    } finally {
      _processing = false;
    }
  }

  Future<List<Color>> _sampleColors(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 64, targetHeight: 64);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return [];

      final pixels = byteData.buffer.asUint8List();
      final Map<String, int> buckets = {};

      for (int i = 0; i < pixels.length; i += 8) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];

        // Skip near-black, near-white, near-grey
        final brightness = (r * 0.299 + g * 0.587 + b * 0.114);
        if (brightness < 30 || brightness > 220) continue;
        final saturation = _saturation(r, g, b);
        if (saturation < 0.15) continue; // skip grey/desaturated

        // Quantize into buckets
        final qr = (r ~/ 40) * 40;
        final qg = (g ~/ 40) * 40;
        final qb = (b ~/ 40) * 40;
        final key = '$qr,$qg,$qb';
        buckets[key] = (buckets[key] ?? 0) + 1;
      }

      if (buckets.isEmpty) return [const Color(0xFF8B5CF6)];

      final sorted = buckets.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final List<Color> result = [];
      for (final entry in sorted.take(20)) {
        final parts = entry.key.split(',');
        final r = int.parse(parts[0]);
        final g = int.parse(parts[1]);
        final b = int.parse(parts[2]);
        final color = Color.fromRGBO(r, g, b, 1.0);

        if (result.isEmpty) {
          result.add(color);
        } else {
          // Only add if sufficiently different
          bool distinct = true;
          for (final existing in result) {
            if (_colorDiff(color, existing) < 80) {
              distinct = false;
              break;
            }
          }
          if (distinct) result.add(color);
          if (result.length >= 2) break;
        }
      }
      return result;
    } catch (e) {
      print('Color sample error: $e');
      return [];
    }
  }

  double _saturation(int r, int g, int b) {
    final max = [r, g, b].reduce((a, b) => a > b ? a : b) / 255.0;
    final min = [r, g, b].reduce((a, b) => a < b ? a : b) / 255.0;
    if (max == 0) return 0;
    return (max - min) / max;
  }

  double _colorDiff(Color a, Color b) =>
      (a.red - b.red).abs() +
      (a.green - b.green).abs() +
      (a.blue - b.blue).abs() +
      0.0;

  Color _darken(Color color, double lightness) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness(lightness.clamp(0.06, 0.20))
        .withSaturation((hsl.saturation * 1.3).clamp(0.0, 1.0))
        .toColor();
  }

  void reset() {
    bgColor1 = const Color(0xFF0D0820);
    bgColor2 = const Color(0xFF000000);
    accentColor = const Color(0xFF8B5CF6);
    _lastUrl = null;
    notifyListeners();
  }
}
