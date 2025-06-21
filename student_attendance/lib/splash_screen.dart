import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';

class SplashScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SplashScreen(this.cameras, {super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _dropController;
  late Animation<Offset> _dropAnimation;

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  late AnimationController _textController;

  @override
  void initState() {
    super.initState();

    // Drop-in animation
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _dropAnimation = Tween<Offset>(
      begin: const Offset(0, -4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _dropController, curve: Curves.bounceOut));

    // One-time zoom-in/out animation
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _zoomAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.30).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.30, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_zoomController);

    // Text fade-in animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Sequence: Drop → Zoom → Text → Pause → Navigate
    _dropController.forward().then((_) {
      _zoomController.forward();
      _textController.forward();
    });

    // Navigate after animations + pause
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/secondary');
      }
    });
  }

  @override
  void dispose() {
    _dropController.dispose();
    _zoomController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2196F3), // Blue
              Color(0xFF9C27B0), // Purple
              Color(0xFFE91E63), // Pink
              Color(0xFFFF9800), // Orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _dropAnimation,
                child: ScaleTransition(
                  scale: _zoomAnimation,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/face_logo.jpg', // Use your image path
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _textController,
                child: const Text(
                  "Student Attendance",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
