import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Símbolo vetorial do Radar de Benefícios.
///
/// O desenho vive em código para manter a mesma geometria no Web, Android e
/// iOS sem acrescentar uma dependência de SVG ao aplicativo.
class LogoRadar extends StatelessWidget {
  const LogoRadar({
    super.key,
    this.tamanho = 112,
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

    if (rotuloSemantico == null) {
      return ExcludeSemantics(child: desenho);
    }
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
    final escala = math.min(size.width, size.height) / 512;
    canvas.save();
    canvas.translate(
      (size.width - (512 * escala)) / 2,
      (size.height - (512 * escala)) / 2,
    );
    canvas.scale(escala);

    final arco = Paint()
      ..color = sobreFundoEscuro ? const Color(0xFFC6E1F4) : Tokens.marca
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 44;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(256, 256), radius: 180),
      0.32,
      4.98,
      false,
      arco,
    );

    final feixe = Path()
      ..moveTo(256, 256)
      ..lineTo(348, 91)
      ..quadraticBezierTo(354, 80, 378, 84)
      ..lineTo(455, 132)
      ..quadraticBezierTo(467, 140, 454, 165)
      ..close();
    final tintaFeixe = Paint()
      ..shader = LinearGradient(
        colors: sobreFundoEscuro
            ? const [Color(0xFF4BA3E3), Color(0xFF55D5ED)]
            : const [Tokens.marcaClara, Color(0xFF25B8D8)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(const Rect.fromLTWH(256, 80, 212, 176));
    canvas.save();
    canvas.translate(256, 256);
    canvas.rotate(2 * math.pi * progresso);
    canvas.translate(-256, -256);
    canvas.drawPath(feixe, tintaFeixe);
    canvas.restore();

    final impacto = math
        .pow((math.cos(2 * math.pi * progresso) + 1) / 2, 4)
        .toDouble();
    final estrela = Path()
      ..moveTo(428, 50)
      ..quadraticBezierTo(434, 90, 474, 96)
      ..quadraticBezierTo(434, 102, 428, 142)
      ..quadraticBezierTo(422, 102, 382, 96)
      ..quadraticBezierTo(422, 90, 428, 50)
      ..close();
    final tintaEstrela = Paint()
      ..shader = LinearGradient(
        colors:
            (sobreFundoEscuro
                    ? const [Color(0xFF4ADE80), Color(0xFF22A34A)]
                    : const [Color(0xFF22A34A), Tokens.ganho])
                .map((cor) => cor.withValues(alpha: 0.38 + (0.62 * impacto)))
                .toList(),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(382, 50, 92, 92));
    final escalaEstrela = 0.88 + (0.12 * impacto);
    canvas.save();
    canvas.translate(428, 96);
    canvas.scale(escalaEstrela);
    canvas.translate(-428, -96);
    canvas.drawPath(estrela, tintaEstrela);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(PintorLogoRadar oldDelegate) =>
      oldDelegate.sobreFundoEscuro != sobreFundoEscuro ||
      oldDelegate.progresso != progresso;
}
