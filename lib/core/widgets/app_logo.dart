import 'package:flutter/material.dart';

/// AppLogo
/// Reusable brand logo component for Phone Parts Finder.
/// Renders the logo image asset with fallback vector graphics.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container / Squircle Badge
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(iconSize * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff00E5FF).withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: const Color(0xff00E5FF).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(iconSize * 0.28),
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => CustomPaint(
                painter: _LogoPainter(),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: iconSize * 0.12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'PP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: iconSize * 0.32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                        Text(
                          'F',
                          style: TextStyle(
                            color: const Color(0xff00E5FF),
                            fontSize: iconSize * 0.32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        if (showText) ...[
          SizedBox(height: iconSize * 0.2),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                fontFamily: 'Roboto',
                letterSpacing: 0.5,
              ),
              children: [
                const TextSpan(
                  text: 'Phone Parts ',
                  style: TextStyle(color: Colors.white),
                ),
                const TextSpan(
                  text: 'Find',
                  style: TextStyle(color: Colors.grey),
                ),
                const TextSpan(
                  text: 'e',
                  style: TextStyle(color: Color(0xff00E5FF)),
                ),
                const TextSpan(
                  text: 'r',
                  style: TextStyle(color: Colors.grey),
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
  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = const Color(0xff00E5FF)
      ..strokeWidth = size.width * 0.06
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0xff00E5FF)
      ..style = PaintingStyle.fill;

    // Cyan arc at bottom under text
    final path = Path();
    path.moveTo(size.width * 0.18, size.height * 0.72);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.58,
      size.width * 0.82,
      size.height * 0.72,
    );
    canvas.drawPath(path, arcPaint);

    // Cyan dot above F
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.24),
      size.width * 0.05,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
