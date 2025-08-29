import 'package:flutter/material.dart';

class ButtonCard extends StatefulWidget {
  final String? imagePath;
  final IconData? icon;
  final String title;
  final VoidCallback onTap;

  const ButtonCard({
    super.key,
    this.imagePath,
    this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<ButtonCard> createState() => _ButtonCardState();
}

class _ButtonCardState extends State<ButtonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _animation,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // evita overflow vertical
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.imagePath != null)
                  Flexible(
                    child: Image.asset(
                      widget.imagePath!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  )
                else if (widget.icon != null)
                  Flexible(
                    child: Icon(
                      widget.icon,
                      size: 60,
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
