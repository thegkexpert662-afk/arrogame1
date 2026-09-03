import 'package:flutter/material.dart';

import 'screens/level_selection_screen.dart';

void main() {
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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark), useMaterial3: true, brightness: Brightness.dark),
      home: LevelSelectionScreen(onThemeChanged: (mode) => setState(() => _mode = mode)),
    );
  }
}
