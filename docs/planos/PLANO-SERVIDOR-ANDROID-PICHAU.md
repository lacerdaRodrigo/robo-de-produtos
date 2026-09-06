# Plano — Celular Android como executor local da Pichau

**Status:** proposta aguardando aprovação e teste no aparelho.

**Última atualização:** 2026-09-05

Este plano trata um telefone Android antigo, informado com 4 GB de RAM, como
executor local do robô Pichau conectado ao Wi‑Fi residencial. Nenhuma etapa
deste documento significa que o aparelho já é servidor, que o robô já roda
nele ou que o app já acessa o telefone.

## 1. Objetivo

Executar a coleta Pichau em um ambiente residencial que recebeu o catálogo
localmente, evitando depender inicialmente do IP dos runners hospedados pelo
GitHub Actions.

O telefone será um executor do robô, não o servidor da API nem o banco do
aplicativo. O fluxo arquitetural atual do aplicativo continua sendo:

```text
Android/Termux → robô Pichau → Postgres/API → aplicativo Flutter
```

O Flutter não acessará Termux, o telefone ou o Postgres diretamente.

## 2. Escopo da primeira prova

- instalar Termux por fonte confiável e validar arquitetura ARM64, Android,
  armazenamento e memória;
- manter o telefone carregado e conectado ao Wi‑Fi;
- instalar Python, Git e o pacote do robô;
- testar uma única página pública da categoria PC Gamer;
- confirmar se SeleniumBase/Chrome consegue receber `products.items` no Android;
- somente depois testar a coleta completa e a publicação no Postgres;
- manter uma coleta por vez, sem paralelismo entre Livelo, Inter e Pichau;
- não executar ainda os robôs Livelo e Inter no telefone;
- não transformar o Android em runner self-hosted do GitHub na primeira prova.

O aparelho informado com 4 GB de RAM será tratado como candidato para uma
prova de um navegador por vez; isso não é capacidade comprovada para produção.

## 3. O que o telefone não fará

- não servirá a API do Radar;
- não hospedará o banco de dados;
- não receberá conexão direta do aplicativo;
- não armazenará imagens ou HTML bruto da Pichau;
- não executará três robôs simultaneamente;
- não receberá segredos no código ou no Git;
- não usará proxy, rotação de IP ou técnica fora da autorização da Pichau.

## 4. Fases

### Fase 0 — Preparação do aparelho

Confirmar modelo, versão do Android, arquitetura, espaço livre, saúde da
bateria e disponibilidade de carregador. Desativar somente as restrições de
bateria necessárias para o processo autorizado e registrar se o Android mata o
Termux após ficar em segundo plano.

O Termux possui builds para arquiteturas Android, mas seus processos em
segundo plano continuam sujeitos às políticas do sistema; isso precisa ser
validado no aparelho, não presumido.

### Fase 1 — Ambiente mínimo

Instalar Termux e preparar um ambiente isolado para o robô. O `.env` será
criado somente no aparelho e conterá `DATABASE_URL`; nunca será versionado.

Validar primeiro comandos locais simples:

- Python inicia;
- pacote `robo_pichau` importa;
- SeleniumBase inicia;
- Chrome/Chromium abre;
- o robô consegue encerrar o navegador sem deixar processos órfãos.

### Fase 2 — Prova Pichau de uma página

Executar somente a página 1, sem publicar catálogo completo. Registrar apenas
metadados seguros: título, tamanho da resposta, URL final, presença de
payload e marcadores de bloqueio.

Aceitar a fase somente se houver:

- payload `products.items`;
- identificador/SKU;
- URL HTTPS da Pichau;
- preço e disponibilidade extraíveis;
- encerramento limpo do navegador.

Se o Android receber `Site em Manutenção`, bloqueio ou HTML sem payload, parar
sem aumentar retries ou volume.

### Fase 3 — Publicação controlada

Com a página 1 aprovada, executar uma coleta completa controlada, respeitando
os limites já aprovados: no máximo 300 páginas, 2–5 segundos entre requisições
e três tentativas por página.

Validar no banco:

- `pichau_execucao` com estado correto;
- produtos em `pichau_produto`;
- medições em `pichau_medicao`;
- nenhum snapshot parcial substituindo o último válido.

Depois, validar o catálogo pela API e pelo aplicativo.

### Fase 4 — Agendamento local

Somente após a Fase 3:

- iniciar o Termux após reinicialização;
- configurar um agendador local para 09h, 15h e 21h;
- usar lock para impedir execuções sobrepostas;
- manter logs com retenção controlada;
- registrar falha sem apagar o snapshot válido;
- fazer uma execução por vez.

O telefone precisa permanecer ligado, carregando e conectado à internet nos
horários. O agendamento local não substitui a API nem cria uma rota nova para o
aplicativo.

### Fase 5 — Avaliação de Livelo e Inter

Só será aberta se a Pichau funcionar por um período de observação. Cada robô
será avaliado separadamente quanto a dependências, memória, tempo, banco e
falhas. Não mover os três robôs para o telefone de uma vez.

## 5. GitHub Actions e VM

O GitHub Actions hospedado já cria uma VM nova para cada job e a descarta no
final; por isso ele não mantém o mesmo IP ou sessão do computador local.

O runner self-hosted oficial exige um sistema operacional compatível. Android
com Termux/proot seria um experimento, não uma implantação suportada. Também
não será configurado runner self-hosted no repositório público sem uma revisão
de segurança, pois workflows não confiáveis podem executar código no aparelho.

Uma VM gratuita persistente será uma alternativa separada. Ela só será
considerada se o teste de uma página confirmar que a Pichau entrega o catálogo
para a rede/IP dessa VM.

## 6. Critérios de aceite

O telefone só poderá ser considerado executor válido quando:

- sobreviver a reinicialização e retornar ao agendamento;
- executar uma página Pichau sem intervenção manual;
- coletar o catálogo completo dentro dos limites;
- publicar dados no Postgres correto;
- permitir que a API e o app leiam os produtos;
- não sobrescrever snapshot válido em falha;
- não executar coletas concorrentes;
- não armazenar imagens, HTML bruto, cookies ou dados pessoais;
- manter temperatura, bateria e armazenamento em condições aceitáveis.

## 7. Critérios para abandonar o telefone

Interromper a alternativa Android se ocorrer qualquer um destes casos:

- Termux for encerrado pelo Android durante a coleta;
- Chrome/SeleniumBase não funcionar de forma estável;
- a Pichau entregar manutenção ou bloqueio no Wi‑Fi residencial;
- o telefone não suportar a duração ou memória da coleta;
- o banco remoto não puder ser acessado com segurança;
- a operação exigir intervenção manual em todas as execuções.

Nesse cenário, a alternativa adequada passa a ser uma VM/VPS Linux autorizada
ou um endpoint/feed oficial da Pichau.

## 8. Referências operacionais

- [Termux](https://github.com/termux/termux-app)
- [Requisitos de runners self-hosted do GitHub](https://docs.github.com/en/actions/reference/runners/self-hosted-runners)
- [Uso de runners hospedados pelo GitHub](https://docs.github.com/en/actions/how-tos/manage-runners/github-hosted-runners/use-github-hosted-runners)
- [SeleniumBase UC Mode](https://github.com/seleniumbase/SeleniumBase/blob/master/help_docs/uc_mode.md)
