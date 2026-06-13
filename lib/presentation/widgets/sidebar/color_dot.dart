import 'package:flutter/material.dart';

class ColorDot extends StatelessWidget {
  final String color;
  final double size;
  final VoidCallback? onTap;
  final bool selected;
  final Color? borderColor;
  final Color? selectedBorderColor;

  const ColorDot({
    super.key,
    required this.color,
    this.size = 12,
    this.onTap,
    this.selected = false,
    this.borderColor,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = _parseColor(color);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: parsed,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? (selectedBorderColor ?? Colors.white)
                : (borderColor ?? Colors.transparent),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7 || hex.length == 9) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
