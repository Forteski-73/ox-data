import 'package:flutter/material.dart';

class BottomItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
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

  bool get _isDisabled => widget.onTap == null;

  Future<void> _handleTap() async {
    if (_isDisabled) return;

    setState(() => _pressed = true);
    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    setState(() => _pressed = false);
    widget.onTap!.call();
  }

  @override
  Widget build(BuildContext context) {
    final Color disabledBg = Colors.grey.shade400;
    final Color disabledFg = Colors.grey.shade700;

    final Color bgColor = _isDisabled
        ? disabledBg
        : (_pressed
            ? widget.backgroundColor.withOpacity(0.35)
            : widget.backgroundColor);

    final Color iconColor = _isDisabled
        ? disabledFg
        : (_pressed
            ? widget.iconColor.withOpacity(0.6)
            : widget.iconColor);

    final Color textColor =
        _isDisabled ? disabledFg : widget.textColor;

    return Expanded(
      child: InkWell(
        onTap: _isDisabled ? null : _handleTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: double.infinity,
          color: bgColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: iconColor,
                size: 30,
              ),
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
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