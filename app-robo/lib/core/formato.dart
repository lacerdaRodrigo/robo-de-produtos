/// Formatação monetária e numérica pt-BR.
///
/// Regra herdada do PRD 5.4 e da RNF20/RNF29 (PLANO §3.2): o valor monetário
/// nunca passa por `double`. Do Postgres ele chega como string (NUMERIC); o
/// Flutter recebe a mesma string da API e a formata sem converter para ponto
/// flutuante — evita o "2,9000000000000004" que o robô já evita com Decimal.
library;

/// Formata uma string decimal em moeda pt-BR.
///
/// - `null` ou vazio → `null` (ausência é estado válido, nunca vira "R$ 0,00").
/// - A entrada é sempre a string crua do banco/API; nada de `double`.
String? moeda(String? valor) {
  if (valor == null || valor.isEmpty) {
    return null;
  }
  final partes = valor.split('.');
  final inteiro = partes[0];
  final fracao = partes.length > 1 ? partes[1] : '';
  final cru = '${fracao}00';
  final decimal = cru.substring(0, 2);

  var comPonto = inteiro;
  if (inteiro.length > 3) {
    comPonto = _agrupar(inteiro);
  }
  return 'R\$ $comPonto,$decimal';
}

/// Agrupa os dígitos do inteiro em grupos de três, separados por ponto
/// (milhar) e mantendo a ordem original.
String _agrupar(String inteiro) {
  final resultado = StringBuffer();
  final n = inteiro.length;
  for (var i = 0; i < n; i++) {
    if (i > 0 && (n - i) % 3 == 0) {
      resultado.write('.');
    }
    resultado.write(inteiro[i]);
  }
  return resultado.toString();
}

/// Converte `true`/`false`/`1`/`0` vindos da API para boleano.
///
/// Textos externos são hostis; um valor fora do esperado vira `false` em vez
/// de quebrar a tela com exceção.
bool boleano(Object? valor) {
  if (valor is bool) {
    return valor;
  }
  final texto = valor?.toString().trim().toLowerCase() ?? '';
  return texto == 'true' || texto == '1' || texto == 'on';
}
