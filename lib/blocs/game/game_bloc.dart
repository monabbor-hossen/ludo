import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'game_event.dart';
import 'game_state.dart';
import '../../services/firebase_service.dart';
import '../../services/audio_service.dart';
import '../../models/game_model.dart';
import '../../logic/game_engine.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final FirebaseService _firebaseService;
  final AudioService _audioService;
  final GameEngine _gameEngine = GameEngine();

  GameBloc(this._firebaseService, this._audioService) : super(GameInitial()) {

    // 1. Listen to Stream
    on<LoadGame>((event, emit) async {
      await emit.forEach(
        _firebaseService.streamGame(event.gameId),
        onData: (GameModel game) => GameLoaded(game),
        onError: (_, __) => const GameError(),
      );
    });

    // 2. Start Game
    on<StartGame>((event, emit) async {
      await _firebaseService.updateGameState(event.gameId, {'status': 'playing'});
    });

    // 3. Leave Game
    on<LeaveGameEvent>((event, emit) async {
      await _firebaseService.leaveGame(event.gameId, event.userId);
    });

    // 4. Roll Dice
    on<RollDice>((event, emit) async {
      _audioService.playRoll();

      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        int diceValue = Random().nextInt(6) + 1;

        await _firebaseService.updateGameState(event.gameId, {
          'diceValue': diceValue,
          'diceRolledBy': game.players[game.currentTurn]['id'],
        });

        // Check if move is possible
        String color = game.players[game.currentTurn]['color'];
        List<int> myTokens = game.tokens[color]!;
        bool canMove = false;

        for (int pos in myTokens) {
          int nextPos = _gameEngine.calculateNextPosition(pos, diceValue, color);
          if (nextPos != pos) {
            canMove = true;
            break;
          }
        }

        // IF NO MOVE POSSIBLE -> Auto Switch Turn
        if (!canMove) {
          await Future.delayed(const Duration(seconds: 1));

          // --- FIX 1: Use helper to skip players who left ---
          int nextTurn = _getNextValidTurn(game, game.currentTurn);

          await _firebaseService.updateGameState(event.gameId, {
            'currentTurn': nextTurn,
            'diceValue': 0,
          });
        }
      }
    });

    // 5. Move Token
    on<MoveToken>((event, emit) async {
      final currentState = state;
      if (currentState is GameLoaded) {
        final game = currentState.gameModel;

        if (game.players[game.currentTurn]['id'] != event.userId) return;
        if (game.diceValue == 0) return;

        String color = game.players[game.currentTurn]['color'];
        List<int> tokens = List.from(game.tokens[color]!);
        int currentPos = tokens[event.tokenIndex];

        // Logic
        int newPos = _gameEngine.calculateNextPosition(currentPos, game.diceValue, color);
        if (newPos == currentPos) return;

        tokens[event.tokenIndex] = newPos;
        Map<String, List<int>> allTokens = Map.from(game.tokens);
        allTokens = allTokens.map((k, v) => MapEntry(k, List.from(v)));
        allTokens[color] = tokens;

        // Sound Logic
        int enemiesBefore = _countEnemiesOnBoard(allTokens, color);
        allTokens = _gameEngine.checkKill(allTokens, color, newPos);
        int enemiesAfter = _countEnemiesOnBoard(allTokens, color);

        if (enemiesAfter < enemiesBefore) {
          _audioService.playKill();
        } else if (newPos == 99) {
          _audioService.playWin();
        } else {
          _audioService.playMove();
        }

        // --- FIX 2: Use helper to skip players who left ---
        int nextTurn = game.currentTurn;
        if (game.diceValue != 6) {
          // If not a 6, find the NEXT VALID player
          nextTurn = _getNextValidTurn(game, game.currentTurn);
        }

        await _firebaseService.updateGameState(event.gameId, {
          'tokens': allTokens,
          'currentTurn': nextTurn,
          'diceValue': 0,
        });
      }
    });
  }

  // --- Helper Methods ---

  // 1. Calculate next turn, skipping players with 'hasLeft': true
  int _getNextValidTurn(GameModel game, int currentTurn) {
    int next = currentTurn;
    // Loop to find next person who hasn't left
    for (int i = 0; i < game.players.length; i++) {
      next = (next + 1) % game.players.length;

      bool hasLeft = game.players[next]['hasLeft'] ?? false;
      if (!hasLeft) return next;
    }
    return currentTurn; // Fallback if everyone left
  }

  int _countEnemiesOnBoard(Map<String, List<int>> tokens, String myColor) {
    int count = 0;
    tokens.forEach((key, positions) {
      if (key != myColor) {
        count += positions.where((pos) => pos > 0 && pos < 99).length;
      }
    });
    return count;
  }
}