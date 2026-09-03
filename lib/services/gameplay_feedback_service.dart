import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Centralized gameplay audio + haptic feedback.
/// Audio files are loaded from assets/sounds/.
class GameplayFeedbackService {
  GameplayFeedbackService._();
  static final instance = GameplayFeedbackService._();

  final AudioPlayer _player = AudioPlayer();

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  int lives = 3;

  void resetLives() => lives = 3;

  Future<void> _play(String file) async {
    if (!soundEnabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {
      // Keep gameplay working even if an optional sound asset is unavailable.
    }
  }

  Future<void> wrongMove() async {
    if (lives > 0) lives--;

    await _play('heart_break.wav');

    if (vibrationEnabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 45));
      await HapticFeedback.mediumImpact();
    }
  }

  /// Plays when an arrow is successfully cleared.
  Future<void> clearArrow() async {
    await _play('swipe.wav');
    if (vibrationEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> correctMove() => clearArrow();

  /// Plays the level-complete sound and a stronger success vibration.
  Future<void> win() async {
    await _play('level_complete.wav');
    if (vibrationEnabled) {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 70));
      await HapticFeedback.selectionClick();
    }
  }

  /// Optional UI click feedback for buttons such as hint/pause/restart.
  Future<void> click() async {
    await _play('click.wav');
    if (vibrationEnabled) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> dispose() => _player.dispose();
}
