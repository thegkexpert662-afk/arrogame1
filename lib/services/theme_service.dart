import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ArrowStyle { classic, bold, minimal, doubleLine }

enum GameBackground { clean, grid, night, soft }

class ThemeService {
  ThemeService._();
  static final instance = ThemeService._();
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<ThemeMode> themeMode() async {
    final value = await _prefs.getString('theme_mode') ?? 'light';
    return value == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode mode) async =>
      _prefs.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');

  Future<ArrowStyle> arrowStyle() async =>
      ArrowStyle.values[await _prefs.getInt('arrow_style') ?? 0];
  Future<void> setArrowStyle(ArrowStyle style) async =>
      _prefs.setInt('arrow_style', style.index);

  Future<GameBackground> background() async =>
      GameBackground.values[await _prefs.getInt('game_background') ?? 0];
  Future<void> setBackground(GameBackground background) async =>
      _prefs.setInt('game_background', background.index);

  Future<bool> isArrowStyleUnlocked(ArrowStyle style, int playerLevel) async =>
      style.index == 0 || playerLevel >= (style.index + 1) * 3;
  Future<bool> isBackgroundUnlocked(
    GameBackground background,
    int playerLevel,
  ) async => background.index == 0 || playerLevel >= (background.index + 1) * 5;
}
