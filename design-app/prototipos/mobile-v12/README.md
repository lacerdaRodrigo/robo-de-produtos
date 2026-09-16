# Protótipo HTML mobile V12

Protótipo navegável, responsivo e autocontido do Radar de Benefícios. Ele
representa a nova direção visual `Delta` e cobre o fluxo
autenticado desde login até ajuda, privacidade, suporte e administração.

## Executar localmente

Na pasta deste arquivo, rode um servidor HTTP simples:

```bash
python3 -m http.server 8765
```

Depois abra `http://127.0.0.1:8765/` no navegador. O uso de servidor é
necessário porque os módulos JavaScript usam `import` nativo.

## Organização

- `index.html`: casca mínima e pontos de montagem.
- `css/tokens.css`: cores, tipografia, espaçamento, raios, sombras e motion.
- `css/base.css`: reset, acessibilidade e layouts responsivos.
- `css/components.css`: componentes reutilizáveis.
- `css/screens.css`: composição específica das telas.
- `css/delta.css`: sistema visual ativo da direção Delta, carregado por último
  para manter tokens e componentes coerentes em todas as telas.
- `js/data.js`: dados ilustrativos, sem chamada externa.
- `js/state.js`: sessão, tema, filtros, abas, paginação e overlays.
- `js/router.js`: roteamento por hash e proteção da área autenticada.
- `js/components.js` e `js/components/`: primitivas de UI reaproveitáveis e
  ponto de exportação modular.
- `js/screens.js` e `js/screens/`: montagem das telas, estados e ponto de
  exportação modular.
- `js/app.js`: eventos, formulários e transições do protótipo.
- `assets/icons.svg`: reserva de ícones vetoriais locais para evolução do
  protótipo; a primeira versão usa ícones inline para facilitar a troca de
  estado e manter acessibilidade.
- `assets/favicon.svg`: marca local usada pelo navegador, sem dependência
  remota.

## Fluxo rápido

1. Abra `#/abertura` e entre no app.
2. Use qualquer e-mail válido e uma senha com pelo menos quatro caracteres.
3. Escolha permitir ou negar push; as duas opções chegam ao Resumo.
4. Abra `#/laboratorio` para visitar todas as rotas, alternar tema, papel e
   estados de dados.

As rotas e regras de produto estão descritas em
[`../../guias/MATRIZ-TELAS-MOBILE-V12.md`](../../guias/MATRIZ-TELAS-MOBILE-V12.md).
Os dados são deliberadamente ilustrativos: nenhuma ação deste protótipo
altera API, banco, conta, coletor ou dados de produção.
