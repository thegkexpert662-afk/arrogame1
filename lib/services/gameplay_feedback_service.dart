import 'package:flutter/services.dart';

/// Lightweight gameplay feedback using Android/iOS system feedback.
/// Keeps gameplay offline and avoids adding a network-dependent audio layer.
class GameplayFeedbackService {
  GameplayFeedbackService._();
  static final instance = GameplayFeedbackService._();

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  int lives = 3;

  void resetLives() => lives = 3;

  Future<void> wrongMove() async {
    // Every blocked tap costs one heart, but never below zero.
    if (lives > 0) lives--;

    if (soundEnabled) {
      // Two quick alert cues create a stronger "crack/break" feedback
      // without requiring an external audio asset.
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 55));
      await SystemSound.play(SystemSoundType.alert);
    }
    if (vibrationEnabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 45));
      await HapticFeedback.mediumImpact();
    }
  }

  /// Short click gives the cleared-arrow a quick "swipe/tap" response.
  Future<void> clearArrow() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (vibrationEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> correctMove() => clearArrow();

  Future<void> win() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
    if (vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }
}
