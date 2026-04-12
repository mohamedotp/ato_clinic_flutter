import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double spacing;
  final Color color;
  final double dotRadius;

  GridPainter({
    this.spacing = 24.0,
    this.color = const Color(0xFF94A3B8), // Slate 400
    this.dotRadius = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.spacing != spacing ||
           oldDelegate.color != color ||
           oldDelegate.dotRadius != dotRadius;
  }
}
