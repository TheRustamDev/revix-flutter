import 'package:flutter/material.dart';
import '../models/settings_models.dart';
import '../repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  late PlaybackSettings _playback;
  late NotificationSettings _notifications;
  late DownloadSettings _downloads;
  late AppearanceSettings _appearance;

  SettingsProvider(this._repository) {
    _loadSettings();
  }

  void _loadSettings() {
    _playback = _repository.getPlaybackSettings();
    _notifications = _repository.getNotificationSettings();
    _downloads = _repository.getDownloadSettings();
    _appearance = _repository.getAppearanceSettings();
  }

  // Getters
  PlaybackSettings get playback => _playback;
  NotificationSettings get notifications => _notifications;
  DownloadSettings get downloads => _downloads;
  AppearanceSettings get appearance => _appearance;

  // Shortcuts for commonly used settings
  String get audioQuality => _playback.audioQuality;
  bool get autoPlay => _playback.autoPlay;

  // Updates
  Future<void> updatePlayback(
      PlaybackSettings Function(PlaybackSettings) update) async {
    _playback = update(_playback);
    await _repository.savePlaybackSettings(_playback);
    notifyListeners();
  }

  Future<void> updateNotifications(
      NotificationSettings Function(NotificationSettings) update) async {
    _notifications = update(_notifications);
    await _repository.saveNotificationSettings(_notifications);
    notifyListeners();
  }

  Future<void> updateDownloads(
      DownloadSettings Function(DownloadSettings) update) async {
    _downloads = update(_downloads);
    await _repository.saveDownloadSettings(_downloads);
    notifyListeners();
  }

  Future<void> updateAppearance(
      AppearanceSettings Function(AppearanceSettings) update) async {
    _appearance = update(_appearance);
    await _repository.saveAppearanceSettings(_appearance);
    notifyListeners();
  }

  // Specific helpers
  void setAudioQuality(String quality) {
    updatePlayback((s) => s.copyWith(audioQuality: quality));
  }

  void setAutoPlay(bool value) {
    updatePlayback((s) => s.copyWith(autoPlay: value));
  }

  void setDownloadQuality(String quality) {
    updateDownloads((s) => s.copyWith(quality: quality));
  }

  void setDownloadOverWifiOnly(bool value) {
    updateDownloads((s) => s.copyWith(downloadOverWifiOnly: value));
  }

  // Appearance Helpers
  void setAmoledMode(bool value) {
    updateAppearance((s) => s.copyWith(amoledMode: value));
  }

  void setAccentColor(int colorValue) {
    updateAppearance((s) => s.copyWith(accentColorValue: colorValue));
  }

  void setGlowIntensity(double value) {
    updateAppearance((s) => s.copyWith(glowIntensity: value));
  }

  void setAnimationSpeed(double value) {
    updateAppearance((s) => s.copyWith(animationSpeed: value));
  }

  void setReducedMotion(bool value) {
    updateAppearance((s) => s.copyWith(reducedMotion: value));
  }

  void setVisualizerStyle(String style) {
    updateAppearance((s) => s.copyWith(visualizerStyle: style));
  }

  void setBlurIntensity(double value) {
    updateAppearance((s) => s.copyWith(blurIntensity: value));
  }
}
