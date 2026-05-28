import 'package:flutter/material.dart';

class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = const Color(0xFF00E5FF),
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color color;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _pressed ? 0.3 : 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.color, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _pressed ? 0.2 : 0.45),
              blurRadius: _pressed ? 8 : 16,
              spreadRadius: _pressed ? 0 : 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
