# Matriz de telas — protótipo mobile V12

Fonte executável: [`../prototipos/mobile-v12/`](../prototipos/mobile-v12/).
As rotas são hash routes para permitir revisão direta sem backend.

| Área | Rota | Cobertura principal |
|---|---|---|
| Abertura | `#/abertura` | proposta, entrada e laboratório |
| Acesso | `#/entrar` | e-mail, senha, mostrar senha, convite negado |
| Recuperação | `#/recuperar` | formulário e resposta neutra |
| Push | `#/permissao-notificacoes` | permitir, negar e continuidade sem push |
| Resumo | `#/resumo` | fontes, atalhos, atualização e estados |
| Serviços | `#/servicos` | Livelo, Inter e Pichau |
| Livelo | `#/livelo` | lojas, acompanhadas, alertas, busca, filtros, histórico e condições |
| Inter hub | `#/inter` | separação entre Sites parceiros e Compre direto |
| Sites parceiros | `#/cashback` | cashback, cliente Inter, condições, acompanhamento e ordenação |
| Compre direto | `#/compre?tab=todas` | lojas, selecionadas e produtos |
| Categorias | overlay em `#/produtos` | hierarquia, chips e `Outros / novas categorias` |
| Produtos | `#/produtos` | busca, categorias, filtros, preço, cashback e acompanhamento |
| Pichau | `#/pichau` | disponibilidade, Pix/cartão, filtros, histórico e oferta segura |
| Alertas | `#/alertas` | filtros de origem, não lidos, marcar individual/todos e preferências |
| Perfil | `#/perfil` | navegação, papel, tema e logout |
| Aparência | `#/aparencia` | claro, escuro e sistema |
| Ajuda | `#/ajuda` | dúvidas frequentes e canais de suporte |
| Relatar problema | `#/relatar-problema` | formulário, envio pendente e retorno |
| Privacidade | `#/privacidade` | origem dos dados, token, retenção e limites |
| Administração | `#/administracao` | autorização e zona de perigo separada por domínio |
| Laboratório | `#/laboratorio` | mapa de rotas, estados, tema e papéis |
| Não encontrado | `#/rota-inexistente` | 404 sem quebrar a casca |

## Interações reutilizáveis

- `data-route`: navegação por hash.
- `data-action`: comandos de tela, overlay, refresh, logout, filtros e
  confirmação.
- `data-tab-action`: troca de abas preservando o domínio.
- `data-search`: busca com atualização curta após digitação.
- `data-follow-domain`/`data-follow-id`: acompanhamento pessoal.
- `data-demo-state`: laboratório de estados.
- `data-theme-value`: escolha de tema.

## Critérios de revisão

1. O fluxo abre sem dependência de rede ou asset remoto.
2. Login válido chega à permissão de push e depois ao Resumo.
3. Todas as áreas autenticadas podem ser alcançadas pelo laboratório ou pela
   navegação normal.
4. Busca, filtros, abas, paginação, acompanhamento e overlays respondem ao
   toque/clique.
5. Dados ilustrativos continuam identificados e não são tratados como
   integração real.
6. As larguras 320, 390, 600, 840 e 1440 px não geram overflow horizontal.
7. Tema claro/escuro e redução de movimento continuam legíveis.
