# Roteamento de modelos do Codex

Status: regra operacional deste projeto.

## Regra obrigatória

Antes de alterar código, documento, teste, configuração ou workflow, o assistente classifica a tarefa e informa o modelo e o esforço recomendados. O usuário escolhe manualmente no seletor e confirma. Só então a alteração começa.

Leitura, busca e diagnóstico sem modificar arquivos podem acontecer antes da classificação. Se a tarefa mudar de escopo, a recomendação deve ser refeita.

## Modelos

| Modelo | Papel simples | Quando usar neste projeto |
| --- | --- | --- |
| **GPT-5.6 Luna** | Econômico e rápido. | Mudança visual óbvia, texto curto, busca pontual e ajuste isolado. |
| **GPT-5.6 Terra** | Equilíbrio entre qualidade e custo. | Padrão para documentação importante, bug localizado, testes e feature de tamanho médio. |
| **GPT-5.6 Sol** | Maior capacidade para trabalho complexo. | Arquitetura, integração externa, banco de dados, segurança e implementação da V3 do Shopping Inter. |
| **GPT-5.5 / GPT-5.4** | Gerações anteriores. | Use apenas se o ambiente exigir compatibilidade ou para comparar resultado; prefira a família 5.6 em tarefas novas. |
| **Mini / Nano / “Lua”** | Nomes antigos ou apelidos do seletor. | Se “Lua” aparecer, trate como **Luna** até o seletor indicar outro nome técnico. Para tarefas novas, prefira Luna/Terra/Sol. |

## Níveis de esforço

| Esforço | Uso recomendado |
| --- | --- |
| **none** | Resposta direta, sem análise ou ferramenta. Raro para mudanças no projeto. |
| **low** | Alteração óbvia e localizada, como cor, texto ou espaçamento. |
| **medium** | Ponto de partida equilibrado: documentação relevante, ajuste com leitura prévia ou teste simples. |
| **high** | Bug com causa incerta, feature média ou mudança que cruza mais de um arquivo. |
| **xhigh** | Plano técnico, arquitetura, integração externa ou vários subsistemas. |
| **max** | Caso crítico com qualidade acima de custo e latência; usar apenas quando xhigh não bastar. |

## Cola rápida de decisão

| Tarefa | Modelo | Esforço |
| --- | --- | --- |
| Trocar cor, texto, margem ou um link conhecido | Luna | low |
| Encontrar o local certo e fazer uma pequena alteração | Luna | medium |
| Atualizar regra importante da documentação | Terra | medium |
| Corrigir bug com teste | Terra | medium ou high |
| Criar feature em um subsistema | Terra | high |
| Planejar a V3 do Shopping Inter | Sol | xhigh |
| Implementar a V3 do Shopping Inter | Sol | high ou xhigh |
| Alterar banco, workflow, segurança ou integração externa sensível | Sol | xhigh; max só se necessário |

## Atalho para classificar

Comece pelo caso mais barato e aumente um nível quando houver arquivo incerto, teste quebrado, mais de um subsistema, API externa, banco de dados, workflow ou segurança. Não escolha o maior esforço por padrão: compare o resultado e o custo em tarefas parecidas.

Fontes: [guia oficial de modelos](https://developers.openai.com/api/docs/guides/latest-model) e [catálogo oficial](https://developers.openai.com/api/docs/models). A documentação oficial recomenda Luna para volume sensível a custo, Terra para equilíbrio e Sol para capacidade de fronteira; `medium` é o início equilibrado e `max` fica reservado aos casos mais difíceis.
