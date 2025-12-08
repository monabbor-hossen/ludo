import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

class AudioService {
  // Player 1: For Moving, Killing, Winning
  static final AudioPlayer _sfxPlayer = AudioPlayer();

  // Player 2: DEDICATED for Dice (So it never waits for other sounds)
  static final AudioPlayer _dicePlayer = AudioPlayer();

  static const String _rollFile = 'audio/dice_roll.mp3';
  static const String _moveFile = 'audio/piece_move.mp3';
  static const String _killFile = 'audio/kill.mp3';
  static const String _winFile = 'audio/win.mp3';

  // --- 1. GENERIC SOUNDS (Move, Kill, Win) ---
  static Future<void> _playSfx(String file) async {
    try {
      // Only stop if it's the long win sound, otherwise Fire-and-Forget
      if (file == _winFile) {
        await _sfxPlayer.stop();
      }

      Source source = kIsWeb ? UrlSource('./assets/$file') : AssetSource(file);

      await _sfxPlayer.setVolume(1.0);
      await _sfxPlayer.play(source);
    } catch (e) {
      debugPrint("🔴 SFX Error: $e");
    }
  }

  // --- 2. DICE SOUND (Dedicated Logic) ---
  static Future<void> playRoll() async {
    try {
      // Stop any previous roll (if you spam click)
      await _dicePlayer.stop();

      Source source = kIsWeb ? UrlSource('./assets/$_rollFile') : AssetSource(_rollFile);

      await _dicePlayer.setVolume(1.0);
      await _dicePlayer.play(source);
    } catch (e) {
      debugPrint("🔴 Dice Audio Error: $e");
    }
  }

  // --- Public Methods ---
  static Future<void> playMove() async => await _playSfx(_moveFile);
  static Future<void> playKill() async => await _playSfx(_killFile);
  static Future<void> playWin() async => await _playSfx(_winFile);
}