import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/game/game_bloc.dart';
import '../blocs/game/game_event.dart';
import '../blocs/game/game_state.dart';
import '../services/audio_service.dart';

class DiceWidget extends StatefulWidget {
  final String myPlayerId;
  const DiceWidget({super.key, required this.myPlayerId});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Timer? _animTimer;
  int _displayValue = 1;
  bool _isRolling = false;
  int _lastServerDiceValue = 0;

  // 1. Track start time to enforce 0.5s duration
  DateTime? _rollStartTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Speed of one spin
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // --- 1. START ANIMATION ---
  void _startRollingAnim() {
    if (_isRolling) return;

    AudioService.playRoll();

    // 2. Record the Start Time
    _rollStartTime = DateTime.now();

    setState(() {
      _isRolling = true;
    });

    _controller.repeat();

    // Show random numbers rapidly (every 80ms)
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (mounted) {
        setState(() {
          _displayValue = Random().nextInt(6) + 1;
        });
      }
    });
  }

  // --- 2. STOP ANIMATION (With Delay) ---
  Future<void> _stopRollingAnim(int finalValue) async {
    // 3. Calculate how long we have been rolling
    if (_rollStartTime != null) {
      final int minDuration = 500; // 0.5 seconds
      final int elapsed = DateTime.now().difference(_rollStartTime!).inMilliseconds;

      if (elapsed < minDuration) {
        // If server replied too fast (e.g. 100ms), wait the remaining 400ms
        await Future.delayed(Duration(milliseconds: minDuration - elapsed));
      }
    }

    _animTimer?.cancel();

    if (mounted) {
      _controller.stop();
      _controller.value = 0; // Reset to upright position

      setState(() {
        _isRolling = false;
        _displayValue = finalValue; // Show the REAL number
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameLoaded) {
          final game = state.gameModel;

          // A. SERVER SENT ROLL
          if (game.diceValue != 0 && game.diceValue != _lastServerDiceValue) {
            _lastServerDiceValue = game.diceValue;
            _stopRollingAnim(game.diceValue);
          }

          // B. TURN RESET
          if (game.diceValue == 0) {
            _lastServerDiceValue = 0;
            if (_isRolling) {
              _stopRollingAnim(_displayValue);
            }
          }
        }
      },
      child: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          if (state is! GameLoaded) return const SizedBox();

          final game = state.gameModel;
          final isMyTurn = game.players[game.currentTurn]['id'] == widget.myPlayerId;
          final diceIsReset = game.diceValue == 0;
          final canRoll = isMyTurn && diceIsReset && !_isRolling;

          // Visual Styles
          final Color boxColor = canRoll ? Colors.white : Colors.grey[300]!;
          final Color dotColor = canRoll ? Colors.black : Colors.grey[600]!;

          return GestureDetector(
            onTap: () {
              if (!isMyTurn) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not your turn!")));
                return;
              }
              if (!diceIsReset) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Move your pawn first!")));
                return;
              }

              if (canRoll) {
                _startRollingAnim();
                context.read<GameBloc>().add(RollDice(game.gameId));
              }
            },
            child: RotationTransition(
              turns: _controller,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: CustomPaint(
                  painter: _DotPainter(_displayValue, dotColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  final int number;
  final Color color;

  _DotPainter(this.number, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    double r = size.width / 10;
    double c = size.width / 2;
    double l = size.width / 4;
    double m = size.width * 0.75;

    List<Offset> dots = [];
    switch (number) {
      case 1: dots = [Offset(c, c)]; break;
      case 2: dots = [Offset(l, l), Offset(m, m)]; break;
      case 3: dots = [Offset(l, l), Offset(c, c), Offset(m, m)]; break;
      case 4: dots = [Offset(l, l), Offset(m, l), Offset(l, m), Offset(m, m)]; break;
      case 5: dots = [Offset(l, l), Offset(m, l), Offset(c, c), Offset(l, m), Offset(m, m)]; break;
      case 6: dots = [Offset(l, l), Offset(m, l), Offset(l, c), Offset(m, c), Offset(l, m), Offset(m, m)]; break;
      default: dots = [Offset(c, c)];
    }

    for (var d in dots) {
      canvas.drawCircle(d, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter oldDelegate) {
    return oldDelegate.number != number || oldDelegate.color != color;
  }
}