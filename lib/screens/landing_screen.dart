import 'package:flutter/material.dart';
import 'package:ludo/screens/computer_game_board.dart';
import 'home_menu.dart'; // Navigates to Online Menu

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isSoundOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. GLOBAL WOOD BACKGROUND
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/wood.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // A. TOP BAR (Settings & Sound)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallWoodenBtn(
                      icon: Icons.settings,
                      onTap: () => _showSettingsDialog(context),
                    ),
                    _buildSmallWoodenBtn(
                      icon: _isSoundOn ? Icons.volume_up : Icons.volume_off,
                      onTap: () {
                        setState(() => _isSoundOn = !_isSoundOn);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // B. GAME LOGO (Large Plank)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 25),
                decoration: _woodenBoxDecoration().copyWith(
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), offset: const Offset(5, 8), blurRadius: 10)
                    ]
                ),
                child: const Column(
                  children: [
                    Icon(Icons.casino, size: 50, color: Color(0xFF3E2723)), // Dice Icon
                    Text(
                      "Goriber\nLUDO",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3E2723), // Dark Brown
                        height: 0.9,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: Colors.white54, offset: Offset(1, 1), blurRadius: 0)
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // C. MAIN MENU PANEL
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723).withOpacity(0.85), // Dark overlay
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 3),
                ),
                child: Column(
                  children: [
                    // BUTTON 1: WITH FRIEND (Online)
                    _buildMainButton(
                      context,
                      title: "PLAY ONLINE",
                      subtitle: "Multiplayer with Friends",
                      icon: Icons.public,
                      color: const Color(0xFF43A047), // Green
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeMenu()),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // BUTTON 2: WITH COMPUTER
                    // BUTTON 2: WITH COMPUTER
                    _buildMainButton(
                      context,
                      title: "VS COMPUTER",
                      subtitle: "Offline Mode",
                      icon: Icons.computer,
                      color: const Color(0xFFE53935),
                      onTap: () => _showColorPickerDialog(context), // <--- New Function
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // D. BOTTOM INFO
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  "Version 1.0.0",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: MAIN MENU BUTTON ---
  Widget _buildMainButton(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color,
          image: const DecorationImage(
            image: AssetImage('assets/wood.png'),
            fit: BoxFit.cover,
            opacity: 0.15, // Texture
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(2, 4), blurRadius: 5)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: SMALL TOP BUTTON ---
  Widget _buildSmallWoodenBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _woodenBoxDecoration(),
        child: Icon(icon, color: const Color(0xFF3E2723), size: 24),
      ),
    );
  }

  // --- HELPER: WOODEN STYLE ---
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8),
        title: const Text("Settings", style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
        content: const Text("Settings menu coming soon!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close", style: TextStyle(color: Color(0xFF3E2723))),
          )
        ],
      ),
    );
  }
  void _showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFD7CCC8), // Wood color
        title: const Text("Choose Your Color", style: TextStyle(color: Color(0xFF3E2723), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("The computer will play the opposite side."),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorBtn(ctx, 'Red', Colors.red),
                _colorBtn(ctx, 'Green', Colors.green),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _colorBtn(ctx, 'Blue', Colors.blue),
                _colorBtn(ctx, 'Yellow', Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorBtn(BuildContext ctx, String color, Color colorVal) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx); // Close Dialog
        // Navigate to Game with selected color
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ComputerGameBoard(userColor: color)),
        );
      },
      child: CircleAvatar(
        radius: 30,
        backgroundColor: colorVal,
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2,2))]
          ),
        ),
      ),
    );
  }
}