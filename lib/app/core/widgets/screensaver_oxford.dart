import 'package:flutter/material.dart';

class ScreensaverOxford extends StatefulWidget {
  const ScreensaverOxford({super.key});

  @override
  State<ScreensaverOxford> createState() => _ScreensaverOxfordState();
}

class _ScreensaverOxfordState extends State<ScreensaverOxford>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [Colors.white24, Colors.white, Colors.white24],
                    stops: const [0.0, 0.5, 1.0],
                    transform: GradientRotation(_controller.value * 6.28),
                  ).createShader(bounds);
                },
                child: const Text(
                  'AGUARDANDO..',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          const SizedBox(
            width: 200, 
            child: LinearProgressIndicator(
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
            ),
          ),
        ],
      ),
    );
  }
}