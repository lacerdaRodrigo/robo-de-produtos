# Auditoria e organização do projeto

**Data da auditoria:** 27 de agosto de 2026  
**Estado:** execução iniciada; mudanças locais ainda não publicadas

## Andamento da execução

Atualizado em 27 de agosto de 2026:

- [x] Corrigido o filtro residual `loja.favorita` sem criar coluna que havia sido revertida.
- [x] Adicionado teste de regressão para o catálogo Livelo.
- [x] Recuperados os contratos úteis da antiga suíte da API: 83 testes encontrados, 82 executados e 1 aceite destrutivo ignorado fora de banco descartável.
- [x] Restaurado o ESLint e corrigido o build local da API.
- [x] Adicionado um job da API ao workflow de CI; a execução no GitHub depende de envio da branch.
- [x] Fixada a versão 3.44.1 do Flutter no CI; ainda falta confirmar a primeira execução remota e investigar as três diferenças visuais locais.
- [x] Corrigidos todos os links internos ativos; documentos arquivados permanecem históricos.
- [x] Corrigidos os caminhos do versionamento, com teste; a próxima release precisa confirmar a sincronização.
- [x] Removido todo o canal SMTP/Gmail da Livelo por decisão do responsável; o problema do logo deixou de existir com a funcionalidade.
- [x] Organizadas as variáveis por componente, com exemplos separados e mapa central em `docs/CONFIGURACAO.md`.
- [x] Removido `backend/api/lib/flags.ts`, legado de interface confirmado sem importações.

## Conclusão

Não recomendo recriar o projeto. A arquitetura principal está correta; os principais problemas estão na migração incompleta do site antigo, na documentação desatualizada e na ausência de validação suficiente da API.

## Por que existem robô Python e backend?

Eles têm funções diferentes:

```text
Livelo / Inter
      ↓
Robôs Python ──→ Neon/Postgres ──→ API Next.js ──→ Flutter
     ↑                                  ↑
GitHub Actions                      Firebase Auth
                                    Vercel
```

- **Robô Python:** faz coletas demoradas e agendadas, interpreta HTML/JSON e grava uma vez no Postgres.
- **API Next.js:** atende o aplicativo em tempo real, autentica usuários, pagina resultados, protege operações administrativas e lê o banco.
- **Flutter:** somente interface. Não deve acessar Neon, GitHub, Livelo ou Inter diretamente.
- **GitHub Actions:** agenda e executa os robôs.
- **Vercel:** mantém a API disponível.
- **Neon:** armazena os dados.

Portanto, o backend não é outro robô e não é mais um site: é a porta segura entre Flutter e banco. Juntar os dois agora aumentaria muito o risco sem trazer benefício real.

## Estado real encontrado

O núcleo está razoavelmente saudável:

- A [API publicada](https://robo-de-produtos.vercel.app/api/status) respondeu saudável.
- Rota protegida sem credencial respondeu `401`, como deveria.
- Os três workflows estão ativos:
  - [Livelo](https://github.com/lacerdaRodrigo/robo-de-produtos/actions/runs/33000161075): sucesso.
  - [Inter Sites](https://github.com/lacerdaRodrigo/robo-de-produtos/actions/runs/33002486544): sucesso.
  - [Inter Produtos](https://github.com/lacerdaRodrigo/robo-de-produtos/actions/runs/33004776668): workflow bem-sucedido, mas a coleta foi pulada porque não havia lojas selecionadas.
- Python após a retirada do e-mail: Ruff e 172 testes passaram, com 93,37% de cobertura.
- Flutter: análise, formatação, build Web e APK Android passaram.
- Flutter: 150 testes passaram e 3 testes visuais falharam localmente por diferenças mínimas de pixels. O CI remoto passa, indicando diferença de ambiente.
- iOS não foi compilado porque o ambiente da auditoria era Linux e não possuía Xcode.
- A auditoria não produziu alterações de código.

## Problemas mais importantes

### 1. Banco e API estão incompatíveis em instalação nova

**Resolvido no código em 27 de agosto de 2026.** O histórico confirmou que a
coluna havia sido deliberadamente revertida. O filtro residual foi removido e
um teste impede sua reintrodução.

A API consulta `loja.favorita` em `backend/api/lib/banco.ts`, mas nenhuma migração atual cria essa coluna.

Isso significa que um banco criado do zero pelas migrações pode quebrar no painel Livelo. Produção pode possuir uma coluna residual, mas isso não está documentado nem reproduzível.

Esse é o primeiro ponto que precisa ser corrigido.

### 2. A API perdeu testes e configuração durante a remoção do site

**Resolvido no código em 27 de agosto de 2026.** Os testes úteis e o ESLint
foram restaurados, o build foi corrigido e o job da API voltou para o CI. Falta
apenas observar a primeira execução no GitHub depois do envio da branch.

Quando `site/` foi removido:

- vários testes da API não foram transferidos;
- o arquivo de configuração do ESLint ficou para trás;
- hoje a API possui apenas 7 testes;
- não existe gate da API no GitHub Actions;
- `npm run lint` falha porque não encontra `eslint.config.*`;
- `npm run build` compila o código, mas falha ao interpretar `tsc --showConfig`.

A API está publicada, mas o repositório não consegue provar com segurança que uma futura mudança não vai quebrá-la.

### 3. Documentação não representa mais o sistema

**Parcialmente resolvido em 27 de agosto de 2026.** Os caminhos ativos, estado
da API, gates e referências principais foram corrigidos. O verificador não
encontra links quebrados fora de `docs/arquivados/`; ainda existem narrativas
históricas extensas em `docs/PENDENCIAS.md` que devem ser condensadas depois.

Foram encontradas 47 referências internas quebradas ou desatualizadas.

Exemplos:

- `AGENTS.md` aponta para caminhos antigos.
- `README.md` ainda trata a API como arquivada, embora ela esteja em produção.
- `docs/PENDENCIAS.md` mistura publicação antiga e estado atual.
- `docs/TESTES.md` contém quantidades antigas.
- A documentação diz que `site/` deve continuar vivo, mas o diretório já foi removido.

Antes de remover arquivos, a documentação precisa virar novamente uma fonte confiável.

### 4. Versionamento está dessincronizado

O GitHub possui release `v1.43.0`, mas o pacote Python continua declarando `1.40.0`. O workflow de versão ainda procura arquivos nos caminhos anteriores à reorganização.

Isso não quebra a coleta imediatamente, mas torna releases e diagnósticos pouco confiáveis.

### 5. Canal de e-mail Livelo retirado

**Resolvido no código em 27 de agosto de 2026.** O responsável decidiu retirar
por completo a funcionalidade e recuperá-la pelo histórico Git apenas se voltar
a precisar dela. Saíram montador, modelo/porta, adaptador SMTP, segredos, input do
workflow, testes e guia. Os e-mails do Firebase Authentication não pertencem a
esse canal e foram preservados.

A remoção revelou uma regra antiga perigosa: falha ao guardar era só `WARNING`
porque o e-mail era o produto principal. Agora, com Postgres configurado, falha
de persistência encerra a execução para o Actions não ficar verde com o app velho.

## Por que as variáveis aparecem em três lugares?

Porque são três computadores independentes:

| Local | Responsabilidade | Exemplos |
|---|---|---|
| GitHub Actions | Executar os robôs | `DATABASE_URL` e configurações não secretas de coleta |
| Vercel | Executar a API | `DATABASE_URL`, Firebase Admin, token GitHub |
| Flutter | Configuração pública do cliente | `API_URL`, App Check, chave pública reCAPTCHA |
| Neon | Banco de dados | Armazena tabelas; não distribui automaticamente variáveis |

A repetição de `DATABASE_URL` entre GitHub e Vercel é normal: ambos precisam acessar o mesmo banco, mas vivem isolados.

### Recomendação para as variáveis

- Manter segredos nos provedores que realmente os utilizam.
- Nunca colocar `DATABASE_URL`, Firebase Admin ou token GitHub no Flutter.
- Criar um documento único dizendo onde cada variável deve existir.
- Criar exemplos separados para `backend/robo`, `backend/api` e Flutter.
- Manter uma cópia humana em um gerenciador de senhas.
- Registrar um checklist de rotação.

Hoje o exemplo da API mistura variáveis do robô, contém nomes antigos e não documenta tudo. O `app/.env` também aparenta não ser carregado pelo código: o Flutter usa `--dart-define`.

Um gerenciador central como Doppler ou Infisical seria possível, mas adicionaria custo, dependência e configuração. Para o tamanho atual do projeto, documentação centralizada e segredos separados são mais simples.

## Funcionalidades descritas versus implementadas

Foram encontradas estas diferenças:

- Alertas no Flutter ainda é uma tela “em breve”.
- Não foi encontrado o simulador de pontos descrito.
- Favoritos administrativos de lojas existem, mas favoritos pessoais ainda não aparecem como funcionalidade concluída.
- Notificações push e relatórios continuam planejados.
- A coleta de produtos está pronta, mas a execução mais recente não possuía lojas selecionadas.

Além disso, há uma contradição documental: um PRD afirma que limpar Livelo deve restaurar lojas padrão na próxima coleta; outros documentos e o código dizem que banco vazio é um estado legítimo. Isso precisa de uma decisão antes de alterar a regra.

## Ordem segura para organizar a casa

1. Corrigir a incompatibilidade de `loja.favorita`.
2. Recuperar os testes antigos úteis da API.
3. Restaurar ESLint, corrigir o build e adicionar CI da API.
4. Fixar a versão do Flutter no CI para estabilizar testes visuais.
5. Corrigir versionamento e documentação; o canal de e-mail foi removido por decisão posterior.
6. Separar os arquivos de exemplo das variáveis por componente.
7. Remover somente código comprovadamente órfão — `backend/api/lib/flags.ts` foi removido após os gates da API ficarem verdes.
8. Validar coleta de produtos com lojas selecionadas e realizar build iOS em macOS.
9. Só depois decidir sobre simulador, favoritos pessoais, alertas e possível abandono do Flutter Web.

## Recomendação final

A fundação é boa e vale ser recuperada. Python, API, Neon e Flutter devem permanecer separados. Primeiro devem ser corrigidos banco, testes e integração contínua; somente depois deve começar a limpeza física do projeto.

Durante esta organização não foram alterados banco ou produção e nenhuma
notificação real foi enviada. Workflows foram editados apenas no repositório local.
