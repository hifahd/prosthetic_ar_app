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

    // Check for measurement points
    if (!measurements.containsKey('points') || measurements['points'] == null) {
      return;
    }

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

      // Draw measurement text if distances are available
      if (measurements.containsKey('distances') && 
          measurements['distances'] != null &&
          measurements['distances'].length > i) {
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

    // Draw confidence and limb type
    if (measurements.containsKey('coordinates') && 
        measurements.containsKey('confidence') &&
        measurements.containsKey('limb_type')) {
      
      final x = measurements['coordinates']['x'].toDouble();
      final y = measurements['coordinates']['y'].toDouble();
      final position = _scalePoint(x, y, size);
      final confidence = measurements['confidence'].toDouble();
      final limbType = measurements['limb_type'].toString().replaceAll('_', ' ');
      
      // Draw indicator for the limb position
      canvas.drawCircle(position, 8, 
        Paint()..color = Colors.red.withOpacity(0.6)
      );
      
      // Draw text label with confidence
      _drawMeasurementText(
        canvas, 
        '$limbType (${(confidence * 100).toStringAsFixed(0)}%)',
        Offset(position.dx, position.dy - 20),
        fontSize: 16
      );
    }

    // Draw asymmetry info if available
    if (measurements.containsKey('asymmetry_data') && 
        measurements['asymmetry_data'] != null) {
      
      final asymmetryData = measurements['asymmetry_data'];
      final String asymmetryText = 'Asymmetry: ' + 
          '${(asymmetryData['hip_knee_asymmetry'] * 100).toStringAsFixed(1)}% Hip-Knee, ' +
          '${(asymmetryData['knee_ankle_asymmetry'] * 100).toStringAsFixed(1)}% Knee-Ankle';
      
      _drawMeasurementText(
        canvas,
        asymmetryText,
        Offset(size.width / 2, size.height - 40),
        fontSize: 14,
        backgroundColor: Colors.black.withOpacity(0.7)
      );
    }
  }

  Offset _scalePoint(double x, double y, Size size) {
    return Offset(
      (x * size.width) / imageSize.width,
      (y * size.height) / imageSize.height,
    );
  }

  void _drawMeasurementText(Canvas canvas, String text, Offset position, {double fontSize = 14, Color? backgroundColor}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw text background
    if (backgroundColor != null) {
      final rect = Rect.fromCenter(
        center: position,
        width: textPainter.width + 16,
        height: textPainter.height + 8,
      );
      canvas.drawRect(
        rect,
        Paint()..color = backgroundColor,
      );
    }

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}