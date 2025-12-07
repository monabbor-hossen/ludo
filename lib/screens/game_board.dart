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

  // Prevent showing the win dialog multiple times
  bool _celebrationShown = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      // 1. LISTENER: Handles Left Players, Win, and Loss
      listener: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;
          final players = game.players;

          // A. Check for new leavers
          for (var p in players) {
            bool hasLeft = p['hasLeft'] ?? false;
            String pid = p['id'];

            if (hasLeft && !_notifiedLeftPlayers.contains(pid)) {
              _notifiedLeftPlayers.add(pid);
              String name = p['name'] ?? p['color'];
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name left the game!"),
                  backgroundColor: Colors.orange[800],
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }

          // B. CHECK WIN/RANKING STATUS
          // Only check if we haven't shown the dialog yet
          if (!_celebrationShown) {
            // 1. Did I win? (Am I in the winners list?)
            if (game.winners.contains(widget.userId)) {
              _celebrationShown = true;
              int rank = game.winners.indexOf(widget.userId) + 1; // 0 index = 1st place
              _showCelebrationDialog(rank, false);
            }

            // 2. Did I lose? (Game finished, and I am NOT in winners list)
            else if (game.status == 'finished') {
              _celebrationShown = true;
              _showCelebrationDialog(0, true); // Rank 0, isLoser = true
            }
          }

          // C. Check Game Over (Empty Room Scenario)
          // (Only triggers if players actually leave via menu, not just finishing game)
          int activePlayers = players.where((p) => p['hasLeft'] != true).length;
          if (players.length > 1 && activePlayers < 2 && game.status != 'finished') {
            _showGameOverDialog();
          }
        }
      },
      // 2. BUILDER
      builder: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;
          final currentPlayer = game.players[game.currentTurn];
          final String turnColor = currentPlayer['color'];
          final String turnName = currentPlayer['name'] ?? turnColor;

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/wood.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // A. APP BAR
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      decoration: _woodenBoxDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                              "Ludo",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3E2723))
                          ),
                          IconButton(
                            icon: const Icon(Icons.exit_to_app, color: Color(0xFF8D6E63), size: 30),
                            onPressed: () => _showLeaveConfirmDialog(game),
                          )
                        ],
                      ),
                    ),

                    // B. STATUS PLANK
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(10),
                      decoration: _woodenBoxDecoration(),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 18, color: Color(0xFF3E2723), fontFamily: 'Courier', fontWeight: FontWeight.bold),
                            children: [
                              const TextSpan(text: "Waiting for "),
                              TextSpan(
                                text: "$turnName's",
                                style: TextStyle(
                                  color: _getColor(turnColor),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const TextSpan(text: " move"),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // C. THE BOARD
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                            ],
                          ),
                          child: BoardLayout(
                            gameModel: game,
                            currentUserId: widget.userId,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // D. CONTROLS
                    Container(
                      height: 140,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: const Color(0xFF3E2723).withOpacity(0.8),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          border: const Border(top: BorderSide(color: Color(0xFF8D6E63), width: 4))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: _woodenBoxDecoration().copyWith(
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("You are:", style: TextStyle(color: Color(0xFF3E2723), fontSize: 12)),
                                Text(
                                    _getMyColor(game, widget.userId),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF3E2723))
                                ),
                              ],
                            ),
                          ),
                          Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)
                              ),
                              child: DiceWidget(myPlayerId: widget.userId)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  // --- HELPERS ---
  BoxDecoration _woodenBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFD7CCC8),
      image: const DecorationImage(
        image: AssetImage('assets/wood.png'),
        fit: BoxFit.cover,
        opacity: 0.5,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF5D4037), width: 2),
      boxShadow: const [
        BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 4)
      ],
    );
  }

  String _getMyColor(GameModel game, String userId) {
    final me = game.players.firstWhere(
            (p) => p['id'] == userId,
        orElse: () => {'color': 'Spectator'}
    );
    return me['color'];
  }

  Color _getColor(String colorName) {
    if (colorName == 'Red') return const Color(0xFFC62828);
    if (colorName == 'Green') return const Color(0xFF2E7D32);
    if (colorName == 'Yellow') return const Color(0xFFF9A825);
    if (colorName == 'Blue') return const Color(0xFF1565C0);
    return Colors.black;
  }

  // --- DIALOGS ---

  // 1. CELEBRATION / RANKING DIALOG (NEW)
  void _showCelebrationDialog(int rank, bool isLoser) {
    String title;
    String message;
    Color color;
    IconData icon;

    if (isLoser) {
      title = "😢 YOU LOST 😢";
      message = "Better luck next time!";
      color = Colors.red;
      icon = Icons.sentiment_very_dissatisfied;
    } else {
      switch (rank) {
        case 1:
          title = "🏆 1st PLACE! 🏆";
          message = "Champion! You won the game!";
          color = Colors.amber;
          icon = Icons.emoji_events;
          break;
        case 2:
          title = "🥈 2nd PLACE! 🥈";
          message = "Great job! You finished 2nd.";
          color = const Color(0xFFB0BEC5); // Silver
          icon = Icons.emoji_events;
          break;
        case 3:
          title = "🥉 3rd PLACE! 🥉";
          message = "Good game! You finished 3rd.";
          color = const Color(0xFF8D6E63); // Bronze
          icon = Icons.emoji_events;
          break;
        default:
          title = "WINNER!";
          message = "You finished the game!";
          color = Colors.amber;
          icon = Icons.star;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Must tap button
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF5D4037), width: 3),
        ),
        title: Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color, shadows: const [Shadow(color: Colors.black26, blurRadius: 2)]),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: color),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
            ),
            if (!isLoser)
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  "(You can stay and watch the others finish!)",
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              )
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // EXIT BUTTON
              TextButton(
                onPressed: () {
                  context.read<GameBloc>().add(LeaveGameEvent(widget.gameId, widget.userId));
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text("EXIT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
              // CONTINUE WATCHING BUTTON (Only if not loser/game over)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3E2723)),
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showLeaveConfirmDialog(GameModel game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8),
        title: const Text("Leave Game?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("You will be removed from the game."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<GameBloc>().add(LeaveGameEvent(widget.gameId, widget.userId));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Leave", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    if (ModalRoute.of(context)?.isCurrent != true) return;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Game Over"),
        content: const Text("Everyone else has left the game!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }
}