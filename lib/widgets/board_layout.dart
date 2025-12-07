import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ludo/widgets/ludo_board_painter.dart';
// import 'package:ludo/widgets/token_pawn.dart'; // <-- NO LONGER NEEDED HERE
import 'package:ludo/widgets/animated_token.dart'; // <-- IMPORT NEW WIDGET
import '../models/game_model.dart';
import '../logic/game_engine.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';

class BoardLayout extends StatelessWidget {
  final GameModel gameModel;
  final String currentUserId;
  final GameEngine _engine = GameEngine();

  BoardLayout({
    super.key,
    required this.gameModel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double boardSize = constraints.maxWidth;
        double cellSize = boardSize / 15.0;
        double tokenSize = cellSize * 0.9;

        return SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: LudoBoardPainter(players: gameModel.players),
                ),
              ),
              // Build animated tokens
              ..._buildTokens(context, gameModel.tokens, cellSize, tokenSize),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTokens(BuildContext context, Map<String, List<int>> allTokens, double cellSize, double tokenSize) {
    List<Widget> widgets = [];

    allTokens.forEach((color, positions) {
      for (int i = 0; i < positions.length; i++) {
        int currentPos = positions[i];

        // Only render if valid (logic is now inside AnimatedToken mostly)
        // But we keep the loop to generate the widgets

        widgets.add(
          AnimatedToken(
            // Use ValueKey so Flutter knows which pawn to animate specifically
            key: ValueKey("$color-$i"),
            colorName: color,
            tokenIndex: i,
            currentPosition: currentPos,
            isDimmed: gameModel.diceValue == 0 || currentPos == 99,
            cellSize: cellSize,
            tokenSize: tokenSize,
            onTap: () => _handleTap(context, color, i, currentPos),
          ),
        );
      }
    });
    return widgets;
  }

  void _handleTap(BuildContext context, String clickedPawnColor, int index, int currentPos) {
    final myPlayer = gameModel.players.firstWhere(
            (p) => p['id'] == currentUserId,
        orElse: () => {'color': 'Spectator'}
    );
    String myColor = myPlayer['color'];

    if (clickedPawnColor != myColor) return;
    if (gameModel.diceValue == 0) return;

    final currentPlayer = gameModel.players[gameModel.currentTurn];
    if (currentPlayer['id'] != currentUserId) return;

    int nextPos = _engine.calculateNextPosition(currentPos, gameModel.diceValue, clickedPawnColor);
    if (nextPos == currentPos) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid move!"), duration: Duration(milliseconds: 500)));
      return;
    }

    context.read<GameBloc>().add(
      MoveToken(
        gameId: gameModel.gameId,
        userId: currentUserId,
        tokenIndex: index,
      ),
    );
  }
}