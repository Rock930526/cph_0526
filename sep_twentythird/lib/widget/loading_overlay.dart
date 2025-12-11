import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingOverlay {
  static void show(BuildContext context, {String message = "AI 病灶分析中…"}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const _MedicalLoadingWidget();
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _MedicalLoadingWidget extends StatefulWidget {
  const _MedicalLoadingWidget();

  @override
  State<_MedicalLoadingWidget> createState() => _MedicalLoadingWidgetState();
}

class _MedicalLoadingWidgetState extends State<_MedicalLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctr;

  @override
  void initState() {
    super.initState();
    _ctr = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctr,
              builder: (_, __) {
                return CustomPaint(
                  painter: _PulsePainter(_ctr.value),
                  size: const Size(120, 120),
                );
              },
            ),
            const SizedBox(height: 25),
            const Text(
              "AI 正在分析皮膚病灶…",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "請稍候片刻",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;

  _PulsePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.cyanAccent, Colors.blueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final radius = size.width / 2 * (0.6 + progress * 0.3);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );

    // 中心光點
    final dotPaint = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      5 + progress * 3,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
