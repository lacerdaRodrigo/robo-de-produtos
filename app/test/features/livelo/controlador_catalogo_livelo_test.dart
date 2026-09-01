import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/livelo/controlador_catalogo_livelo.dart';

ParceiroCatalogoLivelo parceiro(
  String id, {
  String? nome,
  bool acompanhada = false,
  bool alerta = false,
  bool alertaAtivo = false,
}) => ParceiroCatalogoLivelo(
  idExterno: id,
  nome: nome ?? 'Loja $id',
  categorias: const ['Marketplace'],
  pontosAtuais: '2.90',
  pontosAnteriores: null,
  pontosBase: '1.00',
  pontosClube: null,
  moeda: 'R\$',
  prefixoAte: false,
  emPromocao: true,
  campanha: 'PROMOTION',
  descricaoCampanha: null,
  inicioPromocao: null,
  fimPromocao: null,
  acompanhada: acompanhada,
  alertaAtivo: alertaAtivo,
  alerta: alerta,
);

ResumoCatalogoLivelo resumo({
  int acompanhadas = 0,
  int alertas = 0,
  String ultimaColeta = '2026-08-28T12:00:00Z',
  String? ultimaTentativaEm,
  String? qualidade = 'completa',
}) => ResumoCatalogoLivelo(
  ultimaColeta: ultimaColeta,
  ultimaTentativaEm: ultimaTentativaEm ?? ultimaColeta,
  qualidade: qualidade,
  parceirosLidos: 252,
  totalCatalogo: 252,
  acompanhadas: acompanhadas,
  alertas: alertas,
  melhorOferta: const MelhorOfertaLivelo(
    idExterno: 'MELHOR',
    nome: 'Melhor Loja',
    pontosAtuais: '12',
    moeda: 'R\$',
    prefixoAte: false,
  ),
);

PaginaCatalogoLivelo montarPagina(
  List<ParceiroCatalogoLivelo> itens, {
  int numero = 1,
  int? total,
  bool proxima = false,
  ResumoCatalogoLivelo? resumoDaPagina,
}) => PaginaCatalogoLivelo(
  itens: itens,
  resumo: resumoDaPagina ?? resumo(),
  categorias: const ['Marketplace', 'Viagem'],
  pagina: numero,
  porPagina: 20,
  totalItens: total ?? itens.length,
  totalPaginas: proxima ? numero + 1 : numero,
  temProxima: proxima,
);

void main() {
  test('atualização silenciosa distingue retrato, sucesso e falha', () async {
    var momento = '2026-08-28T12:00:00Z';
    var tentativa = momento;
    var qualidade = 'completa';
    var falhar = false;
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async {
            if (falhar) throw StateError('sem rede');
            return montarPagina(
              [parceiro('A')],
              resumoDaPagina: resumo(
                ultimaColeta: momento,
                ultimaTentativaEm: tentativa,
                qualidade: qualidade,
              ),
            );
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);

    await controlador.carregarInicial();
    expect(
      await controlador.atualizarSilenciosamente(),
      ResultadoAtualizacaoSilenciosa.inalterada,
    );

    momento = '2026-08-28T12:05:00Z';
    expect(
      await controlador.atualizarSilenciosamente(),
      ResultadoAtualizacaoSilenciosa.alterada,
    );
    expect(controlador.resumo?.ultimaColeta, momento);

    tentativa = '2026-08-28T12:10:00Z';
    qualidade = 'degradada';
    expect(
      await controlador.atualizarSilenciosamente(),
      ResultadoAtualizacaoSilenciosa.degradada,
    );
    expect(controlador.resumo?.ultimaColeta, momento);
    expect(controlador.resumo?.qualidade, 'degradada');

    falhar = true;
    expect(
      await controlador.atualizarSilenciosamente(),
      ResultadoAtualizacaoSilenciosa.falha,
    );
  });

  test('pagina, filtros e deduplicação usam o ID externo', () async {
    final consultas = <String>[];
    final controlador = ControladorCatalogoLivelo(
      debounce: Duration.zero,
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async {
            consultas.add('$q/$aba/$categoria/$ordenar/$pagina');
            if (pagina == 1) {
              return montarPagina(
                [parceiro('A'), parceiro('B')],
                total: 3,
                proxima: true,
              );
            }
            return montarPagina(
              [parceiro('B'), parceiro('C')],
              numero: 2,
              total: 3,
            );
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);

    await controlador.carregarInicial();
    await controlador.carregarMais();
    expect(controlador.itens.map((item) => item.idExterno), ['A', 'B', 'C']);

    await controlador.mudarAba(AbaCatalogoLivelo.acompanhadas);
    await controlador.mudarCategoria('Viagem');
    expect(consultas.last, '/acompanhadas/Viagem/pontos/1');
  });

  test('debounce descarta resposta antiga', () async {
    final antiga = Completer<PaginaCatalogoLivelo>();
    final controlador = ControladorCatalogoLivelo(
      debounce: const Duration(milliseconds: 10),
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) => q.isEmpty
          ? antiga.future
          : Future.value(
              PaginaCatalogoLivelo(
                itens: [parceiro('NOVA')],
                resumo: resumo(),
                categorias: const [],
                pagina: 1,
                porPagina: 20,
                totalItens: 1,
                totalPaginas: 1,
                temProxima: false,
              ),
            ),
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);

    unawaited(controlador.carregarInicial());
    controlador.mudarBusca('nova');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    antiga.complete(montarPagina([parceiro('ANTIGA')]));
    await Future<void>.delayed(Duration.zero);

    expect(controlador.itens.single.idExterno, 'NOVA');
  });

  test('mutação preserva filtros e desfaz visualmente quando falha', () async {
    var falhar = false;
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async => montarPagina([parceiro('A')], resumoDaPagina: resumo()),
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {
            if (falhar) throw StateError('sem rede');
          },
    );
    addTearDown(controlador.dispose);

    await controlador.carregarInicial();
    expect(
      await controlador.alternarAcompanhamento(controlador.itens.single),
      isTrue,
    );
    expect(controlador.itens.single.acompanhada, isTrue);
    expect(controlador.resumo!.acompanhadas, 1);

    falhar = true;
    expect(
      await controlador.alternarAcompanhamento(controlador.itens.single),
      isFalse,
    );
    expect(controlador.itens.single.acompanhada, isTrue);
    expect(controlador.resumo!.acompanhadas, 1);
    expect(controlador.busca, isEmpty);
    expect(controlador.aba, AbaCatalogoLivelo.lojas);
  });

  test('duplo toque não envia duas mutações', () async {
    final pendente = Completer<void>();
    var chamadas = 0;
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async => montarPagina([parceiro('A')]),
      alterarAcompanhamento: ({required idExterno, required acompanhada}) {
        chamadas++;
        return pendente.future;
      },
    );
    addTearDown(controlador.dispose);
    await controlador.carregarInicial();

    final primeira = controlador.alternarAcompanhamento(
      controlador.itens.single,
    );
    expect(
      await controlador.alternarAcompanhamento(controlador.itens.single),
      isFalse,
    );
    pendente.complete();
    expect(await primeira, isTrue);
    expect(chamadas, 1);
  });
}
