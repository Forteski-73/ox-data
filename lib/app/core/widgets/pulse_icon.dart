import 'package:flutter/material.dart';

class PulseIconButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onPressed;

  const PulseIconButton({
    Key? key,
    required this.icon,
    this.size = 28,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<PulseIconButton> createState() => _PulseIconButtonState();
}

class _PulseIconButtonState extends State<PulseIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _handleTap() async {
    await _controller.forward();   // cresce
    await _controller.reverse();   // volta
    widget.onPressed();            // chama ação original
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: IconButton(
        icon: Icon(widget.icon, size: widget.size),
        color: widget.color,
        onPressed: _handleTap,
      ),
    );
  }
}
