# PRD V5 — Limpeza administrativa por domínio

**Versão:** V5.0 — planejamento  
**Status:** implementado no site; aceite destrutivo em banco descartável pendente

> A V5 adiciona uma operação administrativa destrutiva ao Radar de Benefícios. Ela não coleta uma nova fonte e não muda as regras dos robôs: permite apagar separadamente os dados da Livelo ou resetar todos os dados do Shopping Inter, sempre dentro da área autenticada.

Este documento é um delta sobre PRD.md, PRD-V2.md, PRD-V3.md e PRD-V4.md. Tudo que não for redefinido aqui continua valendo.

---

## 1. Contexto e objetivo

O banco Neon reúne três conjuntos independentes:

| Domínio | Conteúdo | Área relacionada |
|---|---|---|
| Livelo | lojas, regras, execuções e pontuações | Painel e Lojas |
| Inter — Sites parceiros | catálogo, favoritas, execuções e cashback | /inter |
| Inter — Compre direto | vendedores, produtos e medições | /inter/produtos |

A V5 cria dois fluxos explícitos:

1. **Apagar dados da Livelo**.
2. **Resetar dados do Inter**, cobrindo Sites parceiros e Compre direto.

O objetivo é permitir recomeçar uma integração sem apagar autenticação, preferências visuais ou dados de outra integração.

## 2. Escopo

### 2.1 Dentro

- Zona de perigo em Configurações, visível somente com sessão.
- Dois botões independentes, com confirmação em página separada.
- Prévia das contagens atuais antes da confirmação.
- Frase obrigatória validada no servidor.
- Uma transação atômica para cada domínio.
- Mensagem de sucesso, erro controlado e revalidação das páginas afetadas.
- Testes com banco descartável e regressão das suítes existentes.

### 2.2 Fora

- Backup, exportação ou restauração pelo aplicativo.
- Auditoria persistente da limpeza.
- Exclusão da sessão, tentativas de login, tema ou flags de interface.
- Pausa ou cancelamento dos workflows agendados e disparos manuais.
- Exclusão de tabelas, migrações ou schema do Postgres.
- Limpeza automática por prazo.

## 3. Requisitos funcionais

| ID | Requisito |
|---|---|
| RF50 | Mostrar em Configurações ações separadas para Livelo e Inter |
| RF51 | Exigir sessão na confirmação e na Server Action |
| RF52 | Mostrar contagens do domínio antes da confirmação |
| RF53 | Exigir APAGAR LIVELO ou RESETAR INTER, conforme o fluxo |
| RF54 | Executar cada limpeza como transação única, com rollback em falha |
| RF55 | Revalidar páginas públicas e administrativas após sucesso |
| RF56 | Permitir repetir a limpeza de um domínio já vazio |
| RF57 | Manter workflows agendados e disparos manuais operacionais |

## 4. Dados afetados

### 4.1 Livelo

Usar uma lista fixa de tabelas em TRUNCATE ... RESTART IDENTITY, sem cascade genérico:

    pontuacao
    execucao
    apelido
    loja
    preferencia
    disparo_manual

Na mesma transação, recriar as preferências padrão:

    multiplicador_padrao = 2.0
    piso_pontos_padrao   = 4
    assinante_clube      = false

tentativa_login, sessão, tema e flags de interface permanecem intactos. O próximo processamento da Livelo continua agendado; as lojas encontradas entram no catálogo de descobertas, sem serem adicionadas automaticamente às lojas do usuário.

### 4.2 Inter

O reset cobre as duas integrações:

    cashback_inter
    favorita_inter
    execucao_inter
    loja_inter
    disparo_manual_inter
    medicao_produto_direto_inter
    estagio_produto_inter
    produto_direto_inter
    oferta_direta_inter_atual
    execucao_loja_produtos_inter
    execucao_produtos_inter
    loja_direta_inter

O próximo workflow recompõe os catálogos públicos, mas não recupera favoritas, seleções, produtos antigos ou histórico. Produtos diretos só voltam a ser coletados depois de nova seleção administrativa.

Nenhuma tabela da Livelo ou da autenticação entra nessa transação.

## 5. Interface e fluxo

A página existente passa a ter uma Zona de perigo com:

- **Apagar dados da Livelo** — remove cadastro, regras, retratos e disparos da Livelo.
- **Resetar dados do Inter** — remove Sites parceiros, Compre direto, seleções, snapshots e histórico.

Cada botão aponta para uma página protegida de confirmação. O formulário usa HTML nativo e funciona sem JavaScript. A confirmação informa domínio, contagens, consequências e ausência de backup, além de campo de frase e Cancelar.

A validação é repetida na Server Action. A frase não vem de campo oculto e o domínio não é aceito livremente do navegador.

- Sucesso retorna a Configurações com faixa de confirmação.
- Falha de banco faz rollback e mostra mensagem genérica.
- Visitante sem sessão é redirecionado para /entrar.
- Domínio desconhecido retorna 404.

## 6. Segurança e consistência

| Regra | Decisão |
|---|---|
| Autorização | Sessão administrativa exigida na página e na action |
| Confirmação | Frase específica por domínio, validada no servidor |
| Escopo SQL | Lista fixa de tabelas; sem cascade genérico |
| Atomicidade | Uma transação por botão; falha não deixa parcial |
| Concorrência | O banco bloqueia as tabelas durante a operação; escrita posterior é um novo estado |
| Dados comuns | Login, tentativas, cookies, tema e flags preservados |
| Erros | Nunca exibir SQL, URL do banco, exceção ou segredo |
| Recuperação | Não existe cópia no aplicativo; a irreversibilidade é informada |

As contagens são uma fotografia informativa. Se um workflow escrever entre a leitura e a transação, a limpeza continua válida sobre o estado encontrado durante sua execução.

## 7. Interfaces internas previstas

Concentrar a operação em um módulo próprio de banco:

    resumoDadosLivelo() -> ResumoDadosLivelo
    resumoDadosInter()  -> ResumoDadosInter
    apagarDadosLivelo() -> void
    resetarDadosInter() -> void

Também haverá uma função pura para validar a frase esperada por domínio. Não será criada API pública, tabela nova ou migração.

## 8. Testes e aceite

### 8.1 Automatizados

- Frase correta, vazia, errada e trocada entre domínios.
- Resumo com contagens e banco indisponível.
- Livelo limpa somente Livelo e restaura os três padrões.
- Inter limpa V3 e V4, sem tocar Livelo ou autenticação.
- Cada fluxo usa uma única transação.
- Falha no meio não produz sucesso parcial.
- Limpeza repetida de domínio vazio continua válida.
- TypeScript, build, Vitest e suíte Python continuam verdes.

### 8.2 Aceite manual em banco descartável

1. Popular uma linha representativa de cada tabela dos dois domínios.
2. Abrir Configurações sem sessão e confirmar o redirecionamento.
3. Conferir as contagens nas duas páginas de confirmação.
4. Testar Cancelar e frase incorreta.
5. Executar o reset Livelo e confirmar que Inter e login permanecem.
6. Executar o reset Inter e confirmar que Livelo e login permanecem.
7. Repetir os fluxos sobre banco vazio.
8. Confirmar que workflows agendados e disparos manuais continuam disponíveis.

O primeiro teste destrutivo não deve usar o banco de produção.

## 9. Fases planejadas

| Fase | Entrega |
|---|---|
| V5.0 | Este PRD e mapa de dados por domínio | concluída |
| V5.1 | Resumos, validação de frases e transações | concluída |
| V5.2 | Zona de perigo e páginas protegidas | concluída |
| V5.3 | Testes descartáveis, regressão e smoke controlado | pendente |

## 10. Critérios de aceite

1. Visitante não consegue abrir nem executar limpeza.
2. Cada botão afeta somente o domínio anunciado.
3. A confirmação mostra contagens e exige a frase correta.
4. Livelo termina vazia com preferências padrão restauradas.
5. Inter termina sem catálogo, favoritos, produtos ou histórico.
6. Login, tentativas, tema e flags continuam funcionando.
7. Falha transacional não deixa estado parcial.
8. A próxima execução agendada ou manual continua permitida.
9. Nenhuma tabela, migração ou workflow existente é removido.
10. Testes automatizados e build permanecem verdes.
