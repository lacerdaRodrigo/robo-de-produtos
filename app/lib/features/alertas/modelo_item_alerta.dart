import '../../core/api/modelos.dart';
import '../pichau/modelos_pichau.dart';

enum OrigemItemAlerta { livelo, interCashback, interProduto, pichau }

/// Item atual associado ao alerta, sem consultar o catálogo inteiro.
///
/// Os campos são lidos pelos parsers já usados nas respectivas telas de
/// catálogo. Valores comerciais continuam como texto nos DTOs de origem.
class ItemResolvidoAlerta {
  const ItemResolvidoAlerta({required this.origem, required this.item});

  factory ItemResolvidoAlerta.parse(Map<String, dynamic> objeto) {
    final origem = switch (objeto['origem']) {
      'livelo' => OrigemItemAlerta.livelo,
      'inter_cashback' => OrigemItemAlerta.interCashback,
      'inter_produto' => OrigemItemAlerta.interProduto,
      'pichau' => OrigemItemAlerta.pichau,
      _ => throw const FormatException('Origem do item de alerta inválida.'),
    };
    final bruto = objeto['item'];
    if (bruto is! Map<String, dynamic> || bruto.isEmpty) {
      throw const FormatException('Item de alerta inválido.');
    }
    final item = switch (origem) {
      OrigemItemAlerta.livelo => ParceiroCatalogoLivelo.parse(bruto),
      OrigemItemAlerta.interCashback => CashbackInter.parse(bruto),
      OrigemItemAlerta.interProduto => ProdutoDireto.parse(bruto),
      OrigemItemAlerta.pichau => PichauProduto.parse(bruto),
    };
    return ItemResolvidoAlerta(origem: origem, item: item);
  }

  final OrigemItemAlerta origem;
  final Object item;
}
