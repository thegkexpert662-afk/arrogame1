import 'package:flutter/services.dart';

/// Lightweight gameplay feedback without adding another package.
/// Sound is represented by system UI feedback; a real audio asset layer can
/// be plugged in later without changing the game screen API.
class GameplayFeedbackService {
  GameplayFeedbackService._();
  static final instance = GameplayFeedbackService._();

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  Future<void> wrongMove() async {
    if (soundEnabled) await SystemSound.play(SystemSoundType.alert);
    if (vibrationEnabled) await HapticFeedback.heavyImpact();
  }

  Future<void> correctMove() async {
    if (soundEnabled) await SystemSound.play(SystemSoundType.click);
    if (vibrationEnabled) await HapticFeedback.selectionClick();
  }

  Future<void> win() async {
    if (soundEnabled) await SystemSound.play(SystemSoundType.click);
    if (vibrationEnabled) {
      await HapticFeedback.mediumImpact();
    }
  }
}
