import 'package:flutter/material.dart';
import '../logic/path_constants.dart';

class LudoBoardPainter extends CustomPainter {
  // 1. Accept the list of players to find names
  final List<Map<String, dynamic>> players;

  LudoBoardPainter({required this.players});

  final Color redColor = const Color(0xFFE53935);
  final Color greenColor = const Color(0xFF43A047);
  final Color yellowColor = const Color(0xFFFDD835);
  final Color blueColor = const Color(0xFF1E88E5);
  final Color borderColor = const Color(0xFF000000);

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / 15.0;
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = borderColor;

    // Background
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw Bases with Names
    _drawBase(canvas, 0, 0, redColor, "Red", cellSize);
    _drawBase(canvas, 9, 0, greenColor, "Green", cellSize);
    _drawBase(canvas, 9, 9, yellowColor, "Yellow", cellSize);
    _drawBase(canvas, 0, 9, blueColor, "Blue", cellSize);

    _drawGridTracks(canvas, cellSize, strokePaint, paint);
    _drawCenter(canvas, size, cellSize);
  }

  void _drawBase(Canvas canvas, int col, int row, Color color, String colorName, double cellSize) {
    final Paint paint = Paint()..style = PaintingStyle.fill..color = color;

    // A. Colored Base Box
    canvas.drawRect(
      Rect.fromLTWH(col * cellSize, row * cellSize, 6 * cellSize, 6 * cellSize),
      paint,
    );

    // B. White Inner Box
    paint.color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH((col + 1) * cellSize, (row + 1) * cellSize, 4 * cellSize, 4 * cellSize),
      paint,
    );

    // C. Token Circles (Centered)
    paint.color = color.withOpacity(0.2);
    List<Offset> offsets = [
      Offset((col + 2.5) * cellSize, (row + 2.5) * cellSize),
      Offset((col + 2.5) * cellSize, (row + 3.5) * cellSize),
      Offset((col + 3.5) * cellSize, (row + 2.5) * cellSize),
      Offset((col + 3.5) * cellSize, (row + 3.5) * cellSize),
    ];

    for (var offset in offsets) {
      canvas.drawCircle(offset, cellSize * 0.4, Paint()..style=PaintingStyle.stroke..color=color..strokeWidth=2);
    }

    // --- D. DRAW PLAYER NAME ---
    // 1. Find the player with this color
    final player = players.firstWhere(
          (p) => p['color'] == colorName,
      orElse: () => {},
    );

    if (player.isNotEmpty) {
      String name = player['name'] ?? "Player";

      // 2. Configure Text
      final textSpan = TextSpan(
        text: name,
        style: TextStyle(
            color: Colors.white, // White text to pop on colored background
            fontSize: cellSize * 0.6, // Dynamic font size
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(1,1))]
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );

      textPainter.layout(minWidth: 0, maxWidth: 6 * cellSize); // Max width = width of base

      // 3. Position: Centered Horizontally, At the Top of the Base
      final offset = Offset(
        (col * cellSize) + (3 * cellSize) - (textPainter.width / 2), // Center X
        (row * cellSize) + (0.2 * cellSize), // Top Y (with slight padding)
      );

      textPainter.paint(canvas, offset);
    }
  }

  // ... (Keep _drawGridTracks, _fill, _drawStar, _drawCenter exactly as they were) ...

  void _drawGridTracks(Canvas canvas, double cellSize, Paint strokePaint, Paint fillPaint) {
    // ... Paste your existing _drawGridTracks logic here ...
    // (Omitted for brevity, assume previous code remains unchanged)
    for (int row = 0; row < 15; row++) {
      for (int col = 0; col < 15; col++) {
        bool isBase = (row < 6 && col < 6) || (row < 6 && col >= 9) ||
            (row >= 9 && col < 6) || (row >= 9 && col >= 9);
        bool isCenter = (row >= 6 && row <= 8 && col >= 6 && col <= 8);

        if (!isBase && !isCenter) {
          canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize), strokePaint);

          if (row == 6 && col == 1) _fill(canvas, col, row, cellSize, redColor);
          if (row == 1 && col == 8) _fill(canvas, col, row, cellSize, greenColor);
          if (row == 8 && col == 13) _fill(canvas, col, row, cellSize, yellowColor);
          if (row == 13 && col == 6) _fill(canvas, col, row, cellSize, blueColor);

          if (row == 7 && col > 0 && col < 6) _fill(canvas, col, row, cellSize, redColor);
          if (col == 7 && row > 0 && row < 6) _fill(canvas, col, row, cellSize, greenColor);
          if (row == 7 && col > 8 && col < 14) _fill(canvas, col, row, cellSize, yellowColor);
          if (col == 7 && row > 8 && row < 14) _fill(canvas, col, row, cellSize, blueColor);

          if ([const Point(6,1), const Point(2,6), const Point(1,8), const Point(6,12),
            const Point(8,13), const Point(12,8), const Point(13,6), const Point(8,2)]
              .contains(Point(row, col))) {
            _drawStar(canvas, col, row, cellSize);
          }
        }
      }
    }
  }

  void _fill(Canvas canvas, int col, int row, double cellSize, Color color) {
    canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
        Paint()..style = PaintingStyle.fill..color = color);
    canvas.drawRect(Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
        Paint()..style = PaintingStyle.stroke..strokeWidth=1..color = Colors.black);
  }

  void _drawStar(Canvas canvas, int col, int row, double cellSize) {
    final textPainter = TextPainter(
      text: TextSpan(text: String.fromCharCode(Icons.star.codePoint),
          style: TextStyle(fontSize: cellSize * 0.8, fontFamily: Icons.star.fontFamily, color: Colors.black38)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset((col * cellSize) + (cellSize - textPainter.width) / 2, (row * cellSize) + (cellSize - textPainter.height) / 2));
  }

  void _drawCenter(Canvas canvas, Size size, double cellSize) {
    double cx = size.width / 2, cy = size.height / 2;
    double half = (3 * cellSize) / 2;
    Paint paint = Paint()..style = PaintingStyle.fill;

    canvas.drawPath(Path()..moveTo(cx - half, cy - half)..lineTo(cx, cy)..lineTo(cx - half, cy + half)..close(), paint..color = redColor);
    canvas.drawPath(Path()..moveTo(cx - half, cy - half)..lineTo(cx, cy)..lineTo(cx + half, cy - half)..close(), paint..color = greenColor);
    canvas.drawPath(Path()..moveTo(cx + half, cy - half)..lineTo(cx, cy)..lineTo(cx + half, cy + half)..close(), paint..color = yellowColor);
    canvas.drawPath(Path()..moveTo(cx - half, cy + half)..lineTo(cx, cy)..lineTo(cx + half, cy + half)..close(), paint..color = blueColor);
  }

  // Important: Set to true so names update if players join
  @override
  bool shouldRepaint(covariant LudoBoardPainter oldDelegate) => true;
}