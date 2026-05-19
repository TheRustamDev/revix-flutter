import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'repositories/settings_repository.dart';
import 'providers/settings_provider.dart';
import 'services/music_service.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  // Init Settings
  final settingsRepo = SettingsRepository();
  await settingsRepo.init();

  // Migration if needed
  final oldSettingsBox = await Hive.openBox('settings');
  await settingsRepo.migrateOldSettings(oldSettingsBox);

  final musicHandler = await initMusicService();
  runApp(
    MultiProvider(
      providers: [
        Provider<SettingsRepository>.value(value: settingsRepo),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProxyProvider2<SettingsProvider, ThemeProvider,
            PlayerProvider>(
          create: (_) => PlayerProvider(musicHandler),
          update: (_, settings, theme, player) {
            player!.attachSettings(settings);
            player.attachTheme(theme);
            theme.setAmoled(settings.appearance.amoledMode);
            return player;
          },
        ),
      ],
      child: const RevixApp(),
    ),
  );
}

class RevixApp extends StatelessWidget {
  const RevixApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final app = settings.appearance;
        final accent = app.accentColor;

        return MaterialApp(
          title: 'REVIX One',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: ColorScheme.dark(
              primary: accent,
              secondary: const Color(0xFFEC4899),
              tertiary: const Color(0xFF0EA5E9),
              surface: app.amoledMode ? Colors.black : const Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
            sliderTheme: SliderThemeData(
              activeTrackColor: accent,
              thumbColor: Colors.white,
            ),
          ),
          home: const MainWrapper(),
        );
      },
    );
  }
}
