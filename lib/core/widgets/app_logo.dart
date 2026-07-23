import 'package:flutter/material.dart';

/// AppLogo
/// Reusable brand logo component for Phone Parts Finder.
/// Renders the logo image asset with fallback vector graphics cleanly aligned with theme.
class AppLogo extends StatelessWidget {
  final double iconSize;
  final bool showText;
  final double fontSize;

  const AppLogo({
    super.key,
    this.iconSize = 80,
    this.showText = true,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container / Squircle Badge
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(iconSize * 0.28),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(iconSize * 0.28),
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CustomPaint(
                painter: _LogoPainter(color: Colors.white),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: iconSize * 0.12),
                    child: Text(
                      'PPF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: iconSize * 0.32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (showText) ...[
          SizedBox(height: iconSize * 0.18),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
              children: [
                const TextSpan(
                  text: 'Phone Parts ',
                  style: TextStyle(color: Color(0xff0F172A)),
                ),
                TextSpan(
                  text: 'Finder',
                  style: TextStyle(color: primaryColor),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = size.width * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.18, size.height * 0.76);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.64,
      size.width * 0.82,
      size.height * 0.76,
    );
    canvas.drawPath(path, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
