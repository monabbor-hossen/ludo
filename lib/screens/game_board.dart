import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart'; // Required for LeaveGameEvent
import '../blocs/game/game_state.dart';
import '../models/game_model.dart'; // Required for GameModel type
import '../widgets/board_layout.dart';
import '../widgets/dice_widget.dart';

class GameBoard extends StatelessWidget {
  final String gameId;
  final String userId;

  const GameBoard({super.key, required this.gameId, required this.userId});

  @override
  Widget build(BuildContext context) {
    // We use BlocConsumer to LISTEN (for game over) and BUILD (the UI)
    return BlocConsumer<GameBloc, GameState>(
      // 1. LISTENER: Handles logic when players leave
      listener: (context, state) {
        if (state is GameLoaded) {
          final players = state.gameModel.players;

          // Count active players
          int activePlayers = players.where((p) => p['hasLeft'] != true).length;

          // GAME OVER CONDITION:
          // Only if the game had started (length > 1) AND now only 1 person is left.
          if (players.length > 1 && activePlayers < 2) {
            _showGameOverDialog(context);
          }
          // If activePlayers is 2 or more, this block is SKIPPED, and game continues.
        }
      },
      // 2. BUILDER: Draws the UI
      builder: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;

          // Get current player data safely
          final currentPlayer = game.players[game.currentTurn];
          final String turnColor = currentPlayer['color'];
          // Fallback to Color name if specific name is missing
          final String turnName = currentPlayer['name'] ?? turnColor;

          return Scaffold(
            appBar: AppBar(
              title: const Text("Ludo"),
              automaticallyImplyLeading: false, // Prevent back button
              actions: [
                // 3. EXIT BUTTON
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  tooltip: "Leave Game",
                  onPressed: () => _showLeaveConfirmDialog(context, game),
                )
              ],
            ),
            backgroundColor: Colors.white,
            body: Column(
              children: [
                // Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  color: Colors.white,
                  width: double.infinity,
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 22, color: Colors.black),
                        children: [
                          const TextSpan(text: "Waiting for "),
                          TextSpan(
                            text: "$turnName's", // Name is shown here
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getColor(turnColor),
                              fontSize: 24,
                            ),
                          ),
                          const TextSpan(text: " move"),
                        ],
                      ),
                    ),
                  ),
                ),

                // Board
                Expanded(
                  child: Center(
                    child: BoardLayout(
                        gameModel: game,
                        currentUserId: userId
                    ),
                  ),
                ),

                // Controls Area
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(20),
                  color: Colors.grey[200],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Player Info
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("You are:"),
                          Chip(label: Text(_getMyColor(game, userId))),
                        ],
                      ),

                      // The Dice
                      DiceWidget(myPlayerId: userId),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  // --- HELPER METHODS ---

  String _getMyColor(GameModel game, String userId) {
    final me = game.players.firstWhere(
            (p) => p['id'] == userId,
        orElse: () => {'color': 'Spectator'}
    );
    return me['color'];
  }

  Color _getColor(String colorName) {
    if (colorName == 'Red') return Colors.red;
    if (colorName == 'Green') return Colors.green;
    if (colorName == 'Yellow') return Colors.amber;
    if (colorName == 'Blue') return Colors.blue;
    return Colors.black;
  }

  // --- DIALOGS ---

  void _showLeaveConfirmDialog(BuildContext context, GameModel game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Game?"),
        content: const Text("You will be removed from the game."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Cancel
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Trigger the Leave Event in BLoC
              context.read<GameBloc>().add(LeaveGameEvent(gameId, userId));
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Go back to Home Menu
            },
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context) {
    // Prevent multiple dialogs if one is already open
    if (ModalRoute.of(context)?.isCurrent != true) return;

    showDialog(
      barrierDismissible: false, // User must click OK
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Game Over"),
        content: const Text("Everyone else has left the game! You win!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst); // Go to Home
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}