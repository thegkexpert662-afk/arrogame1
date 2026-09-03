import 'package:flutter/material.dart';

import 'screens/level_selection_screen.dart';

void main() {
  runApp(const ArrowGameApp());
}

class ArrowGameApp extends StatelessWidget {
  const ArrowGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arrow Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LevelSelectionScreen(),
    );
  }
}
