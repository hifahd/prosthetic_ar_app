import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class MeasurementOverlay extends CustomPainter {
  final Map<String, dynamic> measurements;
  final Size imageSize;

  MeasurementOverlay({
    required this.measurements,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final measurementPoints = measurements['points'] as List;

    // Draw measurement lines
    for (var i = 0; i < measurementPoints.length - 1; i++) {
      final point1 = _scalePoint(
        measurementPoints[i]['x'].toDouble(),
        measurementPoints[i]['y'].toDouble(),
        size,
      );
      final point2 = _scalePoint(
        measurementPoints[i + 1]['x'].toDouble(),
        measurementPoints[i + 1]['y'].toDouble(),
        size,
      );

      canvas.drawLine(point1, point2, paint);
      canvas.drawCircle(point1, 4, dotPaint);
      canvas.drawCircle(point2, 4, dotPaint);

      // Draw measurement text
      final midPoint = Offset(
        (point1.dx + point2.dx) / 2,
        (point1.dy + point2.dy) / 2,
      );

      _drawMeasurementText(
        canvas,
        '${measurements['distances'][i].toStringAsFixed(1)} cm',
        midPoint,
      );
    }
  }

  Offset _scalePoint(double x, double y, Size size) {
    return Offset(
      (x * size.width) / imageSize.width,
      (y * size.height) / imageSize.height,
    );
  }

  void _drawMeasurementText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          backgroundColor: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw text background
    final rect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    canvas.drawRect(
      rect,
      Paint()..color = Colors.black54,
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
