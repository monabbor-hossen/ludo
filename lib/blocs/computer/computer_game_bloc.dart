import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/game_model.dart';
import '../../logic/game_engine.dart';
import '../game/game_event.dart';
import '../game/game_state.dart';

class ComputerGameBloc extends Bloc<GameEvent, GameState> {
  final GameEngine _engine = GameEngine();
  final String humanId = "HUMAN_PLAYER";
  final String botId = "COMPUTER_BOT";

  // --- CONSTRUCTOR ---
  ComputerGameBloc() : super(GameInitial()) {
    on<StartComputerGame>(_onStartComputerGame);
    on<RollDice>(_onRollDice);
    on<MoveToken>(_onMoveToken);
  }

  // 1. Start Game Handler
  void _onStartComputerGame(StartComputerGame event, Emitter<GameState> emit) {
    String userColor = event.userColor;
    String botColor;

    // Determine Bot Color (Opposite)
    switch (userColor) {
      case 'Red': botColor = 'Yellow'; break;
      case 'Green': botColor = 'Blue'; break;
      case 'Yellow': botColor = 'Red'; break;
      case 'Blue': botColor = 'Green'; break;
      default: botColor = 'Yellow';
    }

    // Initialize Tokens
    Map<String, List<int>> tokens = {
      'Red': [0, 0, 0, 0],
      'Green': [0, 0, 0, 0],
      'Yellow': [0, 0, 0, 0],
      'Blue': [0, 0, 0, 0],
    };

    // Create Players
    List<Map<String, dynamic>> players = [
      {'id': humanId, 'name': 'You', 'color': userColor, 'type': 'human'},
      {'id': botId, 'name': 'Computer', 'color': botColor, 'type': 'bot'},
    ];

    final game = GameModel(
      gameId: "OFFLINE",
      status: "playing",
      currentTurn: 0,
      diceValue: 0,
      diceRolledBy: "",
      tokens: tokens,
      players: players,
    );

    emit(GameLoaded(game));
  }

  // 2. Roll Dice Handler
  Future<void> _onRollDice(RollDice event, Emitter<GameState> emit) async {
    if (state is! GameLoaded) return;
    final currentState = state as GameLoaded;
    var game = currentState.gameModel;

    // Generate Roll
    int roll = Random().nextInt(6) + 1;

    // Update Dice Value
    game = game.copyWith(
      diceValue: roll,
      diceRolledBy: game.players[game.currentTurn]['id'],
    );
    emit(GameLoaded(game));

    // Check if move is possible
    String color = game.players[game.currentTurn]['color'];

    // --- CALLING THE HELPER METHOD HERE ---
    bool canMove = _canAnyTokenMove(game.tokens[color]!, roll, color);

    if (!canMove) {
      // No move possible -> Skip Turn after delay
      await Future.delayed(const Duration(seconds: 1));
      add(MoveToken(gameId: "OFFLINE", userId: "AUTO", tokenIndex: -1));
    } else if (game.players[game.currentTurn]['type'] == 'bot') {
      // BOT LOGIC: Wait, then move
      await Future.delayed(const Duration(milliseconds: 1500));
      int bestTokenIndex = _findBestBotMove(game, roll);
      add(MoveToken(gameId: "OFFLINE", userId: botId, tokenIndex: bestTokenIndex));
    }
  }

  // 3. Move Token Handler
  Future<void> _onMoveToken(MoveToken event, Emitter<GameState> emit) async {
    if (state is! GameLoaded) return;
    final currentState = state as GameLoaded;
    var game = currentState.gameModel;

    int nextTurn = game.currentTurn;

    // A. Handle "Skip Turn" (Index -1)
    if (event.tokenIndex == -1) {
      nextTurn = (game.currentTurn + 1) % game.players.length;
      game = game.copyWith(diceValue: 0, currentTurn: nextTurn);
      emit(GameLoaded(game));
      _checkBotTurn(game);
      return;
    }

    // B. Handle Normal Move
    String color = game.players[game.currentTurn]['color'];
    List<int> tokens = List.from(game.tokens[color]!);
    int currentPos = tokens[event.tokenIndex];
    int newPos = _engine.calculateNextPosition(currentPos, game.diceValue, color);

    if (newPos == currentPos) return;

    // Apply Move
    tokens[event.tokenIndex] = newPos;
    Map<String, List<int>> allTokens = Map.from(game.tokens);
    allTokens[color] = tokens;

    // Check Kills
    allTokens = _engine.checkKill(allTokens, color, newPos);

    // Determine Turn (Extra turn on 6)
    if (game.diceValue != 6) {
      nextTurn = (game.currentTurn + 1) % game.players.length;
    }

    // Update State
    game = game.copyWith(
      tokens: allTokens,
      diceValue: 0,
      currentTurn: nextTurn,
    );

    emit(GameLoaded(game));

    // If next player is Bot, trigger roll
    _checkBotTurn(game);
  }

  void _checkBotTurn(GameModel game) {
    if (game.players[game.currentTurn]['type'] == 'bot') {
      Future.delayed(const Duration(seconds: 1), () {
        add(RollDice("OFFLINE"));
      });
    }
  }

  // --- HELPER METHODS (Must be inside the Class) ---

  bool _canAnyTokenMove(List<int> tokens, int dice, String color) {
    for (int pos in tokens) {
      if (_engine.calculateNextPosition(pos, dice, color) != pos) return true;
    }
    return false;
  }

  int _findBestBotMove(GameModel game, int dice) {
    String color = game.players[game.currentTurn]['color'];
    List<int> tokens = game.tokens[color]!;

    // Priority 1: Move out of Home
    for (int i = 0; i < 4; i++) {
      if (tokens[i] == 0 && dice == 6) return i;
    }

    // Priority 2: Random Valid Move (Simplified)
    for(int i=0; i<4; i++) {
      if (_engine.calculateNextPosition(tokens[i], dice, color) != tokens[i]) return i;
    }

    return 0; // Fallback
  }
}