import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ThemeProvider extends ChangeNotifier {
  Color bgColor1 = const Color(0xFF1A0A2E);
  Color bgColor2 = const Color(0xFF0A0818);
  Color bgColor3 = const Color(0xFF000000);
  String? _lastUrl;
  bool _busy = false;

  LinearGradient get bg => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgColor1, bgColor2, bgColor3],
        stops: const [0.0, 0.5, 1.0],
      );

  Future<void> updateFromUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    if (url == _lastUrl) return;
    if (_busy) return;
    _busy = true;
    _lastUrl = url;
    try {
      final resp =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return;
      final colors = await _extract(resp.bodyBytes);
      if (colors.isEmpty) return;
      final t1 = _vivid(colors[0], 0.22);
      final t2 =
          colors.length > 1 ? _vivid(colors[1], 0.15) : _vivid(colors[0], 0.11);
      final t3 = colors.length > 2
          ? _vivid(colors[2], 0.08)
          : Color.lerp(t1, Colors.black, 0.7)!;
      bgColor1 = Color.lerp(bgColor1, t1, 0.8)!;
      bgColor2 = Color.lerp(bgColor2, t2, 0.8)!;
      bgColor3 = Color.lerp(bgColor3, t3, 0.8)!;
      notifyListeners();
    } catch (e) {
      debugPrint('Theme: $e');
    } finally {
      _busy = false;
    }
  }

  Color _vivid(Color c, double lightness) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(lightness.clamp(0.10, 0.30))
        .withSaturation((hsl.saturation * 1.8).clamp(0.5, 1.0))
        .toColor();
  }

  Future<List<Color>> _extract(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 50, targetHeight: 50);
      final frame = await codec.getNextFrame();
      final data =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) return [];
      final px = data.buffer.asUint8List();
      final Map<String, int> buckets = {};
      for (int i = 0; i < px.length; i += 4) {
        final r = px[i];
        final g = px[i + 1];
        final b = px[i + 2];
        final bright = r * 0.299 + g * 0.587 + b * 0.114;
        if (bright < 20 || bright > 230) continue;
        if (_sat(r, g, b) < 0.12) continue;
        final key = '${(r ~/ 30) * 30},${(g ~/ 30) * 30},${(b ~/ 30) * 30}';
        buckets[key] = (buckets[key] ?? 0) + 1;
      }
      if (buckets.isEmpty) return [];
      final sorted = buckets.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final List<Color> out = [];
      for (final e in sorted.take(50)) {
        final pts = e.key.split(',');
        final c = Color.fromRGBO(
            int.parse(pts[0]), int.parse(pts[1]), int.parse(pts[2]), 1);
        if (out.isEmpty) {
          out.add(c);
        } else if (out.every((x) => _diff(c, x) > 50)) {
          out.add(c);
        }
        if (out.length >= 3) break;
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  double _sat(int r, int g, int b) {
    final mx = [r, g, b].reduce(max) / 255.0;
    final mn = [r, g, b].reduce(min) / 255.0;
    return mx == 0 ? 0 : (mx - mn) / mx;
  }

  double _diff(Color a, Color b) =>
      (a.red - b.red).abs() +
      (a.green - b.green).abs() +
      (a.blue - b.blue).abs() +
      0.0;

  void reset() {
    bgColor1 = const Color(0xFF1A0A2E);
    bgColor2 = const Color(0xFF0A0818);
    bgColor3 = const Color(0xFF000000);
    _lastUrl = null;
    notifyListeners();
  }
}
