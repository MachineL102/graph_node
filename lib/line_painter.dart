import 'package:vector_math/vector_math.dart' as vector_math;
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LineSegment {
  final vector_math.Vector2 start;
  final vector_math.Vector2 end;

  LineSegment(this.start, this.end);
}

class Rectangle {
  final double width;
  final double height;

  Rectangle(this.width, this.height);
}

LineSegment calculateAvoidingRectangle(
  vector_math.Vector2 startPoint,
  Rectangle startRect,
  vector_math.Vector2 endPoint,
  Rectangle endRect,
) {
  // result
  vector_math.Vector2 r1 = vector_math.Vector2(.0, .0);
  vector_math.Vector2 r2 = vector_math.Vector2(.0, .0);
  // 计算线段的斜率
  double slope = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
  double k1 = -startRect.height / startRect.width;
  double k2 = -k1;

  // 计算矩形的四条边的方程
  double startX1 = startPoint.x - startRect.width / 2;
  double startY1 = startPoint.y - startRect.height / 2;
  double startX2 = startPoint.x + startRect.width / 2;
  double startY2 = startPoint.y + startRect.height / 2;

  double endX1 = endPoint.x - endRect.width / 2;
  double endY1 = endPoint.y - endRect.height / 2;
  double endX2 = endPoint.x + endRect.width / 2;
  double endY2 = endPoint.y + endRect.height / 2;

  //
  double b1 = startY1 - k1 * startX1;
  double b2 = startY2 - k2 * startX2;

  double v1 = k1 * endPoint[0] + b1 - endPoint[1];
  double v2 = k2 * endPoint[0] + b2 - endPoint[1];
  if ((v1) > 0 && (v2) > 0) {
    r1[1] = startY1;
    r1[0] = endPoint.x - (endPoint.y - r1[1]) / slope;
  } else if ((v1) > 0 && (v2) < 0) {
    r1[0] = startX1;
    r1[1] = endPoint.y - (endPoint.x - r1[0]) * slope;
  } else if ((v1) < 0 && (v2) > 0) {
    r1[0] = startX2;
    r1[1] = endPoint.y - (endPoint.x - r1[0]) * slope;
  } else if ((v1) < 0 && (v2) < 0) {
    r1[1] = startY2;
    r1[0] = endPoint.x - (endPoint.y - r1[1]) / slope;
  }

  //
  k1 = -endRect.height / endRect.width;
  k2 = -k1;
  b1 = endY1 - k1 * endX1;
  b2 = endY2 - k2 * endX2;

  double v3 = k1 * startPoint[0] + b1 - startPoint[1];
  double v4 = k2 * startPoint[0] + b2 - startPoint[1];
  if ((v3) > 0 && (v4) > 0) {
    r2[1] = endY1;
    r2[0] = endPoint.x - (endPoint.y - r2[1]) / slope;
  } else if ((v3) > 0 && (v4) < 0) {
    r2[0] = endX1;
    r2[1] = endPoint.y - (endPoint.x - r2[0]) * slope;
  } else if ((v3) < 0 && (v4) > 0) {
    r2[0] = endX2;
    r2[1] = endPoint.y - (endPoint.x - r2[0]) * slope;
  } else if ((v3) < 0 && (v4) < 0) {
    r2[1] = endY2;
    r2[0] = endPoint.x - (endPoint.y - r2[1]) / slope;
  }

  // 返回线段
  return LineSegment(
    r1,
    r2,
  );
}

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
