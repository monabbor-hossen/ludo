import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../models/game_model.dart';
import '../widgets/board_layout.dart';
import '../widgets/dice_widget.dart';

class GameBoard extends StatefulWidget {
  final String gameId;
  final String userId;

  const GameBoard({super.key, required this.gameId, required this.userId});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // Keep track of IDs we have already shown the "Left" message for
  final Set<String> _notifiedLeftPlayers = {};

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded) {
          final players = state.gameModel.players;

          // 1. CHECK FOR NEW LEAVERS (Show SnackBar)
          for (var p in players) {
            bool hasLeft = p['hasLeft'] ?? false;
            String pid = p['id'];

            // If they left, and we haven't shown the message yet...
            if (hasLeft && !_notifiedLeftPlayers.contains(pid)) {
              _notifiedLeftPlayers.add(pid); // Mark as notified

              String name = p['name'] ?? p['color'];

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name left the game!"),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }

          // 2. CHECK GAME OVER
          // Count active players (those who have NOT left)
          int activePlayers = players.where((p) => p['hasLeft'] != true).length;

          // Only show Game Over if the game had started (length > 1) AND now only 1 remains
          if (players.length > 1 && activePlayers < 2) {
            _showGameOverDialog();
          }
        }
      },
      builder: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;

          // Get current player data
          final currentPlayer = game.players[game.currentTurn];
          final String turnColor = currentPlayer['color'];
          final String turnName = currentPlayer['name'] ?? turnColor;

          return Scaffold(
            appBar: AppBar(
              title: const Text("Ludo"),
              automaticallyImplyLeading: false,
              actions: [
                // EXIT BUTTON
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  tooltip: "Leave Game",
                  onPressed: () => _showLeaveConfirmDialog(game),
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
                            text: "$turnName's",
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
                      currentUserId: widget.userId, // Use 'widget.userId' in State class
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
                          Chip(label: Text(_getMyColor(game, widget.userId))),
                        ],
                      ),

                      // The Dice
                      DiceWidget(myPlayerId: widget.userId),
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

  // --- HELPER METHODS (Defined inside the State class) ---

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

  void _showLeaveConfirmDialog(GameModel game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Game?"),
        content: const Text("You will be removed from the game."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Trigger Leave Event
              context.read<GameBloc>().add(LeaveGameEvent(widget.gameId, widget.userId));
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Go back to Home
            },
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    // Prevent multiple dialogs
    if (ModalRoute.of(context)?.isCurrent != true) return;

    showDialog(
      barrierDismissible: false,
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