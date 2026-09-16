import { appState, markAlert, markAllAlerts, resetCatalogView, setTheme, setToast, toggleFollow } from "./state.js";
import { alerts, categories, cashbackStores, historySamples, liveloStores, pichauItems, productItems, sourceMeta, summaryData } from "./data.js";
import { button, brand, bottomNav, dialogFrame, followControl, icon, iconButton, pageIntro, pagination, routeButton, searchField, shell, signalLine, sourceMark, stateBox, statusMarker, tabs } from "./components/index.js";
import { navigate, routeName, routeQuery } from "./router.js";

const esc = (value = "") => String(value).replace(/[&<>'"]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[char]);
const nullable = (value, fallback = "—") => value || fallback;
const buttonLink = (label, route, variant = "outline", iconName = "") => routeButton(label, route, variant, iconName);
const sourceClass = (source) => `source-${source}`;

function logoHeader() {
  return `<header class="topbar"><div>${brand()}</div><span class="status-marker status-marker--good">Protótipo V12</span></header>`;
}

function actionRow(actions) {
  return `<div class="cluster">${actions.join("")}</div>`;
}

function sourceLabel(source) {
  const meta = sourceMeta[source] || sourceMeta.livelo;
  return `<span class="signal-line ${sourceClass(source)}">${sourceMark(source)}${meta.label}</span>`;
}

function demoStateNotice() {
  const state = appState.demo.screenState;
  if (state === "success") return "";
  if (state === "offline") return stateBox("offline", "", "retry-demo");
  if (state === "loading") return stateBox("loading", "", "retry-demo");
  if (state === "error") return stateBox("error", "", "retry-demo");
  if (state === "partial") return stateBox("partial", "", "retry-demo");
  if (state === "stale") return stateBox("stale", "", "retry-demo");
  if (state === "empty") return stateBox("empty", "", "retry-demo");
  if (state === "noSync") return stateBox("noSync", "", "retry-demo");
  return "";
}

function renderSplash() {
  return `<div class="page page--splash"><div class="splash-layout"><div class="stack stack--loose"><div>${brand()}</div><div class="stack stack--tight"><p class="eyebrow">Radar de diferenças · protótipo</p><h1 class="display-title">Antes. Depois. Decida.</h1><p class="body-copy">O Radar mostra o que se alterou em pontos, cashback, preço e estoque. Você volta quando há uma diferença concreta, não quando há mais uma vitrine.</p></div>${actionRow([buttonLink("Ver o que mudou", "#/entrar", "primary", "arrow"), buttonLink("Explorar estados", "#/laboratorio", "outline", "settings")])}</div><div class="splash-layout__signal" aria-label="Comparação de uma mudança recente"><span class="splash-layout__pulse" aria-hidden="true"></span><div class="splash-layout__readout stack stack--tight"><span class="eyebrow">Livelo · comparação</span><strong>3 pontos<br /><em>→ 7</em></strong><span class="subtle">Casa &amp; Vídeo · diferença confirmada há 34 min</span></div></div></div></div>`;
}

function renderAuthLayout(title, copy, form, asideTitle = "Uma mudança importa.") {
  return `<div class="page page--auth"><div class="auth-layout"><aside class="auth-layout__aside"><div class="stack stack--loose">${brand()}<div class="stack stack--tight"><p class="eyebrow">Acesso pessoal</p><h1 class="display-title">${title}</h1><p class="body-copy">${copy}</p></div></div><div class="auth-note"><p class="eyebrow">Uma regra simples</p><h2 class="auth-note__title">${asideTitle}</h2><p class="body-copy">Cada fonte conserva seu próprio retrato, horário e condição. O que não veio continua visível como ausência.</p></div></aside><main class="auth-layout__form" id="main-content" tabindex="-1">${form}</main></div></div>`;
}

function renderLogin() {
  return renderAuthLayout("Volte para a diferença.", "Seu Radar começa pelo último movimento, não pelo catálogo inteiro.", `<form class="stack" data-form="login"><div class="stack stack--tight"><p class="eyebrow">Abrir sessão</p><h2 class="section-title">Continue de onde mudou.</h2><p class="body-copy">Use o acesso da sua conta para abrir acompanhamentos, comparações e alertas pessoais.</p></div><div class="stack"><label class="field"><span class="field__label">E-mail</span><input class="input" name="email" type="email" autocomplete="email" required placeholder="voce@exemplo.com" value="${esc(appState.session.email)}" /><span class="field__hint">Apenas o e-mail da sua conta.</span></label><label class="field"><span class="field__label">Senha</span><span class="search-field"><input class="input" name="password" type="password" autocomplete="current-password" required placeholder="Sua senha" /><button class="icon-button" type="button" data-action="toggle-password" aria-label="Mostrar senha">${icon("eye")}</button></span></label></div><div class="form-actions"><button class="button button--primary" type="submit">Ver diferenças ${icon("arrow", "small")}</button><a class="button button--ghost" href="#/recuperar" data-route="#/recuperar">Recuperar acesso</a></div><p class="field__hint">Protótipo: qualquer e-mail válido e senha com 4 ou mais caracteres entram no fluxo simulado.</p></form>`);
}

function renderRecover() {
  return renderAuthLayout("Recupere o acesso.", "Enviaremos uma orientação sem revelar se o endereço está cadastrado.", `<form class="stack" data-form="recover"><div class="stack stack--tight"><p class="eyebrow">Recuperação</p><h2 class="section-title">Receba as instruções</h2><p class="body-copy">Digite o e-mail da conta. A resposta será a mesma para qualquer endereço.</p></div><label class="field"><span class="field__label">E-mail</span><input class="input" name="email" type="email" autocomplete="email" required placeholder="voce@exemplo.com" /><span class="field__hint">Não exibimos se uma conta existe.</span></label><div class="form-actions"><button class="button button--primary" type="submit">Enviar orientação ${icon("arrow", "small")}</button><a class="button button--ghost" href="#/entrar" data-route="#/entrar">Voltar ao login</a></div></form>`);
}

function renderAccessDenied() {
  return renderAuthLayout("Acesso ainda não liberado.", "Sua sessão foi reconhecida, mas esta conta não tem convite ativo para o aplicativo.", `<div class="stack stack--loose"><div class="state-box state-box--danger"><div class="stack stack--tight"><span class="eyebrow">Acesso negado</span><h2 class="section-title">O Radar não abriu sua área.</h2><p class="body-copy">Saia desta sessão e tente novamente com uma conta autorizada.</p></div></div><div class="form-actions">${button("Sair", "logout", "dark", "logout")}${button("Tentar novamente", "go-login", "outline", "refresh")}</div></div>`);
}

function renderNotificationPermission() {
  return `<div class="page page--auth"><div class="page__content"><div class="permission-card"><div class="permission-card__mark">${icon("bell")}</div><div class="stack stack--tight"><p class="eyebrow">Um pedido no momento certo</p><h1 class="screen-title">Quer receber mudanças importantes?</h1><p class="body-copy">O push avisa quando um item acompanhado muda. O histórico continua disponível mesmo se você não permitir notificações.</p></div><div class="form-actions">${button("Permitir notificações", "allow-notifications", "primary", "bell")}${button("Agora não", "deny-notifications", "outline")}</div><p class="field__hint">Você pode rever essa escolha em Preferências de alertas.</p></div></div></div>`;
}

function renderSummary() {
  const notices = demoStateNotice();
  const rows = summaryData.map((item) => `<a class="service-row ${sourceClass(item.id)}" href="${item.route}" data-route="${item.route}"><span class="service-row__rail" aria-hidden="true"></span><span><strong class="service-row__title">${item.name}</strong><span class="service-row__meta"><span>${item.description}</span><span>${item.status}</span></span></span><span class="value-lockup"><strong class="value-lockup__value mono">${item.value}</strong><span class="value-lockup__label">${item.valueLabel}</span>${icon("chevron", "small")}</span></a>`).join("");
  return shell({ title: "Resumo", active: "resumo", eyebrow: "Resumo", content: `<div class="home-hero"><section class="home-hero__readout"><div class="stack stack--tight"><p class="eyebrow">Última diferença encontrada</p><h2 class="screen-title">Casa &amp; Vídeo: 3 → 7 pontos.</h2><p class="body-copy">A Livelo marcou a alteração e preservou a condição publicada no último retrato válido.</p>${signalLine("+4 pontos · confirmado há 34 min", "info")}</div></section><section class="stack stack--loose"><div class="stack stack--tight"><p class="eyebrow">Próxima leitura</p><h2 class="section-title">Escolha onde comparar.</h2></div>${actionRow([buttonLink("Comparar produtos", "#/produtos", "primary", "search"), buttonLink("Ver alertas", "#/alertas", "outline", "bell")])}<div class="notice-strip notice-strip--info">${icon("info")}<p class="notice-strip__copy"><strong>Dados ilustrativos.</strong> Este protótipo simula respostas da API sem enviar nada.</p></div></section></div>${notices}<section class="stack stack--tight"><div class="split"><div><p class="eyebrow">Suas fontes</p><h2 class="section-title">Onde você acompanha.</h2></div>${button("Atualizar resumo", "refresh-summary", "ghost", "refresh")}</div><div class="service-list">${rows}</div></section>`});
}

function renderServices() {
  const content = `<div class="stack stack--loose">${pageIntro("Serviços", "Escolha onde comparar.", "Cada fonte conserva seu próprio retrato, histórico e estado de atualização.")}<div class="service-list"><a class="service-row source-livelo" href="#/livelo" data-route="#/livelo"><span class="service-row__rail"></span><span><strong class="service-row__title">Livelo</strong><span class="service-row__meta">Pontos por loja · catálogo paginado</span></span><span>${icon("chevron")}</span></a><a class="service-row source-cashback" href="#/inter" data-route="#/inter"><span class="service-row__rail"></span><span><strong class="service-row__title">Banco Inter</strong><span class="service-row__meta">Sites parceiros · Compre direto</span></span><span>${icon("chevron")}</span></a><a class="service-row source-pichau" href="#/pichau" data-route="#/pichau"><span class="service-row__rail"></span><span><strong class="service-row__title">Pichau</strong><span class="service-row__meta">PC Gamer · Pix e cartão separados</span></span><span>${icon("chevron")}</span></a></div><div class="dark-panel stack"><p class="eyebrow">Como ler</p><h2 class="section-title">A diferença vem com contexto.</h2><p class="body-copy">Atualizado, atrasado, parcial e indisponível não são o mesmo cenário. O Radar mostra a diferença para você decidir com mais segurança.</p>${buttonLink("Entender na Ajuda", "#/ajuda", "outline", "help")}</div></div>`;
  return shell({ title: "Serviços", active: "servicos", eyebrow: "Serviços", content });
}

function liveloItem(item) {
  const followed = appState.followed.livelo.has(item.id);
  const club = item.club ? `<span>${item.campaign === "CLUB" ? "Exclusivo Clube" : `Clube: ${esc(item.club)} pontos`}</span>` : "";
  return `<article class="offer-row source-livelo"><div class="offer-row__top"><div class="offer-row__identity">${sourceMark("livelo")}<div><h3 class="offer-row__name">${esc(item.name)}</h3><span class="offer-row__origin">${esc(item.category)} · ${esc(item.validity || "sem validade informada")}</span></div></div><div class="offer-row__benefit"><strong>${esc(item.points)}</strong><span>pontos</span></div></div><p class="offer-row__description">${esc(item.description)}</p><div class="offer-row__bottom"><div class="data-row__meta"><span>Base ${esc(item.base)}</span>${club}<span>${item.alert ? "Indicador da última coleta" : "Sem alerta nesta coleta"}</span></div><div class="offer-row__actions">${followControl("livelo", item.id, followed)}${button("Condições", `open-conditions:livelo:${item.id}`, "ghost", "info")}${button("Histórico", `open-history:livelo:${item.id}`, "ghost", "history")}${button("Abrir Livelo", `open-external:livelo:${item.id}`, "ghost", "external")}</div></div></article>`;
}

function renderLivelo() {
  const activeTab = appState.tabs.livelo;
  let items = liveloStores.filter((item) => activeTab === "todas" || (activeTab === "acompanhadas" ? appState.followed.livelo.has(item.id) : item.alert));
  if (appState.filters.livelo.category !== "Todas") items = items.filter((item) => item.category === appState.filters.livelo.category);
  const query = appState.search.livelo.trim().toLowerCase();
  if (query) items = items.filter((item) => `${item.name} ${item.category}`.toLowerCase().includes(query));
  const state = appState.demo.screenState;
  const list = state === "searchEmpty" ? stateBox("searchEmpty", "", "clear-search:livelo") : state === "empty" || state === "noSync" ? demoStateNotice() : items.map(liveloItem).join("");
  const content = `<div class="catalog-head">${pageIntro("Livelo · catálogo", "O que mudou nos pontos.", "Consulte lojas, acompanhe mudanças pessoais e abra o histórico de qualquer item.")}<div class="catalog-head__tools">${searchField("livelo", appState.search.livelo, "Buscar loja")}${actionRow([button("Filtros", "open-filters:livelo", "outline", "filter"), button("Atualizar", "request-refresh:livelo", "ghost", "refresh")])}</div></div>${tabs([{ id: "todas", label: "Lojas" }, { id: "acompanhadas", label: "Acompanhadas" }, { id: "alertas", label: "Alertas" }], activeTab, "livelo")}${state !== "success" && !["empty", "noSync", "searchEmpty"].includes(state) ? demoStateNotice() : ""}<div class="filter-bar stack-gap-medium"><span class="status-marker status-marker--info">Categoria: ${esc(appState.filters.livelo.category)}</span><span class="status-marker">${items.length ? "4 itens no protótipo" : "Sem itens"}</span></div><div class="catalog-list">${list}</div>${state === "success" && items.length ? pagination("livelo", appState.pages.livelo, 2) : ""}`;
  return shell({ title: "Livelo", active: "servicos", back: "#/servicos", eyebrow: "Serviços / Livelo", content });
}

function interHub() {
  const content = `<div class="stack stack--loose">${pageIntro("Banco Inter", "Duas formas de encontrar vantagem.", "Sites parceiros e Compre direto são experiências distintas e continuam separadas.")}<div class="stack"><a class="service-row source-cashback" href="#/cashback" data-route="#/cashback"><span class="service-row__rail"></span><span><strong class="service-row__title">Sites parceiros</strong><span class="service-row__meta">Cashback · condições da loja · acompanhamento pessoal</span></span><span>${icon("chevron")}</span></a><a class="service-row source-produtos" href="#/compre?tab=todas" data-route="#/compre?tab=todas"><span class="service-row__rail"></span><span><strong class="service-row__title">Compre direto</strong><span class="service-row__meta">Lojas selecionadas · produtos · histórico</span></span><span>${icon("chevron")}</span></a></div><div class="metric-band"><div class="metric-band__item"><strong class="metric-band__value">24</strong><span class="metric-band__label">lojas acompanhadas</span></div><div class="metric-band__item"><strong class="metric-band__value">1 h</strong><span class="metric-band__label">último retrato válido</span></div></div>${demoStateNotice()}</div>`;
  return shell({ title: "Banco Inter", active: "servicos", back: "#/servicos", eyebrow: "Serviços / Banco Inter", content });
}

function cashbackItem(item) {
  const followed = appState.followed.cashback.has(item.id);
  return `<article class="offer-row source-cashback"><div class="offer-row__top"><div class="offer-row__identity">${sourceMark("cashback")}<div><h3 class="offer-row__name">${esc(item.name)}</h3><span class="offer-row__origin">${esc(item.client || "Cliente não informado")} · atualizado ${esc(item.updated)}</span></div></div><div class="offer-row__benefit"><strong>${esc(item.benefit)}</strong><span>${esc(item.benefitLabel)}</span></div></div><p class="offer-row__description">${esc(item.conditions || "Condições não informadas neste retrato.")}</p><div class="offer-row__bottom"><div class="data-row__meta"><span>${esc(item.promo || "Oferta sem etiqueta")}</span>${item.secondary ? `<span>${esc(item.secondary)}</span>` : ""}</div><div class="offer-row__actions">${followControl("cashback", item.id, followed)}${button("Condições", `open-conditions:cashback:${item.id}`, "ghost", "info")}${button("Ir para o Inter", `open-external:cashback:${item.id}`, "ghost", "external")}</div></div></article>`;
}

function renderCashback() {
  const activeTab = appState.tabs.cashback;
  let items = cashbackStores.filter((item) => activeTab === "todas" || appState.followed.cashback.has(item.id));
  const query = appState.search.cashback.trim().toLowerCase();
  if (query) items = items.filter((item) => item.name.toLowerCase().includes(query));
  if (appState.filters.cashback.sort === "Nome A–Z") items.sort((a, b) => a.name.localeCompare(b.name, "pt-BR"));
  const state = appState.demo.screenState;
  const list = state === "searchEmpty" ? stateBox("searchEmpty", "", "clear-search:cashback") : state === "empty" || state === "noSync" ? demoStateNotice() : items.map(cashbackItem).join("");
  const content = `<div class="catalog-head">${pageIntro("Inter · Sites parceiros", "Oferta sem adivinhação.", "O maior percentual não conta a história inteira. Veja condição, origem e atualização antes de abrir a oferta.")}<div class="catalog-head__tools">${searchField("cashback", appState.search.cashback, "Buscar loja")}${actionRow([button("Ordenar", "open-filters:cashback", "outline", "sort"), button("Atualizar", "request-refresh:cashback", "ghost", "refresh")])}</div></div>${tabs([{ id: "todas", label: "Todas" }, { id: "acompanhadas", label: "Acompanhadas" }], activeTab, "cashback")}${state !== "success" && !["empty", "noSync", "searchEmpty"].includes(state) ? demoStateNotice() : ""}<div class="filter-bar stack-gap-medium"><span class="status-marker status-marker--info">${appState.filters.cashback.sort}</span><span class="status-marker">10 por página</span></div><div class="catalog-list">${list}</div>${state === "success" && items.length ? pagination("cashback", appState.pages.cashback, 2) : ""}`;
  return shell({ title: "Cashback", active: "servicos", back: "#/inter", eyebrow: "Inter / Sites parceiros", content });
}

const directStores = [
  { id: "store-1", name: "Casas Bahia", slug: "casas-bahia", selected: true, pages: "84 páginas no último retrato" },
  { id: "store-2", name: "Ponto", slug: "ponto", selected: true, pages: "42 páginas no último retrato" },
  { id: "store-3", name: "Extra", slug: "extra", selected: false, pages: "Ainda não selecionada" },
];

function directStoreRow(store) {
  const selected = appState.selectedStores.has(store.id);
  return `<article class="data-row"><div><h3 class="data-row__title">${esc(store.name)}</h3><div class="data-row__meta"><span>${esc(store.slug)}</span><span>${esc(store.pages)}</span></div></div><div class="value-lockup"><span class="status-marker ${selected ? "status-marker--good" : ""}">${selected ? "Selecionada" : "Disponível"}</span><button class="button button--ghost" type="button" data-action="toggle-store:${store.id}">${selected ? "Remover" : "Selecionar"}</button></div></article>`;
}

function productItem(item) {
  const followed = appState.followed.produtos.has(item.id);
  const tags = item.tags.length ? item.tags.map((tag) => `<span>${esc(tag)}</span>`).join(" · ") : "sem etiquetas";
  return `<article class="product-row"><div><p class="product-row__brand">${esc(item.store)} · ${esc(item.brand || "marca não informada")}</p><h3 class="product-row__name">${esc(item.name)}</h3><div class="product-row__meta"><span>${esc(item.category || "categoria não informada")}</span><span>${esc(item.availability)}</span><span>${tags}</span></div></div><div class="product-row__values"><strong class="product-row__price">${esc(item.price)}</strong><span class="product-row__cashback">cashback ${esc(item.cash)}</span><span class="subtle">líquido ${esc(item.net)}</span></div><div class="product-row__actions">${followControl("produtos", item.id, followed)}${button("Histórico", `open-history:produtos:${item.id}`, "ghost", "history")}${button("Abrir oferta", `open-external:produtos:${item.id}`, "ghost", "external")}</div></article>`;
}

function renderProductResults() {
  const query = appState.search.produtos.trim().toLowerCase();
  let items = productItems.filter((item) => !query || `${item.name} ${item.brand || ""} ${item.store}`.toLowerCase().includes(query));
  if (appState.filters.produtos.stores !== "Todas as lojas") items = items.filter((item) => item.store === appState.filters.produtos.stores);
  if (appState.selectedCategories.length) items = items.filter((item) => appState.selectedCategories.some((category) => item.category === category || category === "Casa"));
  const state = appState.demo.screenState;
  if (state === "searchEmpty" || (query && items.length === 0)) return stateBox("searchEmpty", "", "clear-search:produtos");
  if (["empty", "noSync"].includes(state)) return demoStateNotice();
  return items.map(productItem).join("") + pagination("produtos", appState.pages.produtos, 2);
}

function renderProducts() {
  const categoryChips = appState.selectedCategories.map((category) => `<span class="category-chip">${esc(category)}<button type="button" data-action="remove-category:${encodeURIComponent(category)}" aria-label="Remover área ${esc(category)}">×</button></span>`).join("");
  const content = `<div class="catalog-head">${pageIntro("Inter · Compre direto", "A diferença está no detalhe.", "Busque por produto, escolha uma área contextual e veja preço, cashback e histórico na mesma leitura.")}<div class="catalog-head__tools">${searchField("produtos", appState.search.produtos, "Buscar produto, marca ou loja")}${actionRow([button("Filtros", "open-filters:produtos", "outline", "filter"), button("Atualizar", "request-refresh:produtos", "ghost", "refresh")])}</div></div><section class="stack"><div class="notice-strip" style="--notice-color:var(--color-info)">${icon("zap")}<p class="notice-strip__copy"><strong>Atalhos de busca.</strong> Comece por Celulares, Informática, Casa, Beleza ou Pet.</p></div><div class="filter-bar">${["Celulares", "Informática", "Casa", "Beleza", "Pet"].map((label) => `<button class="filter-trigger" type="button" data-action="quick-category:${encodeURIComponent(label)}">${label}</button>`).join("")}</div><button class="button button--outline button--block" type="button" data-action="open-categories">${icon("layers", "small")}<span>${appState.selectedCategories.length ? "Adicionar área" : "Escolher categoria"}</span></button>${categoryChips ? `<div class="filter-bar">${categoryChips}<button class="button button--ghost" type="button" data-action="clear-categories">Limpar áreas</button></div>` : ""}</section><div class="metric-band"><div class="metric-band__item"><strong class="metric-band__value">3.310</strong><span class="metric-band__label">produtos no retrato</span></div><div class="metric-band__item"><strong class="metric-band__value">2</strong><span class="metric-band__label">lojas selecionadas</span></div></div><div class="catalog-list">${renderProductResults()}</div>`;
  return shell({ title: "Produtos", active: "servicos", back: "#/compre?tab=todas", eyebrow: "Inter / Compre direto / Produtos", content });
}

function renderCompre() {
  const query = routeQuery(appState.route);
  const queryTab = query.get("tab");
  if (queryTab && ["todas", "selecionadas", "produtos"].includes(queryTab)) appState.tabs.compre = queryTab;
  const activeTab = appState.tabs.compre;
  if (activeTab === "produtos") return renderProducts();
  let stores = directStores.filter((store) => activeTab === "todas" || appState.selectedStores.has(store.id));
  const searchTerm = appState.search.produtos.trim().toLowerCase();
  if (searchTerm) stores = stores.filter((store) => `${store.name} ${store.slug}`.toLowerCase().includes(searchTerm));
  const content = `<div class="catalog-head">${pageIntro("Inter · Compre direto", "Escolha uma loja para seguir.", "As lojas selecionadas alimentam a coleta de produtos. O acompanhamento pessoal dos produtos acontece dentro do catálogo.")}<div class="catalog-head__tools">${searchField("produtos", appState.search.produtos, "Buscar loja")}${actionRow([button("Atualizar", "request-refresh:compre", "ghost", "refresh")])}</div></div>${tabs([{ id: "todas", label: "Todas" }, { id: "selecionadas", label: "Selecionadas" }, { id: "produtos", label: "Produtos" }], activeTab, "compre")}<div class="notice-strip" style="--notice-color:var(--color-info);margin-top:16px">${icon("info")}<p class="notice-strip__copy"><strong>Seleção administrativa.</strong> Este controle não é o sino de acompanhamento pessoal.</p></div><div class="catalog-list">${stores.map(directStoreRow).join("")}</div>${pagination("compre", 1, 2)}`;
  return shell({ title: "Compre direto", active: "servicos", back: "#/inter", eyebrow: "Inter / Compre direto", content });
}

function pichauItem(item) {
  const followed = appState.followed.pichau.has(item.id);
  const availabilityTone = item.availability === "Disponível" ? "good" : item.availability === "Esgotado" ? "warning" : "danger";
  return `<article class="product-row"><div><p class="product-row__brand">${esc(item.brand)} · ${esc(item.sku)}</p><h3 class="product-row__name">${esc(item.name)}</h3><div class="product-row__meta"><span>${esc(item.category)}</span>${statusMarker(esc(item.availability), availabilityTone)}${item.tags.map((tag) => `<span>${esc(tag)}</span>`).join(" · ")}</div></div><div class="product-row__values"><strong class="product-row__price">${esc(item.pix)}</strong><span class="product-row__cashback">${esc(item.discount || "desconto não informado")}</span><span class="subtle">Cartão ${esc(item.card)}</span></div><div class="product-row__actions">${followControl("pichau", item.id, followed)}${button("Histórico", `open-history:pichau:${item.id}`, "ghost", "history")}${button("Ver na Pichau", `open-external:pichau:${item.id}`, "ghost", "external")}</div></article>`;
}

function renderPichau() {
  const activeTab = appState.tabs.pichau;
  let items = pichauItems.filter((item) => activeTab === "todas" || appState.followed.pichau.has(item.id));
  const query = appState.search.pichau.trim().toLowerCase();
  if (query) items = items.filter((item) => `${item.name} ${item.brand} ${item.sku}`.toLowerCase().includes(query));
  if (appState.filters.pichau.availability !== "Todas") {
    const availability = appState.filters.pichau.availability === "Disponíveis" ? "Disponível" : "Esgotado";
    items = items.filter((item) => item.availability === availability);
  }
  const state = appState.demo.screenState;
  const list = state === "searchEmpty" ? stateBox("searchEmpty", "", "clear-search:pichau") : state === "empty" || state === "noSync" ? demoStateNotice() : items.map(pichauItem).join("");
  const content = `<div class="catalog-head">${pageIntro("Pichau · PC Gamer", "Preço com contexto.", "Pix, cartão, disponibilidade e histórico ficam separados para não criar uma falsa certeza.")}<div class="catalog-head__tools">${searchField("pichau", appState.search.pichau, "Buscar nome, marca ou SKU")}${actionRow([button("Filtros", "open-filters:pichau", "outline", "filter"), button("Atualizar", "request-refresh:pichau", "ghost", "refresh")])}</div></div>${tabs([{ id: "todas", label: "Todas" }, { id: "acompanhadas", label: "Acompanhadas" }], activeTab, "pichau")}${state !== "success" && !["empty", "noSync", "searchEmpty"].includes(state) ? demoStateNotice() : ""}<div class="filter-bar" style="margin-top:16px"><span class="status-marker status-marker--info">Disponibilidade: ${esc(appState.filters.pichau.availability)}</span><span class="status-marker">Ordenado por ${esc(appState.filters.pichau.sort)}</span></div><div class="catalog-list">${list}</div>${state === "success" && items.length ? pagination("pichau", appState.pages.pichau, 2) : ""}`;
  return shell({ title: "Pichau", active: "servicos", back: "#/servicos", eyebrow: "Serviços / Pichau", content });
}

function alertItem(item) {
  const source = sourceMeta[item.source];
  return `<article class="alert-row" style="--source-color:${source.color}"><span class="alert-row__bar" aria-hidden="true"></span><div><button class="button button--ghost" style="padding:0;min-height:32px" type="button" data-action="read-alert:${item.id}" aria-pressed="${item.read}"><span class="alert-row__title">${esc(item.title)}</span></button><p class="alert-row__copy">${esc(item.copy)}</p><div class="data-row__meta">${sourceLabel(item.source)}<span>${item.read ? "Lido" : "Não lido"}</span></div></div><time class="alert-row__date">${esc(item.date)}</time></article>`;
}

function renderAlerts() {
  const activeTab = appState.tabs.alerts;
  let items = appState.alerts.filter((item) => activeTab === "todas" || (activeTab === "nao-lidos" ? !item.read : item.source === activeTab));
  const content = `<div class="catalog-head">${pageIntro("Central de Alertas", "Acompanhe o que mudou.", "Histórico de 90 dias, separado por origem e sem transformar ausência de dado em um alerta falso.")}<div class="catalog-head__tools">${actionRow([button("Marcar tudo como lido", "mark-all-alerts", "outline", "check"), button("Preferências", "open-alert-preferences", "ghost", "settings")])}</div></div>${tabs([{ id: "todas", label: "Todos" }, { id: "nao-lidos", label: "Não lidos" }, { id: "livelo", label: "Livelo" }, { id: "cashback", label: "Cashback" }, { id: "produtos", label: "Produtos" }, { id: "pichau", label: "Pichau" }], activeTab, "alerts")}<div class="filter-bar" style="margin-top:16px"><span class="status-marker status-marker--info">Últimos 90 dias</span><span class="status-marker">${items.length} eventos nesta página</span></div><div class="alert-list">${items.length ? items.map(alertItem).join("") : stateBox("empty", "", "retry-demo")}</div>${pagination("alerts", appState.pages.alerts, 2)}</div>`;
  return shell({ title: "Central de Alertas", active: "servicos", back: "#/perfil", eyebrow: "Perfil / Central de Alertas", content });
}

function renderProfile() {
  const admin = appState.session.role === "admin";
  const items = [
    ["bell", "Central de Alertas", "Mudanças dos itens acompanhados", "#/alertas"],
    ["sun", "Aparência", `Agora: ${appState.theme === "system" ? "Sistema" : appState.theme === "dark" ? "Escuro" : "Claro"}`, "#/aparencia"],
    ["help", "Ajuda", "Entenda fontes, estados e histórico", "#/ajuda"],
    ["flag", "Reportar problema", "Envie contexto sem incluir senha", "#/relatar-problema"],
    ["shield", "Privacidade", "Acompanhamento e retenção", "#/privacidade"],
  ];
  if (admin) items.push(["settings", "Administração", "Zona de perigo protegida", "#/administracao"]);
  const menu = items.map(([iconName, title, copy, route]) => `<a class="profile-menu__item" href="${route}" data-route="${route}"><span class="profile-menu__icon">${icon(iconName, "small")}</span><span><strong class="profile-menu__title">${title}</strong><span class="profile-menu__copy">${copy}</span></span>${icon("chevron", "small")}</a>`).join("");
  const content = `<div class="stack stack--loose">${pageIntro("Perfil", `Olá, ${esc(appState.session.name)}.`, esc(appState.session.email || "Sessão de protótipo"))}<div class="surface" style="padding:20px"><div class="split"><div class="stack stack--tight"><span class="eyebrow">Sessão</span><strong>Conta autenticada</strong><span class="muted">Acompanhamentos pessoais ficam isolados por usuário.</span></div><span class="avatar">RS</span></div></div><div class="profile-menu">${menu}</div>${button("Sair do Radar", "confirm-logout", "outline", "logout")}</div>`;
  return shell({ title: "Perfil", active: "", back: "#/resumo", eyebrow: "Perfil", content });
}

function renderAppearance() {
  const options = [["system", "Sistema", "Segue a preferência do aparelho.", "sun"], ["light", "Claro", "Superfícies abertas e contraste nítido.", "sun"], ["dark", "Escuro", "Fundo profundo para pouca luz.", "moon"]];
  const content = `<div class="stack stack--loose">${pageIntro("Aparência", "Escolha como o Radar aparece.", "A mudança é imediata e não reinicia sua sessão.")}<div class="profile-menu">${options.map(([value, title, copy, iconName]) => `<button class="profile-menu__item" type="button" data-theme-value="${value}" aria-pressed="${appState.theme === value}"><span class="profile-menu__icon">${icon(iconName, "small")}</span><span><strong class="profile-menu__title">${title} ${appState.theme === value ? "· ativo" : ""}</strong><span class="profile-menu__copy">${copy}</span></span>${appState.theme === value ? icon("check", "small") : icon("chevron", "small")}</button>`).join("")}</div><div class="notice-strip" style="--notice-color:var(--color-info)">${icon("info")}<p class="notice-strip__copy"><strong>Preferência do sistema.</strong> Em Sistema, o protótipo acompanha o tema do dispositivo quando essa informação existir.</p></div></div>`;
  return shell({ title: "Aparência", active: "", back: "#/perfil", eyebrow: "Perfil / Aparência", content });
}

function renderHelp() {
  const questions = [
    ["De onde vêm os dados?", "O aplicativo lê somente a API autenticada. Livelo, Sites parceiros do Inter, Produtos Inter e Pichau mantêm retratos separados."],
    ["O que significa atrasado?", "A última coleta válida ainda está disponível, mas passou do intervalo esperado. Atraso não é o mesmo que falha, ausência ou zero."],
    ["Acompanhado e alerta são a mesma coisa?", "Não. Acompanhamento é uma relação pessoal. Um alerta só aparece quando existe uma mudança válida depois de um retrato-base."],
    ["Por que há paginação?", "O catálogo continua no servidor. Cada página traz um recorte limitado e preserva busca, filtros, ordenação e posição ao voltar."],
    ["O que acontece se eu negar o push?", "A Central e o histórico continuam disponíveis. Apenas a entrega de notificação depende da permissão, preferência e token válido."],
    ["Como comparo produtos?", "Em Compre direto, abra Produtos, use busca ou uma área contextual e confira preço atual, cashback, preço líquido e histórico sem misturar medições."],
  ];
  const content = `<div class="stack stack--loose">${pageIntro("Ajuda", "Entenda antes de decidir.", "Uma leitura rápida sobre fontes, estados, alertas e histórico.")}<div class="stack">${questions.map(([question, answer], index) => `<details class="accordion" ${index === 0 ? "open" : ""}><summary>${question}</summary><div class="accordion__body">${answer}</div></details>`).join("")}</div><div class="dark-panel stack"><p class="eyebrow">Ainda ficou uma dúvida?</p><h2 class="section-title">Leve o contexto com você.</h2><p class="body-copy">Ao reportar um problema, informe a tela e o estado percebido. Nunca inclua senha ou token.</p>${actionRow([buttonLink("Reportar problema", "#/relatar-problema", "primary", "flag"), buttonLink("Ver privacidade", "#/privacidade", "outline", "shield")])}</div></div>`;
  return shell({ title: "Ajuda", active: "", back: "#/perfil", eyebrow: "Perfil / Ajuda", content });
}

function renderReport() {
  const content = `<div class="stack stack--loose">${pageIntro("Reportar problema", "Conte o que aconteceu.", "Seu relato recebe categoria, mensagem e contexto da versão. Não inclua senha, token ou URL privada.")}<form class="stack" data-form="report"><label class="field"><span class="field__label">Categoria</span><select class="select" name="category" required><option value="">Escolha uma categoria</option><option>Dados desatualizados</option><option>Erro ao carregar</option><option>Problema de navegação</option><option>Outro</option></select></label><label class="field"><span class="field__label">Mensagem</span><textarea class="textarea" name="message" required minlength="10" placeholder="Descreva a tela, a ação e o estado que você viu."></textarea><span class="field__hint">O relato é retido por até 180 dias.</span></label><div class="surface" style="padding:16px"><span class="field__label">Contexto incluído</span><p class="field__hint">Versão do protótipo · ${esc(routeName(appState.route))} · tema ${esc(appState.theme)}</p></div><button class="button button--primary" type="submit">Enviar relato ${icon("arrow", "small")}</button></form></div>`;
  return shell({ title: "Reportar problema", active: "", back: "#/perfil", eyebrow: "Perfil / Reportar problema", content });
}

function renderPrivacy() {
  const content = `<div class="stack stack--loose">${pageIntro("Privacidade", "Seus sinais continuam seus.", "O Radar separa dados pessoais, catálogos e operações administrativas para reduzir confusão.")}<div class="stack"><div class="notice-strip" style="--notice-color:var(--color-info)">${icon("shield")}<p class="notice-strip__copy"><strong>Acompanhamento pessoal.</strong> Livelo, cashback, produtos e Pichau são associados ao usuário autenticado e não alteram seleções globais.</p></div><div class="metric-band"><div class="metric-band__item"><strong class="metric-band__value">90</strong><span class="metric-band__label">dias de histórico de alertas</span></div><div class="metric-band__item"><strong class="metric-band__value">180</strong><span class="metric-band__label">dias de retenção de relatos</span></div></div>${["O app acessa somente a API autenticada; não fala diretamente com Livelo, Inter, Pichau ou banco.", "O token de notificação é removido no logout da sessão atual.", "Push depende da permissão do aparelho, da preferência e de um token válido. A Central continua funcionando sem push.", "As buscas e históricos respeitam o usuário autenticado. Administração é protegida separadamente."].map((text) => `<div class="data-row"><p class="body-copy">${text}</p>${icon("check", "small")}</div>`).join("")}</div>${actionRow([buttonLink("Abrir Ajuda", "#/ajuda", "outline", "help"), buttonLink("Reportar problema", "#/relatar-problema", "ghost", "flag")])}</div>`;
  return shell({ title: "Privacidade", active: "", back: "#/perfil", eyebrow: "Perfil / Privacidade", content });
}

function renderAdmin() {
  if (appState.session.role !== "admin") return renderAccessDenied();
  const content = `<div class="stack stack--loose">${pageIntro("Administração", "Zona de perigo.", "Operações separadas por domínio. As contagens são uma fotografia e a ação é irreversível no produto real.")}<section class="danger-zone"><div class="danger-zone__header"><div class="stack stack--tight"><span class="eyebrow">Acesso administrativo</span><h2 class="section-title">Apague somente o que você confirma.</h2><p class="body-copy">Login, tema, tentativas e demais dados comuns ficam preservados.</p></div></div><button class="danger-zone__item" type="button" data-action="open-admin-confirm:livelo"><span><strong>Apagar dados da Livelo</strong><span class="profile-menu__copy">Cadastro, regras, retratos e disparos da Livelo.</span></span>${icon("trash")}</button><button class="danger-zone__item" type="button" data-action="open-admin-confirm:inter"><span><strong>Resetar dados do Inter</strong><span class="profile-menu__copy">Sites parceiros, Compre direto, seleções, snapshots e histórico.</span></span>${icon("trash")}</button></section><div class="notice-strip" style="--notice-color:var(--color-danger)">${icon("lock")}<p class="notice-strip__copy"><strong>Confirmação protegida.</strong> O protótipo nunca executa exclusão real, mas reproduz a validação e o retorno do contrato.</p></div></div>`;
  return shell({ title: "Administração", active: "", back: "#/perfil", eyebrow: "Perfil / Administração", content });
}

function renderLaboratory() {
  const routes = [
    ["Abertura", "#/abertura"], ["Login", "#/entrar"], ["Recuperação", "#/recuperar"], ["Permissão push", "#/permissao-notificacoes"], ["Resumo", "#/resumo"], ["Serviços", "#/servicos"], ["Livelo", "#/livelo"], ["Banco Inter", "#/inter"], ["Cashback", "#/cashback"], ["Compre direto", "#/compre?tab=todas"], ["Produtos", "#/produtos"], ["Pichau", "#/pichau"], ["Alertas", "#/alertas"], ["Perfil", "#/perfil"], ["Aparência", "#/aparencia"], ["Ajuda", "#/ajuda"], ["Relatar problema", "#/relatar-problema"], ["Privacidade", "#/privacidade"], ["Administração", "#/administracao"], ["404", "#/rota-inexistente"],
  ];
  const states = ["success", "loading", "empty", "searchEmpty", "error", "partial", "stale", "offline", "noSync"];
  return `<div class="page"><div class="stack stack--loose"><header class="topbar">${brand()}${button("Voltar ao app", "go-login", "ghost", "arrow")}</header>${pageIntro("Laboratório QA", "Teste cada canto do protótipo.", "Rota fora do produto. Use-a para revisar cobertura, estados, temas e papéis sem precisar repetir o fluxo completo.")}<section class="stack"><div class="split"><div><p class="eyebrow">Rotas</p><h2 class="section-title">Mapa de telas</h2></div><span class="status-marker status-marker--info">${routes.length} destinos</span></div><div class="profile-menu">${routes.map(([label, route]) => `<a class="profile-menu__item" href="${route}" data-route="${route}"><span class="profile-menu__icon">${icon("chevron", "small")}</span><span><strong class="profile-menu__title">${label}</strong><span class="profile-menu__copy">${route}</span></span>${icon("arrow", "small")}</a>`).join("")}</div></section><section class="stack"><p class="eyebrow">Estado de dados</p><h2 class="section-title">Forçar uma resposta</h2><div class="filter-bar">${states.map((state) => `<button class="filter-trigger" type="button" data-demo-state="${state}" aria-pressed="${appState.demo.screenState === state}">${state}</button>`).join("")}</div></section><section class="stack"><p class="eyebrow">Sessão</p><h2 class="section-title">Testar autorização</h2>${actionRow([button("Usuário comum", "set-user-role", "outline", "user"), button("Administrador", "set-admin-role", "primary", "settings"), button(`Tema: ${appState.theme}`, "cycle-theme", "ghost", "sun")])}</section><div class="notice-strip" style="--notice-color:var(--color-danger)">${icon("info")}<p class="notice-strip__copy"><strong>Somente revisão.</strong> Este laboratório não faz parte da navegação do usuário e nenhuma chamada externa é executada.</p></div></div></div>`;
}

function renderNotFound() {
  return `<div class="page page--auth"><div class="page__content"><div class="state-box state-box--danger stack"><span class="eyebrow">404</span><h1 class="screen-title">Esta rota não existe.</h1><p class="body-copy">O endereço solicitado não pertence ao mapa atual do Radar.</p>${buttonLink("Voltar ao Resumo", "#/resumo", "primary", "home")}</div></div></div>`;
}

export function renderOverlay() {
  const overlay = appState.overlay;
  if (!overlay) return "";
  if (overlay.type === "conditions") {
    const sourceItems = overlay.domain === "livelo" ? liveloStores : cashbackStores;
    const item = sourceItems.find((candidate) => candidate.id === overlay.id);
    return `<div class="backdrop" data-backdrop="true"><section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title"><div class="sheet__grabber" aria-hidden="true"></div><header class="sheet__header"><div><p class="eyebrow">Condições completas</p><h2 class="sheet__title" id="sheet-title">${esc(item?.name || "Oferta")}</h2></div>${iconButton("Fechar condições", "close-overlay")}</header><div class="stack"><div class="notice-strip" style="--notice-color:var(--color-info)">${icon("info")}<p class="notice-strip__copy"><strong>Texto do retrato.</strong> O conteúdo abaixo é somente leitura e não é uma regra inventada pelo protótipo.</p></div><p class="body-copy">${esc(item?.description || item?.conditions || "Condições não informadas neste retrato.")}</p>${item?.secondary ? `<div class="surface" style="padding:16px"><p class="eyebrow">Oferta secundária</p><p class="body-copy">${esc(item.secondary)}</p></div>` : ""}</div></section></div>`;
  }
  if (overlay.type === "history") {
    const sourceItems = overlay.domain === "livelo" ? liveloStores : overlay.domain === "pichau" ? pichauItems : productItems;
    const item = sourceItems.find((candidate) => candidate.id === overlay.id);
    return `<div class="backdrop" data-backdrop="true"><section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title"><div class="sheet__grabber" aria-hidden="true"></div><header class="sheet__header"><div><p class="eyebrow">Histórico · últimos 30 dias</p><h2 class="sheet__title" id="sheet-title">${esc(item?.name || "Item acompanhado")}</h2></div>${iconButton("Fechar histórico", "close-overlay")}</header><div class="metric-band"><div class="metric-band__item"><strong class="metric-band__value">${overlay.domain === "livelo" ? "7" : "R$ 3.541"}</strong><span class="metric-band__label">última medição</span></div><div class="metric-band__item"><strong class="metric-band__value">${overlay.domain === "livelo" ? "3" : "R$ 3.699"}</strong><span class="metric-band__label">menor no período</span></div></div><div class="stack" style="margin-top:24px">${historySamples.map((sample) => `<div class="data-row"><div><strong class="data-row__title">${esc(sample.date)}</strong><div class="data-row__meta"><span>Preço ${esc(sample.price)}</span><span>Cashback ${esc(sample.cash)}</span></div></div><strong class="mono">${esc(sample.net)}</strong></div>`).join("")}</div><p class="field__hint" style="margin-top:20px">Sem medições não significa valor zero. Abrir o histórico não inicia coleta.</p></section></div>`;
  }
  if (overlay.type === "external") {
    return dialogFrame("Abrir uma oferta externa", `<div class="stack"><p class="body-copy">Você está saindo do Radar para continuar no serviço de origem. O protótipo não abre uma URL real.</p><div class="surface" style="padding:16px"><p class="eyebrow">Destino simulado</p><strong>${esc(overlay.domain === "livelo" ? "livelo.com.br" : overlay.domain === "pichau" ? "pichau.com.br" : "shopping.inter.co")}</strong></div><div class="form-actions">${button("Simular abertura", "simulate-external", "primary", "external")}${button("Cancelar", "close-overlay", "outline")}</div></div>`);
  }
  if (overlay.type === "filters") {
    let body = "";
    if (overlay.domain === "pichau") body = `<label class="field"><span class="field__label">Disponibilidade</span><select class="select" data-filter-key="pichau.availability"><option>Todas</option><option>Disponíveis</option><option>Esgotados</option></select></label><label class="field"><span class="field__label">Ordenar por</span><select class="select" data-filter-key="pichau.sort"><option>Nome</option><option>Preço Pix</option><option>Desconto</option></select></label>`;
    else if (overlay.domain === "produtos") body = `<label class="field"><span class="field__label">Lojas</span><select class="select" data-filter-key="produtos.stores"><option>Todas as lojas</option><option>Casas Bahia</option><option>Ponto</option></select></label><div class="cluster"><label class="field" style="flex:1"><span class="field__label">Preço mínimo</span><input class="input" inputmode="decimal" data-filter-key="produtos.min" placeholder="R$ 0,00" /></label><label class="field" style="flex:1"><span class="field__label">Preço máximo</span><input class="input" inputmode="decimal" data-filter-key="produtos.max" placeholder="R$ 0,00" /></label></div>`;
    else if (overlay.domain === "cashback") body = `<label class="field"><span class="field__label">Ordenar por</span><select class="select" data-filter-key="cashback.sort"><option>Maior cashback</option><option>Nome A–Z</option><option>Mais recentes</option></select></label>`;
    else body = `<label class="field"><span class="field__label">Categoria</span><select class="select" data-filter-key="livelo.category"><option>Todas</option><option>Casa</option><option>Beleza</option><option>Viagens</option></select></label><label class="field"><span class="field__label">Ordenar por</span><select class="select" data-filter-key="livelo.sort"><option>Mais recentes</option><option>Maior pontuação</option><option>Nome A–Z</option></select></label>`;
    return `<div class="backdrop" data-backdrop="true"><section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title"><div class="sheet__grabber" aria-hidden="true"></div><header class="sheet__header"><div><p class="eyebrow">Folha de filtros</p><h2 class="sheet__title" id="sheet-title">Ajuste sua leitura</h2></div>${iconButton("Fechar filtros", "close-overlay")}</header><form class="stack" data-form="filters" data-domain="${overlay.domain}">${body}<div class="form-actions">${button("Aplicar filtros", "apply-filters", "primary", "check")}${button("Limpar filtros", `clear-filters:${overlay.domain}`, "ghost")}</div></form></section></div>`;
  }
  if (overlay.type === "categories") return renderCategoryOverlay();
  if (overlay.type === "alert-preferences") return dialogFrame("Preferências de alertas", `<form class="stack" data-form="preferences"><p class="body-copy">Escolha quais mudanças podem gerar notificações. O histórico da Central continua independente da permissão de push.</p>${["Livelo", "Cashback Inter", "Produtos Inter", "Pichau"].map((label, index) => `<label class="data-row"><span><strong class="data-row__title">${label}</strong><span class="field__hint">Mudanças válidas nesta origem</span></span><input type="checkbox" name="preference-${index}" ${index < 3 ? "checked" : ""} /></label>`).join("")}<div class="form-actions">${button("Salvar preferências", "save-preferences", "primary", "check")}${button("Cancelar", "close-overlay", "outline")}</div></form>`);
  if (overlay.type === "logout") return dialogFrame("Sair do Radar?", `<div class="stack"><p class="body-copy">O token de notificação da sessão atual será removido. Seus acompanhamentos permanecem vinculados à conta.</p><div class="form-actions">${button("Sair", "logout", "danger", "logout")}${button("Continuar no app", "close-overlay", "outline")}</div></div>`);
  if (overlay.type === "admin-confirm") return renderAdminConfirm(overlay.domain);
  return "";
}

function renderCategoryOverlay() {
  const path = appState.categoryPath;
  const current = path.length ? path[path.length - 1] : "root";
  const options = categories[current] || categories.root;
  return `<div class="backdrop" data-backdrop="true"><section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title"><div class="sheet__grabber" aria-hidden="true"></div><header class="sheet__header"><div><p class="eyebrow">Escolher categoria</p><h2 class="sheet__title" id="sheet-title">${path.length ? esc(path[path.length - 1]) : "Comece por uma área"}</h2></div>${iconButton("Fechar categorias", "close-overlay")}</header><div class="stack"><p class="body-copy">Navegue pelo contexto até um recorte aprovado. Voltar não aplica nada.</p><div class="category-path">${options.map((option) => `<button class="category-path__item" type="button" data-category-option="${encodeURIComponent(option)}">${esc(option)}${icon("chevron", "small")}</button>`).join("")}</div>${path.length ? button("Voltar uma área", "category-back", "ghost", "arrow") : ""}<button class="button button--outline button--block" type="button" data-action="apply-category:Outros / novas categorias">Outros / novas categorias</button></div></section></div>`;
}

function renderAdminConfirm(domain) {
  const isLivelo = domain === "livelo";
  const title = isLivelo ? "Apagar dados da Livelo" : "Resetar dados do Inter";
  const phrase = isLivelo ? "APAGAR LIVELO" : "RESETAR INTER";
  const consequences = isLivelo ? "cadastro, regras, retratos e disparos da Livelo" : "Sites parceiros, Compre direto, seleções, snapshots e histórico";
  return `<div class="backdrop" data-backdrop="true"><section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title"><div class="sheet__grabber" aria-hidden="true"></div><header class="sheet__header"><div><p class="eyebrow">Confirmação protegida</p><h2 class="sheet__title" id="sheet-title">${title}</h2></div>${iconButton("Fechar confirmação", "close-overlay")}</header><form class="stack" data-form="destructive" data-domain="${domain}"><div class="state-box state-box--danger stack stack--tight"><span class="eyebrow">Sem backup no app</span><p class="body-copy">Esta ação remove ${consequences}. Login, tema e dados do outro domínio permanecem.</p><strong>Contagem ilustrativa: ${isLivelo ? "10 lojas acompanhadas" : "2 lojas selecionadas · 36 produtos"}.</strong></div><label class="field"><span class="field__label">Digite ${phrase} para confirmar</span><input class="input" name="phrase" required autocomplete="off" placeholder="${phrase}" /><span class="field__hint">A frase é validada novamente pela API no produto real.</span></label><div class="form-actions">${button("Confirmar ação", "submit-destructive", "danger", "trash")}${button("Cancelar", "close-overlay", "outline")}</div></form></section></div>`;
}

export function renderScreen() {
  const route = routeName(appState.route);
  if (route === "#/abertura" || route === "#/") return renderSplash();
  if (route === "#/entrar") return renderLogin();
  if (route === "#/recuperar") return renderRecover();
  if (route === "#/acesso-negado") return renderAccessDenied();
  if (route === "#/permissao-notificacoes") return renderNotificationPermission();
  if (route === "#/resumo") return renderSummary();
  if (route === "#/servicos") return renderServices();
  if (route === "#/livelo") return renderLivelo();
  if (route === "#/inter") return interHub();
  if (route === "#/cashback") return renderCashback();
  if (route === "#/compre") return renderCompre();
  if (route === "#/produtos") return renderProducts();
  if (route === "#/pichau") return renderPichau();
  if (route === "#/alertas") return renderAlerts();
  if (route === "#/perfil") return renderProfile();
  if (route === "#/aparencia") return renderAppearance();
  if (route === "#/ajuda") return renderHelp();
  if (route === "#/relatar-problema") return renderReport();
  if (route === "#/privacidade") return renderPrivacy();
  if (route === "#/administracao") return renderAdmin();
  if (route === "#/laboratorio") return renderLaboratory();
  return renderNotFound();
}
