import 'package:flutter/material.dart';
import 'screens/app_screens.dart';
import 'screens/game_screen.dart';

void main() => runApp(const ArroPuzzalApp());

class ArroPuzzalApp extends StatelessWidget {
  const ArroPuzzalApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Arro Puzzal',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFFFF8E8), colorSchemeSeed: const Color(0xFF8A552A)),
    initialRoute: '/',
    routes: {
      '/': (_) => const SplashScreen(), '/intro': (_) => const IntroScreen(), '/home': (_) => const HomeScreen(),
      '/difficulty': (_) => const DifficultyScreen(), '/levels': (_) => const LevelSelectScreen(), '/game': (_) => const GameScreen(),
      '/result': (_) => const ResultScreen(), '/settings': (_) => const SettingsScreen(), '/daily': (_) => const DailyScreen(), '/how': (_) => const HowToPlayScreen(),
    },
  );
}
