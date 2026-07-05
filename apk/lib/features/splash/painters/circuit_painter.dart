import 'dart:math';
import 'package:flutter/material.dart';

class CircuitCornerPainter extends CustomPainter {
  final Color greenColor;
  final Color goldColor;

  CircuitCornerPainter({
    this.greenColor = const Color(0xFF2E7D32),
    this.goldColor = const Color(0xFFB8860B),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // L-shaped polyline
    paint.color = greenColor.withValues(alpha: 0.5);
    final path = Path();
    path.moveTo(5, size.height - 5);
    path.lineTo(5, 5);
    path.lineTo(size.width - 5, 5);
    canvas.drawPath(path, paint);

    // Corner node
    final cornerNodePaint = Paint()..color = greenColor.withValues(alpha: 0.6);
    canvas.drawCircle(const Offset(5, 5), 3, cornerNodePaint);

    // Gold nodes
    final goldNodePaint = Paint()..color = goldColor.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.width * 0.4, 5), 2, goldNodePaint);
    canvas.drawCircle(Offset(5, size.height * 0.5), 2, goldNodePaint);

    // Extension lines
    paint.color = greenColor.withValues(alpha: 0.3);
    paint.strokeWidth = 1;
    canvas.drawLine(
      const Offset(25, 5),
      const Offset(25, 18),
      paint,
    );
    canvas.drawLine(
      const Offset(5, 30),
      const Offset(18, 30),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CircuitCornerPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  final Color color;

  GridPainter({this.color = const Color(0xFF2E7D32)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    // Horizontal lines
    for (double y in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(size.width, size.height * y),
        paint,
      );
    }

    // Vertical lines
    for (double x in [0.25, 0.5, 0.75]) {
      canvas.drawLine(
        Offset(size.width * x, 0),
        Offset(size.width * x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}

class PulsingDot {
  final double x;
  final double y;
  final double size;
  final double delay;

  PulsingDot({
    required this.x,
    required this.y,
    required this.size,
    required this.delay,
  });
}

class PulsingDotsPainter extends CustomPainter {
  final double animationValue;
  final List<PulsingDot> dots;
  final Color color;

  PulsingDotsPainter({
    required this.animationValue,
    required this.dots,
    this.color = const Color(0xFF2E7D32),
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final phase = (animationValue + dot.delay) % 1.0;
      final opacity = 0.15 + 0.35 * sin(phase * 2 * pi);
      final scale = 1.0 + 0.4 * sin(phase * 2 * pi);

      final paint = Paint()..color = color.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(size.width * dot.x, size.height * dot.y),
        dot.size * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PulsingDotsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
