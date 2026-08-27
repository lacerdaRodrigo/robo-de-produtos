# `app/` — Flutter (Web, Android e iOS)

Cliente multiplataforma do **Radar de Benefícios**. Atende Web, Android e iOS com
o mesmo código, consumindo somente a API arquivada em `../backend/api/`.

> **Estado atual:** as Fases 0 a 5 do piloto estão implementadas e a API da Fase 5
> já foi publicada. Autenticação, painéis de leitura e administração usam a API
> (sem prefixo de versão, por domínio).
> O redesign por telas está em andamento: identidade, abertura, login responsivo e
> a nova moldura receberam aceite no Samsung conectado; os Módulos 3 a 6 (Início,
> hub de Lojas, Shopping Inter e Produtos/histórico) estão implementados. Web e iOS
> ainda precisam de aceite visual. O plano técnico está em [`PLANO.md`](PLANO.md) e a
> ordem visual por telas em [`PLANO-REDESIGN-POR-TELAS.md`](PLANO-REDESIGN-POR-TELAS.md).

## Plataformas e identificadores

- projeto Firebase: `radarbeneficios`;
- Android `applicationId`: `br.com.radarbeneficios.app`;
- iOS bundle ID: `br.com.radarbeneficios.app`;
-