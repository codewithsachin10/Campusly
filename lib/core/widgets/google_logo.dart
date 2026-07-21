import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Blue (#4285F4)
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(23.49, 12.27)
      ..cubicTo(23.49, 11.48, 23.42, 10.73, 23.3, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.51)
      ..lineTo(18.47, 14.51)
      ..cubicTo(18.18, 15.99, 17.33, 17.24, 16.08, 18.09)
      ..lineTo(16.08, 21.09)
      ..lineTo(19.94, 21.09)
      ..cubicTo(22.2, 19.01, 23.49, 15.92, 23.49, 12.27)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green (#34A853)
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 19.94, 21.09)
      ..lineTo(16.08, 18.09)
      ..cubicTo(15.0, 18.81, 13.62, 19.25, 12.0, 19.25)
      ..cubicTo(8.87, 19.25, 6.22, 17.14, 5.27, 14.29)
      ..lineTo(1.29, 14.29)
      ..lineTo(1.29, 17.38)
      ..cubicTo(3.26, 21.3, 7.31, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(5.27, 14.29)
      ..cubicTo(5.02, 13.57, 4.89, 12.8, 4.89, 12.0)
      ..cubicTo(4.89, 11.2, 5.02, 10.43, 5.27, 9.71)
      ..lineTo(5.27, 6.62)
      ..lineTo(1.29, 6.62)
      ..cubicTo(0.47, 8.24, 0.0, 10.06, 0.0, 12.0)
      ..cubicTo(0.0, 13.94, 0.47, 15.76, 1.29, 17.38)
      ..lineTo(5.27, 14.29)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red (#EA4335)
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(12.0, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.6, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.96, 1.21, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.31, 0.0, 3.26, 2.7, 1.29, 6.62)
      ..lineTo(5.27, 9.71)
      ..cubicTo(6.22, 6.86, 8.87, 4.75, 12.0, 4.75)
      ..close();
    canvas.drawPath(redPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
