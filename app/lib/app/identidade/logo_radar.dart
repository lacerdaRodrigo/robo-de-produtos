import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Símbolo da identidade V15: etiqueta de compra e três sinais de descoberta.
class LogoRadar extends StatelessWidget {
  const LogoRadar({
    super.key,
    this.tamanho = 64,
    this.sobreFundoEscuro = false,
    this.progresso = 0,
    this.rotuloSemantico,
  }) : assert(progresso >= 0 && progresso <= 1);

  final double tamanho;
  final bool sobreFundoEscuro;
  final double progresso;
  final String? rotuloSemantico;

  @override
  Widget build(BuildContext context) {
    final desenho = SizedBox.square(
      dimension: tamanho,
      child: CustomPaint(
        painter: PintorLogoRadar(
          sobreFundoEscuro: sobreFundoEscuro,
          progresso: progresso,
        ),
      ),
    );
    if (rotuloSemantico == null) return ExcludeSemantics(child: desenho);
    return Semantics(
      image: true,
      label: rotuloSemantico,
      excludeSemantics: true,
      child: desenho,
    );
  }
}

@visibleForTesting
class PintorLogoRadar extends CustomPainter {
  const PintorLogoRadar({required this.sobreFundoEscuro, this.progresso = 0});

  final bool sobreFundoEscuro;
  final double progresso;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = math.min(size.width, size.height) / 64;
    final cor = sobreFundoEscuro ? Tokens.acaoEscura : Tokens.action;
    canvas.save();
    canvas.translate(
      (size.width - (64 * escala)) / 2,
      (size.height - (64 * escala)) / 2,
    );
    canvas.scale(escala);

    final etiqueta = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(9, 17)
      ..cubicTo(9, 12.58, 12.58, 9, 17, 9)
      ..lineTo(36, 9)
      ..cubicTo(38.12, 9, 40.16, 9.84, 41.66, 11.34)
      ..lineTo(57, 26.68)
      ..cubicTo(60.9, 30.58, 60.9, 33.38, 57, 37.28)
      ..lineTo(37.28, 57)
      ..cubicTo(33.38, 60.9, 30.58, 60.9, 26.68, 57)
      ..lineTo(11.34, 41.66)
      ..cubicTo(9.84, 40.16, 9, 38.12, 9, 36)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(28, 23), radius: 5));
    canvas.drawPath(etiqueta, Paint()..color = cor);

    final sinais = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(32, 32);
    canvas.rotate(2 * math.pi * progresso);
    canvas.translate(-32, -32);
    canvas
      ..drawLine(const Offset(47, 8), const Offset(51, 4), sinais)
      ..drawLine(const Offset(55, 19), const Offset(60, 18), sinais)
      ..drawLine(const Offset(38, 5), const Offset(39, 2), sinais);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorLogoRadar oldDelegate) =>
      oldDelegate.sobreFundoEscuro != sobreFundoEscuro ||
      oldDelegate.progresso != progresso;
}
