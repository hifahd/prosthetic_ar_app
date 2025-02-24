import 'package:flutter/material.dart';

class CameraOverlay extends CustomPainter {
  final Color guideColor;
  final double opacity;

  CameraOverlay({
    this.guideColor = Colors.white,
    this.opacity = 0.7,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = guideColor.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dotPaint = Paint()
      ..color = guideColor.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    // Screen dimensions
    final double width = size.width;
    final double height = size.height;

    // Draw body outline
    var path = Path();

    // Head circle
    canvas.drawCircle(
      Offset(width * 0.5, height * 0.15),
      width * 0.08,
      paint,
    );

    // Body outline
    path.moveTo(width * 0.4, height * 0.25); // Left shoulder
    path.lineTo(width * 0.6, height * 0.25); // Right shoulder
    path.lineTo(width * 0.65, height * 0.8); // Right hip
    path.lineTo(width * 0.35, height * 0.8); // Left hip
    path.close();

    // Left arm
    path.moveTo(width * 0.4, height * 0.25); // Shoulder
    path.lineTo(width * 0.3, height * 0.45); // Elbow
    path.lineTo(width * 0.25, height * 0.6); // Hand

    // Right arm
    path.moveTo(width * 0.6, height * 0.25); // Shoulder
    path.lineTo(width * 0.7, height * 0.45); // Elbow
    path.lineTo(width * 0.75, height * 0.6); // Hand

    // Left leg
    path.moveTo(width * 0.35, height * 0.8); // Hip
    path.lineTo(width * 0.3, height * 0.9); // Knee
    path.lineTo(width * 0.35, height); // Foot

    // Right leg
    path.moveTo(width * 0.65, height * 0.8); // Hip
    path.lineTo(width * 0.7, height * 0.9); // Knee
    path.lineTo(width * 0.65, height); // Foot

    canvas.drawPath(path, paint);

    // Draw key measurement points
    final points = [
      Offset(width * 0.3, height * 0.9), // Left knee
      Offset(width * 0.7, height * 0.9), // Right knee
      Offset(width * 0.35, height), // Left ankle
      Offset(width * 0.65, height), // Right ankle
    ];

    for (var point in points) {
      canvas.drawCircle(point, 5, dotPaint);
    }

    // Draw guide text
    final textSpan = TextSpan(
      text: 'Align your body with the outline',
      style: TextStyle(
        color: guideColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width * 0.8);
    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        height * 0.05,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
