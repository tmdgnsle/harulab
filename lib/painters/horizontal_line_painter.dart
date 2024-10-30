import 'package:flutter/material.dart';

double? topLineY;
double? bottomLineY;

class HorizontalLinesPainter extends CustomPainter {
  final bool isInPosition;

  HorizontalLinesPainter({this.isInPosition = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isInPosition ? Colors.green : Colors.red
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    // 첫 번째 수평선 (화면의 상단 5% 지점)
    topLineY = 5 * size.height / 100;
    canvas.drawLine(
      Offset(0, topLineY!),
      Offset(size.width, topLineY!),
      paint,
    );

    // 두 번째 수평선 (화면의 하단 5% 지점)
    bottomLineY = 95 * size.height / 100;
    canvas.drawLine(
      Offset(0, bottomLineY!),
      Offset(size.width, bottomLineY!),
      paint,
    );

  }

  @override
  bool shouldRepaint(covariant HorizontalLinesPainter oldDelegate) {
    return isInPosition != oldDelegate.isInPosition;
  }
}
