import 'package:flutter/material.dart';
import 'dart:math';
import 'admin_login.dart';
import 'teacher_login.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  RoleSelectionPageState createState() => RoleSelectionPageState();
}

class RoleSelectionPageState extends State<RoleSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // Continuous glowing loop
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login/login_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 📷 Top Image
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/login/login_select.png',
                height: 250,
                width: size.width * 0.9,
                fit: BoxFit.contain,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 380),
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildAnimatedGlowButton(
                          label: 'Admin Login',
                          onPressed: () {
                            _navigateToPage(AdminLoginPage());
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildAnimatedGlowButton(
                          label: 'Teacher Login',
                          onPressed: () {
                            _navigateToPage(TeacherLoginPage());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✨ Animated Glowing Border Button (Gemini-style)
  Widget _buildAnimatedGlowButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowingBorderPainter(_controller.value),
          child: Container(
            padding: const EdgeInsets.all(3.5), // Border thickness
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 10,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Method to handle navigation with custom fade + scale transition
  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Fade animation
          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);

          // Scale animation
          var scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(animation);

          return FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// 🎨 Glowing border painter with circular gradient effect
class _GlowingBorderPainter extends CustomPainter {
  final double progress;

  _GlowingBorderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * pi,
      tileMode: TileMode.mirror,
      transform: GradientRotation(2 * pi * progress),
      colors: const [
        Colors.cyanAccent,
        Colors.deepPurpleAccent,
        Colors.pinkAccent,
        Colors.tealAccent,
        Colors.cyanAccent,
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      Radius.circular(22),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}