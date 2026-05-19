import 'package:flutter/material.dart';

class PlaybackSettings {
  final String audioQuality;
  final bool autoPlay;
  final bool volumeNormalization;
  final double crossfade;

  PlaybackSettings({
    this.audioQuality = 'Normal',
    this.autoPlay = true,
    this.volumeNormalization = false,
    this.crossfade = 0.0,
  });

  PlaybackSettings copyWith({
    String? audioQuality,
    bool? autoPlay,
    bool? volumeNormalization,
    double? crossfade,
  }) {
    return PlaybackSettings(
      audioQuality: audioQuality ?? this.audioQuality,
      autoPlay: autoPlay ?? this.autoPlay,
      volumeNormalization: volumeNormalization ?? this.volumeNormalization,
      crossfade: crossfade ?? this.crossfade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'audioQuality': audioQuality,
      'autoPlay': autoPlay,
      'volumeNormalization': volumeNormalization,
      'crossfade': crossfade,
    };
  }

  factory PlaybackSettings.fromMap(Map<dynamic, dynamic> map) {
    return PlaybackSettings(
      audioQuality: map['audioQuality'] ?? 'Normal',
      autoPlay: map['autoPlay'] ?? true,
      volumeNormalization: map['volumeNormalization'] ?? false,
      crossfade: (map['crossfade'] ?? 0.0).toDouble(),
    );
  }
}

class NotificationSettings {
  final bool enabled;
  final bool showProgress;

  NotificationSettings({
    this.enabled = true,
    this.showProgress = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? showProgress,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      showProgress: showProgress ?? this.showProgress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'showProgress': showProgress,
    };
  }

  factory NotificationSettings.fromMap(Map<dynamic, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] ?? true,
      showProgress: map['showProgress'] ?? true,
    );
  }
}

class DownloadSettings {
  final String quality;
  final bool downloadOverWifiOnly;

  DownloadSettings({
    this.quality = 'High',
    this.downloadOverWifiOnly = false,
  });

  DownloadSettings copyWith({
    String? quality,
    bool? downloadOverWifiOnly,
  }) {
    return DownloadSettings(
      quality: quality ?? this.quality,
      downloadOverWifiOnly: downloadOverWifiOnly ?? this.downloadOverWifiOnly,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'downloadOverWifiOnly': downloadOverWifiOnly,
    };
  }

  factory DownloadSettings.fromMap(Map<dynamic, dynamic> map) {
    return DownloadSettings(
      quality: map['quality'] ?? 'High',
      downloadOverWifiOnly: map['downloadOverWifiOnly'] ?? false,
    );
  }
}

class AppearanceSettings {
  final bool useDynamicColors;
  final int accentColorValue;
  final bool amoledMode;
  final double glowIntensity;
  final double animationSpeed;
  final bool reducedMotion;
  final String visualizerStyle;
  final double blurIntensity;

  AppearanceSettings({
    this.useDynamicColors = true,
    this.accentColorValue = 0xFF8B5CF6,
    this.amoledMode = false,
    this.glowIntensity = 0.5,
    this.animationSpeed = 1.0,
    this.reducedMotion = false,
    this.visualizerStyle = 'Waveform',
    this.blurIntensity = 20.0,
  });

  Color get accentColor => Color(accentColorValue);

  AppearanceSettings copyWith({
    bool? useDynamicColors,
    int? accentColorValue,
    bool? amoledMode,
    double? glowIntensity,
    double? animationSpeed,
    bool? reducedMotion,
    String? visualizerStyle,
    double? blurIntensity,
  }) {
    return AppearanceSettings(
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      amoledMode: amoledMode ?? this.amoledMode,
      glowIntensity: glowIntensity ?? this.glowIntensity,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      visualizerStyle: visualizerStyle ?? this.visualizerStyle,
      blurIntensity: blurIntensity ?? this.blurIntensity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'useDynamicColors': useDynamicColors,
      'accentColorValue': accentColorValue,
      'amoledMode': amoledMode,
      'glowIntensity': glowIntensity,
      'animationSpeed': animationSpeed,
      'reducedMotion': reducedMotion,
      'visualizerStyle': visualizerStyle,
      'blurIntensity': blurIntensity,
    };
  }

  factory AppearanceSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppearanceSettings(
      useDynamicColors: map['useDynamicColors'] ?? true,
      accentColorValue: map['accentColorValue'] ?? 0xFF8B5CF6,
      amoledMode: map['amoledMode'] ?? false,
      glowIntensity: (map['glowIntensity'] ?? 0.5).toDouble(),
      animationSpeed: (map['animationSpeed'] ?? 1.0).toDouble(),
      reducedMotion: map['reducedMotion'] ?? false,
      visualizerStyle: map['visualizerStyle'] ?? 'Waveform',
      blurIntensity: (map['blurIntensity'] ?? 20.0).toDouble(),
    );
  }
}
