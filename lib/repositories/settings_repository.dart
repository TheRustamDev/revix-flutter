import 'package:hive_flutter/hive_flutter.dart';
import '../models/settings_models.dart';

class SettingsRepository {
  static const String _boxName = 'settings_v2';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> _put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  // Playback
  PlaybackSettings getPlaybackSettings() {
    final map = _box.get('playback', defaultValue: {});
    return PlaybackSettings.fromMap(Map<dynamic, dynamic>.from(map));
  }

  Future<void> savePlaybackSettings(PlaybackSettings settings) async {
    await _put('playback', settings.toMap());
  }

  // Notification
  NotificationSettings getNotificationSettings() {
    final map = _box.get('notifications', defaultValue: {});
    return NotificationSettings.fromMap(Map<dynamic, dynamic>.from(map));
  }

  Future<void> saveNotificationSettings(NotificationSettings settings) async {
    await _put('notifications', settings.toMap());
  }

  // Download
  DownloadSettings getDownloadSettings() {
    final map = _box.get('downloads', defaultValue: {});
    return DownloadSettings.fromMap(Map<dynamic, dynamic>.from(map));
  }

  Future<void> saveDownloadSettings(DownloadSettings settings) async {
    await _put('downloads', settings.toMap());
  }

  // Appearance
  AppearanceSettings getAppearanceSettings() {
    final map = _box.get('appearance', defaultValue: {});
    return AppearanceSettings.fromMap(Map<dynamic, dynamic>.from(map));
  }

  Future<void> saveAppearanceSettings(AppearanceSettings settings) async {
    await _put('appearance', settings.toMap());
  }

  // Batch migration from old settings box if needed
  Future<void> migrateOldSettings(Box oldBox) async {
    if (_box.isEmpty && oldBox.isNotEmpty) {
      final audioQuality = oldBox.get('audioQuality');
      final autoPlay = oldBox.get('autoPlay');

      if (audioQuality != null || autoPlay != null) {
        final currentPlayback = getPlaybackSettings();
        await savePlaybackSettings(currentPlayback.copyWith(
          audioQuality: audioQuality as String?,
          autoPlay: autoPlay as bool?,
        ));
      }
    }
  }
}
