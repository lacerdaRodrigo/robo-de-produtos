import '../../core/api/modelos.dart';

String formatarValorAlerta(String valor, TipoAlertaApp tipo) {
  if (tipo != TipoAlertaApp.preco) return valor;

  final entrada = valor.trim();
  final partes = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$').firstMatch(entrada);
  if (partes == null) return valor;

  final sinal = partes.group(1)!;
  var inteiro = partes.group(2)!;
  final fracao = partes.group(3) ?? '';
  while (inteiro.length > 1 && inteiro.startsWith('0')) {
    inteiro = inteiro.substring(1);
  }

  var centavos = '${fracao}00'.substring(0, 2);
  if (fracao.length > 2 && fracao[2].compareTo('5') >= 0) {
    final arredondado = _incrementarDigitos(centavos);
    if (arredondado.length > 2) {
      centavos = '00';
      inteiro = _incrementarDigitos(inteiro);
    } else {
      centavos = arredondado.padLeft(2, '0');
    }
  }

  return '${sinal}R\$ ${_agruparMilhares(inteiro)},$centavos';
}

String _incrementarDigitos(String valor) {
  final digitos = valor.split('');
  for (var indice = digitos.length - 1; indice >= 0; indice--) {
    if (digitos[indice] == '9') {
      digitos[indice] = '0';
      continue;
    }
    digitos[indice] = String.fromCharCode(digitos[indice].codeUnitAt(0) + 1);
    return digitos.join();
  }
  return '1${digitos.join()}';
}

String _agruparMilhares(String valor) {
  final resultado = StringBuffer();
  for (var indice = 0; indice < valor.length; indice++) {
    if (indice > 0 && (valor.length - indice) % 3 == 0) {
      resultado.write('.');
    }
    resultado.write(valor[indice]);
  }
  return resultado.toString();
}
