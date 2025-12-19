import 'package:flutter/material.dart';

class BottomItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const BottomItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  State<BottomItem> createState() => _BottomItemState();
}

class _BottomItemState extends State<BottomItem> {
  bool _pressed = false;

  Future<void> _handleTap() async {
    setState(() => _pressed = true);

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    setState(() => _pressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final Color flashedBg =
        widget.backgroundColor.withOpacity(0.35);

    final Color flashedIcon =
        widget.iconColor.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: _handleTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: double.infinity,
          color: _pressed ? flashedBg : widget.backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 120),
                child: Icon(
                  widget.icon,
                  key: ValueKey(_pressed),
                  color: _pressed
                      ? flashedIcon
                      : widget.iconColor,
                  size: 32,
                ),
              ),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
