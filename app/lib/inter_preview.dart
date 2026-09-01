import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app/navegacao/moldura.dart';
import 'app/tema/tema.dart';
import 'core/api/api.dart';
import 'core/api/cliente.dart';

void main() {
  final api = Api(
    paginaPadrao: 20,
    cliente: ClienteApi(
      baseUrl: 'http://preview.local',
      provedorToken: () async => 'preview',
      cliente: _ClientePreview(),
    ),
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TemaRadar.claro(),
      darkTheme: TemaRadar.escuro(),
      home: MolduraRadar(
        api: api,
        administrador: true,
        agora: () => DateTime(2026, 8, 29),
      ),
    ),
  );
}

class _ClientePreview extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = switch (request.url.path) {
      '/api/status' => '{"api":"v1","saudavel":true}',
      '/api/resumo' => _resumo,
      '/api/inter/cashback' => _cashback,
      '/api/inter/lojas' => _sites,
      _ => _paginaVazia,
    };
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      headers: const {'content-type': 'application/json'},
    );
  }
}

const _paginaVazia =
    '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,'
    '"total_paginas":1,"tem_proxima":false,"atualizado_em":null}';

const _resumo =
    '{"gerado_em":"2026-08-29T20:20:00Z","estado_geral":"atualizado",'
    '"livelo":{"estado":"atualizado","ultimo_sucesso_em":"2026-08-29T20:10:00Z",'
    '"lojas_acompanhadas":3,"alertas_ultima_coleta":2},'
    '"cashback_inter":{"estado":"atualizado",'
    '"ultima_tentativa_em":"2026-08-29T20:00:00Z",'
    '"ultima_tentativa_estado":"sucesso","ultimo_sucesso_em":"2026-08-29T20:00:00Z",'
    '"lojas_acompanhadas":3,"lojas_encontradas_ultima_coleta":3},'
    '"produtos":{"estado":"atualizado",'
    '"ultima_tentativa_em":"2026-08-29T20:00:00Z",'
    '"ultima_tentativa_estado":"sucesso","dados_mais_antigos_em":"2026-08-29T19:00:00Z",'
    '"dados_mais_recentes_em":"2026-08-29T20:00:00Z","qualidade":"completa",'
    '"lojas_selecionadas":1,"lojas_sem_coleta":0,"produtos_ativos":15}}';

const _cashback =
    '{"itens":['
    '{"id":"magalu","slug":"magalu","nome":"Magazine Luiza",'
    '"cashback_principal_texto":"até 20%","cashback_principal_valor":"20.00",'
    '"cashback_secundario_texto":null,"cashback_secundario_valor":null,'
    '"etiqueta":null,"descricao_principal":null,"descricao_secundaria":null,'
    '"encontrada":true,"favorita":true,'
    '"link":"https://shopping.inter.co/site-parceiro/lojas"},'
    '{"id":"riachuelo","slug":"riachuelo","nome":"Riachuelo",'
    '"cashback_principal_texto":"até 15%","cashback_principal_valor":"15.00",'
    '"cashback_secundario_texto":null,"cashback_secundario_valor":null,'
    '"etiqueta":null,"descricao_principal":null,"descricao_secundaria":null,'
    '"encontrada":true,"favorita":false,'
    '"link":"https://shopping.inter.co/site-parceiro/lojas"}],'
    '"pagina":1,"por_pagina":20,"total_itens":2,"total_paginas":1,'
    '"tem_proxima":false,"atualizado_em":"2026-08-29T20:00:00Z"}';

const _sites =
    '{"itens":[{"id":"magalu","id_externo":"1","slug":"magalu",'
    '"nome":"Magazine Luiza","cashback_principal_texto":"até 20%",'
    '"cashback_principal_valor":"20.00","ativa":true,"favorita":true}],'
    '"pagina":1,"por_pagina":20,"total_itens":382,"total_paginas":20,'
    '"tem_proxima":true,"atualizado_em":null}';
