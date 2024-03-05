import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class LinePainter extends CustomPainter {
  final ui.Size startPoint;
  final ui.Size endPoint;

  // Constructor to initialize the startPoint and endPoint
  LinePainter({required this.startPoint, required this.endPoint});
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

