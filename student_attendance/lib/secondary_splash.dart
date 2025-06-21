import 'package:flutter/material.dart';
import 'dart:async';

class SecondarySplashPage extends StatefulWidget {
  const SecondarySplashPage({super.key});

  @override
  State<SecondarySplashPage> createState() => _SecondarySplashPageState();
}

class _SecondarySplashPageState extends State<SecondarySplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  String _text = "";
  final String _fullText = "Welcome To Real Time Face Recognition Attendance System!";
  int _textIndex = 0;
  bool _showCursor = true;

  @override
  void initState() {
    super.initState();

    // Glowing animation controller
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Typing effect
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_textIndex < _fullText.length) {
        setState(() {
          _text += _fullText[_textIndex];
          _textIndex++;
        });
      } else {
        timer.cancel();
      }
    });

    // Cursor blink after typing finishes
    Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (_textIndex < _fullText.length) return;
      setState(() {
        _showCursor = !_showCursor;
      });
    });

    // Navigate after a short delay
    Future.delayed(const Duration(seconds: 8), () {
      Navigator.pushReplacementNamed(context, '/role');
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: CustomPaint(
        child: Container(
          width: size.width,
          height: size.height,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.black87],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(70),
                borderRadius: BorderRadius.circular(12),
                // border: Border.all(color: Colors.white24, width: 1),
              ),
              constraints: BoxConstraints(
                minWidth: 100,
                maxWidth: size.width * 0.9,
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Courier',
                  ),
                  children: [
                    ..._text.runes.map((rune) {
                      final i = _text.runes.toList().indexOf(rune);
                      final hue = (360 * (i / _fullText.length)) % 360;
                      return TextSpan(
                        text: String.fromCharCode(rune),
                        style: TextStyle(
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: [
                                HSLColor.fromAHSL(1.0, hue, 1.0, 0.6).toColor(),
                                HSLColor.fromAHSL(1.0, (hue + 60) % 360, 1.0, 0.6).toColor(),
                              ],
                            ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
                        ),
                      );
                    }),
                    if (_showCursor)
                      const TextSpan(
                        text: "|",
                        style: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}