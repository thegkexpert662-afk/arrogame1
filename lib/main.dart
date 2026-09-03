import 'package:flutter/material.dart';

import 'screens/level_selection_screen.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ads are optional. A slow/unavailable network must never prevent the game
  // from starting, so offline gameplay remains available.
  try {
    await AdService.instance.initialize().timeout(const Duration(seconds: 4));
  } catch (_) {
    // Ignore ad initialization failures; gameplay is fully local.
  }

  runApp(const ArrowGameApp());
}

class ArrowGameApp extends StatefulWidget {
  const ArrowGameApp({super.key});
  @override
  State<ArrowGameApp> createState() => _ArrowGameAppState();
}

class _ArrowGameAppState extends State<ArrowGameApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arrow Game',
      themeMode: _mode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: LevelSelectionScreen(
        onThemeChanged: (mode) => setState(() => _mode = mode),
      ),
    );
  }
}
