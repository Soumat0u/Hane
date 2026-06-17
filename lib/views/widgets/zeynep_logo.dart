import 'package:flutter/material.dart';


import 'package:hane/theme/app_theme.dart';
class ZeynepLogo extends StatelessWidget {
  const ZeynepLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: LogoPainter(brandColor: Theme.of(context).extension<AppColors>()!.brand),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ZEYNEP',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A9BD5),
                  letterSpacing: 2,
                  height: 1.1,
                ),
              ),
              Text(
                'İNŞAAT FİNANS PANELİ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF032B5E),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  final Color brandColor;
  const LogoPainter({required this.brandColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftPath = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.32, h)
      ..lineTo(w * 0.32, h * 0.2)
      ..lineTo(0, h * 0.42)
      ..close();

    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF021B3A),
          brandColor,
          const Color(0xFF5A9BD5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.32, h));
    canvas.drawPath(leftPath, leftPaint);

    final midPath = Path()
      ..moveTo(w * 0.38, h)
      ..lineTo(w * 0.68, h)
      ..lineTo(w * 0.68, h * 0.12)
      ..lineTo(w * 0.38, 0)
      ..close();

    final midPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          brandColor,
          const Color(0xFF94A3B8),
        ],
      ).createShader(Rect.fromLTWH(w * 0.38, 0, w * 0.3, h));
    canvas.drawPath(midPath, midPaint);

    final rightPath = Path()
      ..moveTo(w * 0.74, h)
      ..lineTo(w * 1.0, h)
      ..lineTo(w * 1.0, h * 0.35)
      ..lineTo(w * 0.74, h * 0.18)
      ..close();

    final rightPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(rightPath, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
