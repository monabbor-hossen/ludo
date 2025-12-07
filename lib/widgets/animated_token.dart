import 'dart:async';
import 'package:flutter/material.dart';
import '../logic/path_constants.dart';
import '../services/audio_service.dart';
import 'token_pawn.dart'; // <--- IMPORT YOUR 3D PAWN

class AnimatedToken extends StatefulWidget {
  final String colorName;
  final int tokenIndex;
  final int currentPosition; // Server position
  final bool isDimmed;
  final double cellSize;
  final double tokenSize;
  final VoidCallback onTap;

  const AnimatedToken({
    super.key,
    required this.colorName,
    required this.tokenIndex,
    required this.currentPosition,
    required this.isDimmed,
    required this.cellSize,
    required this.tokenSize,
    required this.onTap,
  });

  @override
  State<AnimatedToken> createState() => _AnimatedTokenState();
}

class _AnimatedTokenState extends State<AnimatedToken> with SingleTickerProviderStateMixin {
  late int _visualPosition;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnim;

  double _left = 0;
  double _top = 0;

  @override
  void initState() {
    super.initState();
    _visualPosition = widget.currentPosition;
    _updateCoordinates(_visualPosition);

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Hop effect: Scale up 1.3x then back to 1.0x
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(AnimatedToken oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If position changed, animate steps
    if (widget.currentPosition != oldWidget.currentPosition) {
      _animateToNewPosition(oldWidget.currentPosition, widget.currentPosition);
    }
    // If board resized, update immediately
    else if (widget.cellSize != oldWidget.cellSize) {
      _updateCoordinates(_visualPosition);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _animateToNewPosition(int start, int end) async {
    // 1. Reset/Kill Logic (Direct Teleport)
    if (end == 0 && start != 0) {
      if (mounted) {
        setState(() {
          _visualPosition = 0;
          _updateCoordinates(0);
        });
      }
      return;
    }

    // 2. Step-by-Step Walk
    int steps = end - start;
    if (steps < 0) return;

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;

      int nextStep = start + i;

      setState(() {
        _visualPosition = nextStep;
        _updateCoordinates(nextStep);
      });

      _bounceController.forward(from: 0); // Trigger Hop
      AudioService.playMove(); // Tick Sound

      await Future.delayed(const Duration(milliseconds: 250)); // Walk Speed
    }
  }

  void _updateCoordinates(int pos) {
    double centeringOffset = (widget.cellSize - widget.tokenSize) / 2;
    double l = 0;
    double t = 0;

    if (pos == 99) { // Winner Center
      double centerGrid = 7.0 * widget.cellSize;
      switch (widget.colorName) {
        case 'Red': l = centerGrid - (widget.cellSize * 0.6); t = centerGrid; break;
        case 'Green': l = centerGrid; t = centerGrid - (widget.cellSize * 0.6); break;
        case 'Yellow': l = centerGrid + (widget.cellSize * 0.6); t = centerGrid; break;
        case 'Blue': l = centerGrid; t = centerGrid + (widget.cellSize * 0.6); break;
      }
      double jitter = widget.tokenIndex * (widget.tokenSize * 0.2);
      if (widget.colorName == 'Red' || widget.colorName == 'Yellow') t += jitter - (widget.tokenSize * 0.3);
      if (widget.colorName == 'Green' || widget.colorName == 'Blue') l += jitter - (widget.tokenSize * 0.3);
      l += centeringOffset; t += centeringOffset;
    }
    else if (pos == 0) { // Home Base
      var point = PathConstants.homeBases[widget.colorName]?[widget.tokenIndex];
      if (point != null) {
        l = (point.col * widget.cellSize) + centeringOffset;
        t = (point.row * widget.cellSize) + centeringOffset;
      }
    }
    else { // Path
      var point = PathConstants.stepToGrid[pos];
      if (point != null) {
        l = (point.col * widget.cellSize) + centeringOffset;
        t = (point.row * widget.cellSize) + centeringOffset;
      }
    }

    _left = l;
    _top = t;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      left: _left,
      top: _top,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SizedBox(
            width: widget.tokenSize,
            height: widget.tokenSize,
            // --- RESTORED 3D PAWN WIDGET HERE ---
            child: TokenPawn(
              colorName: widget.colorName,
              tokenIndex: widget.tokenIndex,
              isDimmed: widget.isDimmed,
              showNumber: true, // Always show numbers on the board
            ),
          ),
        ),
      ),
    );
  }
}