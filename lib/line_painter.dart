import 'dart:ffi';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class LinePainter extends CustomPainter {
  final ui.Size startPoint;
  final ui.Size endPoint;
  final bool directed;
  // Constructor to initialize the startPoint and endPoint
  LinePainter(
      {required this.startPoint,
      required this.endPoint,
      required this.directed});
  @override
  void paint(Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..color = Colors.black // Adjust the color of the line
      ..strokeWidth = 1; // Adjust the thickness of the line

    canvas.drawLine(
      Offset(startPoint.width, startPoint.height), // Start point
      Offset(endPoint.width, endPoint.height),
      paint,
    );
    if (directed) {
      final dX = endPoint.width - startPoint.width;
      final dY = endPoint.height - startPoint.height;
      final angle = math.atan2(dY, dX);
      final arrowSize = 15;
      final arrowAngle = 25 * math.pi / 180;
      final path = Path();

      path.moveTo(endPoint.width - arrowSize * math.cos(angle - arrowAngle),
          endPoint.height - arrowSize * math.sin(angle - arrowAngle));
      path.lineTo(endPoint.width, endPoint.height);
      path.lineTo(endPoint.width - arrowSize * math.cos(angle + arrowAngle),
          endPoint.height - arrowSize * math.sin(angle + arrowAngle));
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
