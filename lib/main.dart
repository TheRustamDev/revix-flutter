import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'services/music_service.dart';
import 'providers/player_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  final musicHandler = await initMusicService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider(musicHandler)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const RevixApp(),
    ),
  );
}

class RevixApp extends StatelessWidget {
  const RevixApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'REVIX One',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFFEC4899),
          tertiary: Color(0xFF0EA5E9),
          surface: Color(0xFF1A1A2E),
        ),
      ),
      home: const MainWrapper(),
    );
  }
}
