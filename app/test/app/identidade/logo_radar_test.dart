import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/identidade/logo_radar.dart';

void main() {
  testWidgets('logo expõe o nome da marca quando recebe rótulo', (at) async {
    final semantica = at.ensureSemantics();

    await at.pumpWidget(
      const MaterialApp(
        home: Center(child: LogoRadar(rotuloSemantico: 'Radar de Benefícios')),
      ),
    );

    expect(find.bySemanticsLabel('Radar de Benefícios'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('variantes clara e sobre fundo escuro permanecem vetoriais', (
    at,
  ) async {
    await at.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            LogoRadar(key: Key('logo-claro')),
            LogoRadar(key: Key('logo-escuro'), sobreFundoEscuro: true),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('logo-claro')), findsOneWidget);
    expect(find.byKey(const Key('logo-escuro')), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is PintorLogoRadar,
      ),
      findsNWidgets(2),
    );
  });

  test('pintor só repinta quando a variante muda', () {
    const claro = PintorLogoRadar(sobreFundoEscuro: false);
    const outroClaro = PintorLogoRadar(sobreFundoEscuro: false);
    const escuro = PintorLogoRadar(sobreFundoEscuro: true);
    const varredura = PintorLogoRadar(sobreFundoEscuro: false, progresso: 0.5);

    expect(claro.shouldRepaint(outroClaro), isFalse);
    expect(claro.shouldRepaint(escuro), isTrue);
    expect(claro.shouldRepaint(varredura), isTrue);
  });
}
