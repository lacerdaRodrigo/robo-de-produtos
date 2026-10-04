# Referência complementar de design: FUUXUI

A apostila `Apostila_Padroes_de_Interface_FUUXUI_1.pdf` reúne 49 pares de
exemplos e critérios práticos de interface em 13 temas: formulários, ações,
listas, navegação, hierarquia, contraste, acessibilidade, seleção,
sobreposições, microtexto, layout, estados e movimento. Também traz escalas de
referência, critérios de acessibilidade e uma revisão final em três passagens.

O PDF completo fica como material local em `.codex/design/` e é ignorado pelo
Git. Este índice resumido é a referência versionada para o agente e outros
clones do projeto. Quando o PDF estiver presente, consulte nele apenas os
padrões relevantes à tarefa.

## Como usar no aplicativo

- Leia primeiro o HTML V15 e `docs/guias/design-v15.md`, conforme as instruções
do perfil `designer_flutter`.
- Selecione somente os padrões pertinentes à tela, estado ou fluxo em trabalho;
não é necessário reler as 32 páginas em cada tarefa.
- Transforme os princípios escolhidos em critérios verificáveis para aquela
jornada. Exemplos úteis: estados inicial/sem resultado/erro (C3), filtros
visíveis (H5), feedback junto à ação (G1), rótulos acessíveis para ícones (G3),
erros com orientação (A5/J1), estados dos controles (L1) e movimento reduzido
(M3).
- Trate os exemplos e contagens da apostila como heurísticas para comparar
alternativas, não como resultado de pesquisa ou regra universal. Os exemplos
são em grande parte web/desktop; adapte-os às interações nativas Android/iOS,
aos tokens e aos componentes existentes. Não copie valores CSS em pixels para
Flutter.
- A V15 continua sendo a fonte visual de verdade. Se uma sugestão da apostila
conflitar com o HTML ou com `design-v15.md`, preserve o contrato V15 e registre
a lacuna para o agente gerente; não invente uma nova aparência.

## Revisão sugerida

Use as três passagens da apostila como inspiração para uma revisão manual e
proporcional ao escopo: (1) hierarquia, contraste e estados visíveis; (2)
navegação, foco e operação por toque/teclado quando aplicável; (3) rótulos,
erros, pluralização e conteúdo. Registre apenas os problemas pertinentes à
tela alterada e valide-os pelos gates Flutter autorizados em `AGENTS.md`.
