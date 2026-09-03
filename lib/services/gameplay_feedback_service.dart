import 'package:flutter/services.dart';

/// Lightweight gameplay feedback using Android/iOS system feedback.
/// Keeps gameplay offline and avoids adding a network-dependent audio layer.
class GameplayFeedbackService {
  GameplayFeedbackService._();
  static final instance = GameplayFeedbackService._();

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  Future<void> wrongMove() async {
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (vibrationEnabled) {
      await HapticFeedback.heavyImpact();
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
