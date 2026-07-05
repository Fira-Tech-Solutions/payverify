import 'dart:math';
import 'package:flutter/material.dart';

class SealPainter extends CustomPainter {
  final double animationValue;
  final Color goldColor;
  final Color greenColor;
  final Color darkColor;
  final Color lightColor;

  SealPainter({
    required this.animationValue,
    this.goldColor = const Color(0xFFB8860B),
    this.greenColor = const Color(0xFF2E7D32),
    this.darkColor = const Color(0xFF1A1A2E),
    this.lightColor = const Color(0xFFEEF2F8),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer stamp ring
    final outerRingPaint = Paint()..color = const Color(0xFF0D0D1F);
    canvas.drawCircle(center, radius, outerRingPaint);

    // Gold ring
    final goldRingPaint = Paint()..color = goldColor;
    canvas.drawCircle(center, radius * 0.93, goldRingPaint);

    // Light inner circle
    final innerCirclePaint = Paint()..color = lightColor;
    canvas.drawCircle(center, radius * 0.85, innerCirclePaint);

    // Serrated dots
    final dotPaint = Paint()..color = goldColor;
    for (int i = 0; i < 20; i++) {
      final angle = (i * 2 * pi / 20) - pi / 2;
      final dotX = center.dx + radius * 0.96 * cos(angle);
      final dotY = center.dy + radius * 0.96 * sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), radius * 0.04, dotPaint);
    }

    // Shield
    final shieldPath = Path();
    final shieldTop = center.dy - radius * 0.55;
    final shieldBottom = center.dy + radius * 0.35;
    final shieldLeft = center.dx - radius * 0.35;
    final shieldRight = center.dx + radius * 0.35;
    final shieldCenterY = center.dy - radius * 0.15;

    shieldPath.moveTo(center.dx, shieldTop);
    shieldPath.lineTo(shieldRight, shieldTop + radius * 0.15);
    shieldPath.lineTo(shieldRight, shieldCenterY);
    shieldPath.quadraticBezierTo(
      shieldRight,
      shieldBottom,
      center.dx,
      shieldBottom + radius * 0.15,
    );
    shieldPath.quadraticBezierTo(
      shieldLeft,
      shieldBottom,
      shieldLeft,
      shieldCenterY,
    );
    shieldPath.lineTo(shieldLeft, shieldTop + radius * 0.15);
    shieldPath.close();

    final shieldFillPaint = Paint()..color = darkColor;
    canvas.drawPath(shieldPath, shieldFillPaint);

    final shieldStrokePaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(shieldPath, shieldStrokePaint);

    // Checkmark
    final checkPaint = Paint()
      ..color = greenColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path();
    checkPath.moveTo(center.dx - radius * 0.18, center.dy + radius * 0.02);
    checkPath.lineTo(center.dx - radius * 0.05, center.dy + radius * 0.18);
    checkPath.lineTo(center.dx + radius * 0.22, center.dy - radius * 0.18);
    canvas.drawPath(checkPath, checkPaint);

    // Circuit tree on top
    final treePaint = Paint()
      ..color = greenColor
      ..strokeWidth = radius * 0.03
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx, shieldTop - radius * 0.02),
      Offset(center.dx, shieldTop - radius * 0.2),
      treePaint,
    );

    // Left branch
    final leftBranchPaint = Paint()
      ..color = greenColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.025
      ..strokeCap = StrokeCap.round;

    final leftBranch = Path();
    leftBranch.moveTo(center.dx, shieldTop - radius * 0.12);
    leftBranch.quadraticBezierTo(
      center.dx - radius * 0.2,
      shieldTop - radius * 0.18,
      center.dx - radius * 0.3,
      shieldTop - radius * 0.25,
    );
    canvas.drawPath(leftBranch, leftBranchPaint);

    // Right branch
    final rightBranchPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.025
      ..strokeCap = StrokeCap.round;

    final rightBranch = Path();
    rightBranch.moveTo(center.dx, shieldTop - radius * 0.12);
    rightBranch.quadraticBezierTo(
      center.dx + radius * 0.2,
      shieldTop - radius * 0.18,
      center.dx + radius * 0.3,
      shieldTop - radius * 0.25,
    );
    canvas.drawPath(rightBranch, rightBranchPaint);

    // Circuit nodes
    final nodePaint = Paint()..color = greenColor;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.31, shieldTop - radius * 0.26),
      radius * 0.035,
      nodePaint,
    );

    final goldNodePaint = Paint()..color = goldColor;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.31, shieldTop - radius * 0.26),
      radius * 0.035,
      goldNodePaint,
    );

    final darkNodePaint = Paint()..color = darkColor;
    canvas.drawCircle(
      Offset(center.dx, shieldTop - radius * 0.2),
      radius * 0.035,
      darkNodePaint,
    );

    // Arc text - PAYVERIFY · ETHIOPIA
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'PAYVERIFY · ETHIOPIA',
        style: TextStyle(
          color: darkColor,
          fontSize: radius * 0.12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw curved text along top arc
    const textRadiusFactor = 0.72;
    const textStartAngleFactor = -0.8;
    const textSweepAngleFactor = 0.6;
    final textRadius = radius * textRadiusFactor;
    final textStartAngle = pi * textStartAngleFactor;
    final textSweepAngle = pi * textSweepAngleFactor;

    canvas.save();
    for (int i = 0; i < textPainter.width.toInt(); i++) {
      final t = i / textPainter.width;
      final angle = textStartAngle + textSweepAngle * t;
      final x = center.dx + textRadius * cos(angle);
      final y = center.dy + textRadius * sin(angle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    canvas.restore();

    // Bottom arc text - FIRA TECH SOLUTIONS
    final bottomTextPainter = TextPainter(
      text: TextSpan(
        text: 'FIRA TECH SOLUTIONS',
        style: TextStyle(
          color: goldColor,
          fontSize: radius * 0.1,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.5,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    bottomTextPainter.layout();

    const bottomTextRadiusFactor = 0.65;
    const bottomTextStartAngleFactor = 0.2;
    const bottomTextSweepAngleFactor = 0.6;
    final bottomTextRadius = radius * bottomTextRadiusFactor;
    final bottomTextStartAngle = pi * bottomTextStartAngleFactor;
    final bottomTextSweepAngle = pi * bottomTextSweepAngleFactor;

    canvas.save();
    for (int i = 0; i < bottomTextPainter.width.toInt(); i++) {
      final t = i / bottomTextPainter.width;
      final angle = bottomTextStartAngle + bottomTextSweepAngle * t;
      final x = center.dx + bottomTextRadius * cos(angle);
      final y = center.dy + bottomTextRadius * sin(angle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle - pi / 2);
      bottomTextPainter.paint(canvas, Offset(-bottomTextPainter.width / 2, -bottomTextPainter.height / 2));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SealPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
