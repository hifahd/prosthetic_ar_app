import 'package:flutter/material.dart';

class CameraOverlay extends CustomPainter {
  final Color guideColor;
  final double opacity;
  final List<Offset> bodyPoints;
  final Offset? anchorPosition;

  CameraOverlay({
    this.guideColor = Colors.white,
    this.opacity = 0.7,
    this.bodyPoints = const [],
    this.anchorPosition,
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

    // Draw guide lines for body positioning
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Horizontal guide line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );

    // Vertical guide line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paint,
    );

    // Draw body outline guidance
    final bodyPath = Path();

    // Head circle
    canvas.drawCircle(
      Offset(centerX, size.height * 0.15),
      size.width * 0.06,
      paint,
    );

    // Body silhouette guidance
    bodyPath.moveTo(
        centerX - size.width * 0.1, size.height * 0.25); // Left shoulder
    bodyPath.lineTo(
        centerX + size.width * 0.1, size.height * 0.25); // Right shoulder
    bodyPath.lineTo(
        centerX + size.width * 0.12, size.height * 0.7); // Right hip
    bodyPath.lineTo(centerX - size.width * 0.12, size.height * 0.7); // Left hip
    bodyPath.close();

    canvas.drawPath(bodyPath, paint);

    // Draw detected body points if available
    for (var point in bodyPoints) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 8, paint);
    }

    // Draw anchor point if selected
    if (anchorPosition != null) {
      final anchorPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(anchorPosition!, 15, anchorPaint);
      canvas.drawCircle(anchorPosition!, 5, Paint()..color = Colors.red);
    }

    // Draw instruction text
    final textSpan = TextSpan(
      text: anchorPosition == null
          ? 'Align your body with the guide'
          : 'Prosthetic anchored',
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
    textPainter.layout(maxWidth: size.width * 0.8);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.05,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
