# Roteamento de modelos do Codex

**Status:** regra de apoio do projeto, atualizada em 2026-09-04 a partir da
[documentação oficial de modelos da OpenAI](https://developers.openai.com/api/docs/models).
Não é um PRD do Radar de Benefícios e não substitui instruções da sessão,
permissões, skills ou pedidos explícitos do responsável.

## Regra operacional

Antes de uma alteração, classifique o risco e a abrangência para decidir o
nível de análise. Use somente modelos e níveis de esforço disponíveis na sessão;
este arquivo não autoriza trocar modelo, publicar, migrar produção, excluir
dados, enviar mensagens ou executar outra ação externa.

Leitura e diagnóstico sem escrita podem preceder a classificação. Quando o
escopo mudar, classifique novamente e informe a escolha quando o ambiente
permitir essa seleção.

## Modelos atuais

| Modelo | Uso recomendado |
|---|---|
| **GPT-6 Astra** | Trabalho de ponta a ponta especialmente difícil, com raciocínio ou código complexos. Use quando estiver disponível e o custo/latência se justificarem. |
| **GPT-5.6 Sol** | Trabalho profissional complexo: arquitetura, segurança, integrações e alterações que cruzam subsistemas. |
| **GPT-5.6 Terra** | Padrão equilibrado para documentação relevante, bug localizado, testes e feature de tamanho médio. |
| **GPT-5.6 Luna** | Tarefa bem delimitada, alto volume ou sensível a custo: busca pontual, texto curto e ajuste mecânico. |
| **GPT-5.5 ou anterior** | Apenas compatibilidade ou comparação quando for a única opção exposta pelo ambiente; não é o padrão para trabalho novo. |

O catálogo oficial classifica Astra como o modelo mais capaz para raciocínio e
código complexos; Sol como modelo profissional complexo; Terra como equilíbrio
entre inteligência e custo; e Luna para volume sensível a custo.

## Nível de esforço

| Esforço | Quando usar |
|---|---|
| **low** | Alteração óbvia e isolada. |
| **medium** | Ponto de partida para documentação relevante, ajuste com leitura prévia ou teste simples. |
| **high** | Bug de causa incerta, feature média ou mais de um arquivo/subsistema. |
| **xhigh / max** | Arquitetura, banco, segurança, integração externa ou situação excepcionalmente crítica. Use o maior nível só quando a incerteza justificar. |

## Atalho de classificação

| Tarefa | Perfil sugerido |
|---|---|
| Texto, link, espaçamento ou busca conhecida | Luna / low |
| Pequena alteração após localizar o arquivo | Luna ou Terra / medium |
| Regra de documentação, bug com teste ou widget | Terra / medium ou high |
| Feature de domínio, API, banco, workflow ou segurança | Sol / high ou xhigh |
| Problema de ponta a ponta sem solução clara | Astra, se disponível / xhigh ou max |

Comece no menor perfil que cubra a incerteza real e aumente somente quando a
investigação revelar mais risco, integrações ou superfícies afetadas.
