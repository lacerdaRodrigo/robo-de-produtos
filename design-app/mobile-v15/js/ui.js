(function (root) {
  "use strict";
  const D = root.RadarData,
    C = root.RadarCore,
    e = C.escape;
  const paths = {
    arrow: '<path d="M5 12h14m-6-6 6 6-6 6"/>',
    back: '<path d="M19 12H5m6-6-6 6 6 6"/>',
    chevron: '<path d="m9 5 7 7-7 7"/>',
    home: '<path d="m3 10 9-7 9 7v10H3V10Z"/><path d="M9 20v-7h6v7"/>',
    explore:
      '<circle cx="12" cy="12" r="9"/><path d="m16 8-2 6-6 2 2-6 6-2Z"/>',
    bookmark: '<path d="M6 4h12v17l-6-4-6 4V4Z"/>',
    bell: '<path d="M5 16h14l-2-3V9a5 5 0 0 0-10 0v4l-2 3Z"/><path d="M10 20h4M12 2v2"/>',
    profile:
      '<circle cx="12" cy="8" r="4"/><path d="M4 21v-2a8 8 0 0 1 16 0v2"/>',
    store:
      '<path d="M4 10v11h16V10M3 4h18l1 6a3 3 0 0 1-5 2 3 3 0 0 1-5 0 3 3 0 0 1-5 0 3 3 0 0 1-5-2l1-6Z"/><path d="M9 21v-6h6v6"/>',
    bag: '<path d="M4 7h16l1 14H3L4 7Z"/><path d="M8 9V6a4 4 0 0 1 8 0v3"/>',
    spark: '<path d="m12 2 3 7 7 3-7 3-3 7-3-7-7-3 7-3 3-7Z"/>',
    desktop:
      '<rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8m-4-4v4M6 7h8"/>',
    search: '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
    close: '<path d="m6 6 12 12M6 18 18 6"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
    tune: '<path d="M4 7h16M4 17h16"/><circle cx="9" cy="7" r="3"/><circle cx="16" cy="17" r="3"/>',
    history: '<path d="M3 4v5h5M3 9a9 9 0 1 1 0 6"/><path d="M12 7v5l3 2"/>',
    external: '<path d="M14 3h7v7m0-7L10 14M9 4H4v16h16v-5"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v6m0-10v.01"/>',
    down: '<path d="M12 4v16m-6-6 6 6 6-6"/>',
    refresh:
      '<path d="M20 4v5h-5M4 20v-5h5M20 9A8 8 0 0 0 5 6m-1 9a8 8 0 0 0 15 3"/>',
    eye: '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 6 9 7 9-7"/>',
    lock: '<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V6a4 4 0 0 1 8 0v4m-4 5v2"/>',
    moon: '<path d="M20 15A9 9 0 0 1 9 4a9 9 0 1 0 11 11Z"/>',
    help: '<circle cx="12" cy="12" r="9"/><path d="M9 9a3 3 0 0 1 6 0c0 2-3 2-3 4m0 4v.01"/>',
    shield:
      '<path d="m12 2 8 3v7c0 5-8 10-8 10S4 17 4 12V5l8-3Z"/><path d="m8 11 3 3 5-6"/>',
    logout: '<path d="M9 4H4v16h5m5-13 5 5-5 5m-5-5h13"/>',
    message: '<path d="M4 4h16v13H9l-5 4V4Z"/><path d="M8 8h8m-8 5h5"/>',
    trash: '<path d="M3 6h18M9 6V3h6v3M6 6l1 15h10l1-15M10 10v7m4-7v7"/>',
    warning: '<path d="m12 3 10 18H2L12 3Z"/><path d="M12 9v5m0 3v.01"/>',
    wifi: '<path d="M3 7a15 15 0 0 1 18 0M6 11a10 10 0 0 1 12 0m-9 4a5 5 0 0 1 6 0m-3 4v.01"/>',
    copy: '<rect x="8" y="8" width="13" height="13" rx="2"/><path d="M16 8V3H3v13h5"/>',
  };
  const icon = (name, cls = "") =>
    `<svg class="icon ${["arrow", "back", "chevron", "logout"].includes(name) ? "directional" : ""} ${cls}" viewBox="0 0 24 24" aria-hidden="true">${paths[name] || paths.info}</svg>`;
  const brand = () =>
    '<span class="brand"><img class="brand-light" src="assets/brand/symbol.svg" alt=""><img class="brand-dark" src="assets/brand/symbol-dark.svg" alt="">radar.</span>';
  const button = (text, action, attrs = "", cls = "") =>
    `<button type="button" class="button ${cls}" data-action="${action}" ${attrs}>${text}</button>`;
  const link = (text, action, attrs = "") =>
    `<button type="button" class="link" data-action="${action}" ${attrs}>${text}</button>`;
  const ib = (name, label, action, attrs = "", cls = "") =>
    `<button type="button" class="icon-button ${cls}" aria-label="${e(label)}" data-action="${action}" ${attrs}>${icon(name)}</button>`;
  const go = (route, text, cls = "") =>
    button(text, "go", `data-route="${route}"`, cls);
  const header = (title, sub = "", action = "") =>
    `<header class="app-header">${ib("back", "Voltar", "back", "", "back")}<div class="header-title">${title}${sub ? `<span class="header-sub">${sub}</span>` : ""}</div>${action}</header>`;
  const frame = (html) => `<section class="screen">${html}</section>`;
  const sectionHead = (title, action = "") =>
    `<div class="section-head"><h2>${title}</h2>${action}</div>`;
  const listRow = (title, subtitle, action, attrs = "", ico = "") =>
    `<button type="button" class="list-row" data-action="${action}" ${attrs}>${ico ? icon(ico) : ""}<span><strong>${title}</strong>${subtitle ? `<small>${subtitle}</small>` : ""}</span>${icon("chevron")}</button>`;
  const notice = (title, body, tone = "") =>
    `<div class="notice ${tone}" role="status">${icon(tone === "error" || tone === "warning" ? "warning" : "info")}<div><strong>${title}</strong>${body}</div></div>`;
  const label = (name, input, hint = "") =>
    `<label class="field">${name}${input}${hint ? `<span class="field-hint">${hint}</span>` : ""}</label>`;
  const select = (name, values, value) =>
    `<select name="${name}">${values.map(([v, t]) => `<option value="${e(v)}" ${String(value) === String(v) ? "selected" : ""}>${e(t)}</option>`).join("")}</select>`;
  const segment = (
    options,
    current,
    action,
    attrs = "",
    ariaLabel = "Visualização",
  ) =>
    `<div class="segmented" role="group" aria-label="${ariaLabel}">${options.map(([value, text]) => `<button type="button" data-action="${action}" data-value="${value}" ${attrs} aria-pressed="${current === value}">${text}</button>`).join("")}</div>`;
  const pagination = (result, scope) =>
    result.pages <= 1
      ? ""
      : `<div class="pagination" aria-label="Paginação">${ib("back", "Página anterior", "page", `data-scope="${scope}" data-page="${result.page - 1}" ${result.page <= 1 ? "disabled" : ""}`)}<span>${result.page} de ${result.pages}</span>${ib("arrow", "Próxima página", "page", `data-scope="${scope}" data-page="${result.page + 1}" ${result.page >= result.pages ? "disabled" : ""}`)}</div>`;
  const itemsFor = (s, domain) =>
    s.cleared.includes(domain) ? [] : D.collections[domain];
  const find = (s, id) =>
    Object.values(D.collections)
      .flat()
      .find((x) => x.id === id && !s.cleared.includes(x.domain));
  const follow = (s, item) =>
    `<button type="button" class="follow-button" data-action="follow" data-id="${e(item.id)}" aria-pressed="${s.following.includes(item.id)}" ${s.pending.has(item.id) ? 'disabled aria-busy="true"' : ""}>${icon(s.pending.has(item.id) ? "refresh" : s.following.includes(item.id) ? "check" : "bell")}${s.pending.has(item.id) ? "Salvando" : s.following.includes(item.id) ? "Acompanhando" : "Acompanhar"}</button>`;
  function empty(kind = "empty", title = "", body = "") {
    const variants = {
      empty: [
        "Nada acompanhado ainda",
        "Escolha uma loja ou produto para colocar no seu radar.",
        "assets/illustrations/acompanhamentos.png",
        "Explorar",
        "go",
        'data-route="explore"',
      ],
      "no-results": [
        "Não encontramos por aqui",
        "Tente outro nome ou amplie os filtros.",
        "assets/illustrations/no-results.svg",
        "Limpar busca e filtros",
        "clear-filters",
        "",
      ],
      "error-empty": [
        "Não foi possível carregar",
        "Tente novamente para consultar os dados disponíveis.",
        "assets/illustrations/offline.svg",
        "Tentar novamente",
        "refresh",
        "",
      ],
      alerts: [
        "Tudo em dia",
        "As próximas mudanças aparecem aqui.",
        "assets/illustrations/acompanhamentos.png",
        "Ver acompanhamentos",
        "go",
        'data-route="watching"',
      ],
    };
    const a = variants[kind] || variants.empty;
    return `<div class="state-view"><img class="${a[2].endsWith(".png") ? "raster" : ""}" src="${a[2]}" alt=""><h2>${title || a[0]}</h2><p>${body || a[1]}</p>${button(a[3], a[4], a[5], "secondary")}</div>`;
  }
  function withState(s, content) {
    if (s.reviewState === "loading")
      return `<div role="status" aria-label="Carregando conteúdo"><div class="skeleton skeleton-title"></div><div class="skeleton skeleton-line"></div><div class="skeleton skeleton-card"></div><div class="skeleton skeleton-card"></div><span class="sr-only">Carregando conteúdo</span></div>`;
    if (["empty", "no-results", "error-empty"].includes(s.reviewState))
      return empty(s.reviewState);
    const notices = {
      refreshing: ["Atualizando", "Os dados anteriores continuam disponíveis."],
      offline: [
        "Você está offline",
        "Exibindo a última atualização disponível.",
      ],
      stale: [
        "Atualização atrasada",
        "Confira o horário em cada origem.",
        "warning",
      ],
      partial: [
        "Atualização parcial",
        "Os últimos dados completos foram preservados.",
        "warning",
      ],
      error: [
        "A atualização falhou",
        "Seu último resultado continua aqui.",
        "error",
      ],
    };
    const n = notices[s.reviewState];
    return (n ? notice(...n) : "") + content;
  }
  function searchForm(s, domain, placeholder) {
    return `<form class="search-form" data-form="search" data-domain="${domain}" role="search" aria-label="Buscar em ${D.domains[domain].name}">${icon("search")}<input name="query" aria-label="Buscar" value="${e(s.filters[domain].query)}" placeholder="${placeholder}" type="search" autocomplete="off"><button type="submit" aria-label="Pesquisar">${icon("arrow")}</button></form>`;
  }
  function storeCard(s, item) {
    const livelo = item.domain === "livelo";
    const value = livelo
      ? item.points == null
        ? "Sem medição"
        : `${C.decimal(item.points)}`
      : item.benefitText;
    const terms =
      item.conditions ||
      "O Inter não informou condições adicionais nesta consulta";
    return `<article class="offer-card" data-item="${e(item.id)}"><div class="card-kicker"><span>${e(item.category)}</span>${item.active ? `<span>${e(item.updated)}</span>` : '<span class="badge warning">Ausente</span>'}</div><h2>${e(item.name)}</h2><div class="benefit"><strong>${e(value)}</strong><span class="qualifier">${livelo ? (item.points == null ? "" : "pontos / R$ 1") : "cashback"}</span></div>${livelo ? `<p class="meta no-margin">Base ${C.decimal(item.base)} pts${item.club != null && item.club > item.points ? ` · Clube ${C.decimal(item.club)} pts` : ""}</p><div class="actions">${item.campaign === "CLUB" ? '<span class="badge">Extra exclusivo do Clube</span>' : item.points > item.base ? '<span class="badge success">Pontuação ampliada</span>' : ""}${item.validity ? `<span class="badge ${item.endsToday ? "warning" : ""}">${item.endsToday ? "Termina hoje" : `Até ${e(item.validity.toLowerCase())}`}</span>` : ""}</div>` : `<p class="meta no-margin">Cliente Inter Shopping</p><p class="store-terms">${e(terms.split("\n")[0])}</p>${item.secondary ? `<p class="meta">${e(item.secondary)}</p>` : ""}`}<div class="card-footer">${follow(s, item)}${link("Condições", "sheet", `data-sheet="conditions" data-id="${item.id}"`)}</div>${livelo ? `<div class="row between">${link(`${icon("history")} Histórico`, "sheet", `data-sheet="history" data-id="${item.id}"`)}${link(`Ir à Livelo ${icon("external", "sm")}`, "external", `data-id="${item.id}"`)}</div>` : link(`Ir para o Inter ${icon("external", "sm")}`, "external", `data-id="${item.id}"`)}</article>`;
  }
  function productCard(s, item) {
    const direct = item.domain === "direct";
    return `<article class="offer-card" data-item="${item.id}"><div class="card-kicker"><span>${e(direct ? item.store : item.externalId)}</span><span>${item.active ? (item.available ? "Disponível" : "Esgotado") : "Fora do catálogo"}</span></div><h2>${e(item.name)}</h2>${direct ? `<p class="meta no-margin">${e(item.brand)} · ${e(item.category)}</p>` : `<div class="spec-line">${e(item.ram)} de memória &nbsp;·&nbsp; ${e(item.storage)}</div>`}<div class="card-price">${item.original && item.price != null ? `<del class="old-price">${C.money(item.original)}</del>` : ""}<strong class="price">${C.money(item.price)}${!direct && item.price != null ? "<small>no Pix</small>" : ""}</strong>${direct ? `<p class="meta">${e(item.benefitText)} de cashback · ${C.money(item.cashback)}<br>Estimativa após cashback: <strong>${C.money(item.net)}</strong></p>` : `<p class="meta">${item.price == null ? "Preço atual indisponível." : `Cartão ${C.money(item.cardPrice)} · ${e(item.discountText)}`}</p>`}</div><div class="card-footer">${follow(s, item)}${link(`Detalhes ${icon("arrow", "sm")}`, "detail", `data-id="${item.id}"`)}</div><p class="meta no-margin">${e(item.updated)}</p></article>`;
  }
  function catalog(s, domain) {
    const config = D.domains[domain],
      f = s.filters[domain];
    const all = C.filterItems(
      itemsFor(s, domain),
      { ...f, groupStore: domain === "direct" },
      s.following,
    );
    const result = C.paginate(all, f.page, 10);
    const titles = {
      partner: "Lojas com cashback",
      livelo: "Lojas e pontos",
      direct: "Produtos por loja",
      pichau: "PCs gamer",
    };
    let lastStore = "";
    const cards = result.items
      .map((item) => {
        const group =
          domain === "direct" && item.store !== lastStore
            ? `<div class="store-group-label"><span>${e(item.store)}</span><span class="meta">${e(item.updated)}</span></div>`
            : "";
        lastStore = item.store;
        return (
          group +
          (["partner", "livelo"].includes(domain)
            ? storeCard(s, item)
            : productCard(s, item))
        );
      })
      .join("");
    const filterLabels = [
      f.category !== "all" ? f.category : null,
      f.store !== "all" ? f.store : null,
      f.availability !== "all"
        ? {
            available: "Disponíveis",
            soldout: "Esgotados",
            out: "Fora do catálogo",
          }[f.availability]
        : null,
      f.min != null || f.max != null ? "Faixa de preço" : null,
    ].filter(Boolean);
    return frame(
      `${header(config.name, config.name === config.source ? "Catálogo" : config.source, ib("refresh", "Atualizar catálogo", "refresh"))}<h1 class="page-title catalog-title">${titles[domain]}</h1>${searchForm(s, domain, ["partner", "livelo"].includes(domain) ? "Qual loja você procura?" : domain === "pichau" ? "Nome, processador ou SKU" : "Produto, marca ou modelo")}${segment(
        [
          ["all", domain === "livelo" ? "Lojas" : "Todos"],
          ["following", "No radar"],
        ],
        f.followed ? "following" : "all",
        "catalog-tab",
        `data-domain="${domain}"`,
      )}<div class="filter-row"><span class="meta">${result.total} ${["partner", "livelo"].includes(domain) ? "lojas" : "produtos"}${filterLabels.length ? `<br>${e(filterLabels.join(" · "))}` : ""}</span><button class="filter-button" data-action="sheet" data-sheet="filters" data-domain="${domain}">${icon("tune")} Filtros${filterLabels.length ? ` (${filterLabels.length})` : ""}</button></div>${withState(s, result.total ? `<div class="catalog">${cards}</div>${pagination(result, domain)}` : empty(f.query || filterLabels.length ? "no-results" : "empty", f.followed ? "Seu radar começa aqui" : "Nenhum item neste recorte"))}`,
    );
  }
  function home(s) {
    const unread = D.events.filter(
      (x) => !s.reads.includes(x.id) && !s.cleared.includes(x.domain),
    );
    return frame(
      `<header class="app-header">${brand()}<button class="icon-button" data-action="go" data-route="alerts" aria-label="Alertas, ${unread.length} não lidos">${icon("bell")}${unread.length ? `<span class="unread-dot">${unread.length}</span>` : ""}</button></header><div class="home-heading"><p class="eyebrow">SEU RADAR, SEU RITMO</p><h1 class="page-title">Boas escolhas começam aqui.</h1><p class="meta"><span class="live-dot"></span>${unread.length ? `${unread.length} mudanças para conferir` : "Tudo lido por enquanto"}</p></div>${sectionHead("Explore as origens", link("Ver todas", "go", 'data-route="explore"'))}<div class="service-rail">${[
        ["inter", "store", "Banco Inter", "Cashback e produtos"],
        ["livelo", "spark", "Livelo", "Pontos em lojas"],
        ["pichau", "desktop", "Pichau", "PCs gamer"],
      ]
        .map(
          ([route, ico, name, sub]) =>
            `<button class="service-tile" data-action="go" data-route="${route}">${icon(ico)}<strong>${name}</strong><span>${sub}</span></button>`,
        )
        .join(
          "",
        )}</div><div class="collection-count"><strong>${s.following.filter((id) => find(s, id)).length}</strong><span class="meta">itens no seu radar</span>${link("Ver lista", "go", 'data-route="watching"')}</div>`,
    );
  }
  function explore() {
    return frame(
      `<header class="app-header">${brand()}<span class="meta">Explorar</span></header><p class="eyebrow">ESCOLHA SEU CAMINHO</p><h1 class="page-title">Uma compra.<br>Mais possibilidades.</h1><p class="lede">Encontre preços e benefícios por origem.</p>${[
        [
          "inter",
          "store",
          "Banco Inter",
          "Cashback em lojas e compra de produtos.",
          "02 experiências",
        ],
        [
          "livelo",
          "spark",
          "Livelo",
          "Lojas parceiras e pontos por real gasto.",
          "Pontos",
        ],
        [
          "pichau",
          "desktop",
          "Pichau",
          "PCs gamer com preço Pix e cartão.",
          "Tecnologia",
        ],
      ]
        .map(
          ([route, ico, name, copy, tag]) =>
            `<button class="feature-choice" data-action="go" data-route="${route}"><div class="row"><span class="large-icon">${icon(ico)}</span><span class="meta">${tag}</span>${icon("arrow")}</div><h2>${name}</h2><p>${copy}</p></button>`,
        )
        .join("")}`,
    );
  }
  function inter() {
    return frame(
      `${header("Banco Inter", "Escolha a experiência")}<h1 class="page-title">Como você<br>quer comprar?</h1><p class="lede">Dois caminhos, cada um com seus benefícios.</p><button class="feature-choice" data-action="go" data-route="partners"><div class="row"><span class="large-icon">${icon("store")}</span>${icon("arrow")}</div><h2>Sites parceiros</h2><p>Descubra o cashback das lojas, confira as condições e acompanhe as mudanças.</p></button><button class="feature-choice" data-action="go" data-route="direct"><div class="row"><span class="large-icon">${icon("bag")}</span>${icon("arrow")}</div><h2>Compre direto</h2><p>Encontre produtos, compare preços e consulte o histórico de cada oferta.</p></button>`,
    );
  }
  function detail(s) {
    const item = find(s, s.params.id);
    if (!item)
      return frame(
        header("Item indisponível") +
          empty(
            "no-results",
            "Este item não está disponível",
            "Volte ao catálogo para escolher outro.",
          ),
      );
    if (["partner", "livelo"].includes(item.domain))
      return frame(
        `${header(item.name, D.domains[item.domain].name)}${withState(s, storeCard(s, item))}`,
      );
    const pichau = item.domain === "pichau";
    return frame(
      `${header("Detalhes", pichau ? "Pichau" : e(item.store), ib("bell", s.following.includes(item.id) ? "Deixar de acompanhar" : "Acompanhar", "follow", `data-id="${item.id}" aria-pressed="${s.following.includes(item.id)}" ${s.pending.has(item.id) ? "disabled" : ""}`))}${withState(s, `<span class="badge ${item.active && item.available ? "success" : "warning"}">${item.active ? (item.available ? "Disponível" : "Esgotado") : "Fora do catálogo"}</span><h1 class="detail-title">${e(item.name)}</h1><p class="meta">${e(item.brand)} · ${e(item.category)}${pichau ? ` · ${e(item.externalId)}` : ""}</p><div class="detail-pricing"><span class="meta">${pichau ? "Preço no Pix" : "Preço de compra"}</span>${item.original && item.price != null ? `<p class="no-margin"><del class="old-price">${C.money(item.original)}</del></p>` : ""}<strong class="price">${C.money(item.price)}</strong><span class="meta">${e(item.updated)}</span></div><dl class="facts">${pichau ? `<div><dt>No cartão</dt><dd>${C.money(item.cardPrice)}</dd></div><div><dt>Desconto no Pix</dt><dd>${e(item.discountText)}</dd></div><div><dt>Processador</dt><dd>${e(item.cpu)}</dd></div><div><dt>Placa de vídeo</dt><dd>${e(item.gpu)}</dd></div><div><dt>Memória / armazenamento</dt><dd>${e(item.ram)} / ${e(item.storage)}</dd></div>` : `<div><dt>Cashback</dt><dd>${e(item.benefitText)} · ${C.money(item.cashback)}</dd></div><div><dt>Estimativa após cashback</dt><dd>${C.money(item.net)}</dd></div><div><dt>Loja</dt><dd>${e(item.store)}</dd></div>`}</dl><p class="meta">${e(item.installment)}</p>${!pichau ? notice("Sobre o cashback", "A estimativa após cashback depende das condições e da elegibilidade. O valor cobrado é o preço de compra.") : ""}<div class="actions">${follow(s, item)}${button(`${icon("history")} Histórico`, "sheet", `data-sheet="history" data-id="${item.id}"`, "secondary")}</div><div class="sticky-action">${button(`${pichau ? "Abrir Pichau" : "Abrir Inter"} ${icon("external")}`, "external", `data-id="${item.id}" ${!item.active ? 'disabled title="Fora do catálogo"' : ""}`, "full")}</div>`)}`,
    );
  }
  function watching(s) {
    const all = s.following.map((id) => find(s, id)).filter(Boolean);
    const filtered = all
      .filter((x) => s.savedDomain === "all" || x.domain === s.savedDomain)
      .filter((x) => C.match(x, s.savedQuery));
    const result = C.paginate(filtered, s.savedPage, 10);
    return frame(
      `<header class="app-header"><h1 class="page-title no-margin">No seu radar</h1>${ib("bell", "Abrir alertas", "go", 'data-route="alerts"')}</header><p class="lede">${all.length} itens acompanhados por você.</p><form class="search-form" data-form="saved-search" role="search">${icon("search")}<input type="search" name="query" aria-label="Buscar nos acompanhamentos" placeholder="Encontre na sua lista" value="${e(s.savedQuery)}"><button aria-label="Pesquisar" type="submit">${icon("arrow")}</button></form><div class="chips" role="group" aria-label="Origem dos acompanhamentos">${[["all", "Todos"], ...Object.entries(D.domains).map(([key, d]) => [key, d.name])].map(([v, t]) => `<button class="chip" data-action="saved-domain" data-value="${v}" aria-pressed="${s.savedDomain === v}">${t}</button>`).join("")}</div>${withState(s, filtered.length ? `<div class="catalog">${result.items.map((item) => (["partner", "livelo"].includes(item.domain) ? storeCard(s, item) : productCard(s, item))).join("")}</div>${pagination(result, "saved")}` : empty(all.length ? "no-results" : "empty"))}`,
    );
  }
  function alerts(s) {
    const a = s.alertFilter;
    const events = D.events.filter(
      (x) =>
        !s.cleared.includes(x.domain) &&
        (a.read === "all" || !s.reads.includes(x.id)) &&
        (a.domain === "all" || x.domain === a.domain) &&
        (a.type === "all" || x.type === a.type),
    );
    const result = C.paginate(events, a.page, 3);
    const cards = result.items
      .map(
        (x) =>
          `<article class="alert-card ${s.reads.includes(x.id) ? "read" : ""}"><div class="row"><span class="alert-marker"></span><div class="grow"><span class="meta">${e(D.domains[x.domain].name)} · ${e(x.time)}</span><h2>${e(x.title)}</h2><p class="meta no-margin">${e(x.name)}</p><div class="alert-values"><del>${e(x.before)}</del>${icon("arrow", "sm")}<strong>${e(x.after)}</strong></div><div class="actions">${link("Ver item", "alert", `data-id="${x.id}"`)}${!s.reads.includes(x.id) ? link("Marcar lido", "read", `data-id="${x.id}"`) : '<span class="meta">Lido</span>'}</div></div></div></article>`,
      )
      .join("");
    return frame(
      `<header class="app-header">${ib("back", "Voltar", "back", "", "back")}<h1 class="page-title no-margin alert-title">Mudou. Você viu.</h1>${ib("tune", "Preferências de alertas", "go", 'data-route="notifications"')}</header><p class="lede">Mudanças nos itens que você acompanha.</p>${segment(
        [
          ["all", "Todos"],
          ["unread", "Não lidos"],
        ],
        a.read,
        "alerts-tab",
      )}<div class="filter-row"><span class="meta">Últimos 90 dias</span><button class="filter-button" data-action="sheet" data-sheet="alert-filters">${icon("tune")} Filtrar</button></div>${link("Marcar todos como lidos", "read-all")}${withState(s, events.length ? cards + pagination(result, "alerts") : empty("alerts"))}`,
    );
  }
  function profile(s) {
    const row = (route, title, sub, ico) =>
      listRow(title, sub, "go", `data-route="${route}"`, ico);
    return frame(
      `<header class="app-header"><span class="eyebrow">SUA CONTA</span>${brand()}</header><div class="profile-summary"><div class="avatar" aria-hidden="true">R</div><div><h1>Olá, Rodrigo.</h1><p class="meta">demo@radar.app</p></div></div><div class="settings-group">${row("watching", "Acompanhamentos", `${s.following.filter((x) => find(s, x)).length} itens no seu radar`, "bookmark")}${row("appearance", "Aparência", { light: "Tema claro", dark: "Tema escuro", system: "Seguir o sistema" }[s.theme], "moon")}${row("notifications", "Notificações", s.prefs.push ? "Ativadas nesta demonstração" : "Escolha o que quer receber", "bell")}</div><p class="group-label">SUPORTE</p><div class="settings-group">${row("help", "Ajuda", "Respostas para usar o Radar", "help")}${row("report", "Relatar problema", "Conte o que aconteceu", "message")}${row("reports", "Meus relatos", `${s.reports.length} registros locais`, "history")}${row("privacy", "Privacidade", "Como seus dados são usados", "shield")}</div>${s.role === "admin" ? `<p class="group-label">GESTÃO</p><div class="settings-group">${row("admin", "Administração", "Operações por domínio", "lock")}</div>` : ""}<div class="actions">${button(`${icon("logout")} Sair da conta`, "sheet", 'data-sheet="logout"', "outline full")}</div><p class="fine-print">Radar de Benefícios · Mobile 15<br>Preços, cashback e pontos em um só lugar.</p>`,
    );
  }
  function appearance(s) {
    return frame(
      `${header("Aparência")}<h1 class="page-title">Do seu jeito.</h1><p class="lede">Uma escolha para todo o aplicativo.</p>${[
        ["system", "Seguir o sistema", "Acompanha a aparência do aparelho."],
        ["light", "Claro", "Luz suave, leitura confortável."],
        ["dark", "Escuro", "Grafite, contraste e menos brilho."],
      ]
        .map(
          ([v, t, sub]) =>
            `<button class="theme-choice" data-action="theme" data-value="${v}" aria-pressed="${s.theme === v}"><span class="theme-swatch ${v}" aria-hidden="true"></span><span class="grow"><strong>${t}</strong><small>${sub}</small></span>${s.theme === v ? icon("check") : ""}</button>`,
        )
        .join(
          "",
        )}${sectionHead("Movimento")}<div class="switch-row"><span><strong>Reduzir animações</strong><p class="meta">Transições mais discretas.</p></span><button class="switch" role="switch" aria-label="Reduzir animações" aria-checked="${s.motion}" data-action="motion"></button></div>`,
    );
  }
  function notifications(s) {
    return frame(
      `${header("Notificações")}<h1 class="page-title">Só o que importa.</h1><p class="lede">A Central continua disponível mesmo sem notificações no aparelho.</p>${[
        [
          "push",
          "Notificações no aparelho",
          "Receber avisos de novas mudanças.",
        ],
        ["price", "Preço", "Aumento ou redução do preço."],
        ["cashback", "Cashback", "Mudanças no benefício publicado."],
        ["points", "Pontos", "Mudanças na pontuação comum."],
      ]
        .map(
          ([key, title, sub]) =>
            `<div class="switch-row"><span><strong>${title}</strong><p class="meta">${sub}</p></span><button class="switch" role="switch" aria-label="${title}" aria-checked="${s.prefs[key]}" data-action="preference" data-key="${key}"></button></div>`,
        )
        .join(
          "",
        )}${button("Rever permissão do aparelho", "sheet", 'data-sheet="permission"', "secondary full")}<p class="fine-print">Acompanhar um item e permitir notificações são escolhas separadas.</p>`,
    );
  }
  function login(s) {
    return frame(
      `<div class="auth">${brand()}<div class="auth-art"><img src="assets/illustrations/descoberta.png" alt="Etiqueta de preço e lente em uma composição de cerâmica"></div><h1 class="page-title">Bom te ver por aqui.</h1><p class="lede">Entre e acompanhe suas próximas escolhas.</p><form data-form="login" novalidate>${label("E-mail", `<input type="email" name="email" autocomplete="username" placeholder="demo@radar.app" value="${e(s.loginEmail)}" required ${s.busy === "login" ? "disabled" : ""}>`)}${label("Senha", `<span class="password-wrap"><input type="${s.showPassword ? "text" : "password"}" name="password" autocomplete="current-password" value="${e(s.loginPassword)}" required placeholder="Sua senha" ${s.busy === "login" ? "disabled" : ""}>${ib("eye", s.showPassword ? "Ocultar senha" : "Mostrar senha", "password")}</span>`)}${s.formError ? `<p class="field-error" role="alert">${e(s.formError)}</p>` : ""}<button class="button full" type="submit" ${s.busy === "login" ? 'disabled aria-busy="true"' : ""}>${s.busy === "login" ? "Entrando…" : "Entrar"} ${icon("arrow")}</button></form><div class="row between">${link("Esqueci minha senha", "go", 'data-route="recovery"')}${link("Explorar demo", "demo")}</div><p class="auth-foot">Demonstração local · use a conta de teste.<br>Seus dados reais de acesso não são necessários.</p></div>`,
    );
  }
  function recovery(s) {
    return frame(
      `${header("Recuperar acesso")}<h1 class="page-title">Vamos te ajudar<br>a voltar.</h1><p class="lede">Informe o e-mail da conta de demonstração.</p><form data-form="recovery" novalidate>${label("E-mail", `<input type="email" name="email" autocomplete="email" value="${e(s.recoveryEmail)}" placeholder="demo@radar.app" required>`)}${s.formError ? `<p class="field-error" role="alert">${e(s.formError)}</p>` : ""}<button class="button full" type="submit" ${s.busy === "recovery" ? "disabled" : ""}>${s.busy === "recovery" ? "Processando…" : "Continuar"}</button></form><p class="fine-print">Este protótipo mostra a jornada de recuperação sem enviar e-mails.</p>`,
    );
  }
  function recoverySent(s) {
    return frame(
      `${header("Recuperar acesso")}<div class="check-success">${icon("check")}</div><h1 class="page-title">Pedido registrado.</h1><p class="lede">Na aplicação conectada, as instruções chegariam em <strong>${e(s.recoveryEmail)}</strong>.</p><div class="report-receipt"><span class="meta">ACESSO DE DEMONSTRAÇÃO</span><strong>demo@radar.app</strong><span class="meta">Senha: radar123</span></div>${go("login", "Voltar para entrar", "full")}`,
    );
  }
  const faqs = [
    [
      "O que o Radar acompanha?",
      "Preços de produtos, cashback de lojas e pontuação de parceiros. Cada origem tem seu próprio catálogo e horário de atualização.",
    ],
    [
      "Por que o preço pode mudar no destino?",
      "O Radar mostra a última informação recebida. A loja pode alterar preço, estoque ou elegibilidade depois. Confira o destino antes de comprar.",
    ],
    [
      "Livelo também tem produtos?",
      "Nesta experiência, a Livelo reúne lojas parceiras e pontos por real gasto. A busca de produtos fica no Compre direto e na Pichau.",
    ],
    [
      "Acompanhar garante uma notificação?",
      "A Central registra mudanças válidas depois que você começa a acompanhar. Para avisos no aparelho, também é necessário permitir notificações e habilitar a preferência.",
    ],
    [
      "Por que aparece “até” no cashback?",
      "Esse é o teto informado pela origem. Produtos, vendedores e condições podem ter percentuais diferentes. Abra as condições completas.",
    ],
    [
      "Buscar atualiza a loja em tempo real?",
      "A busca consulta o catálogo disponível. A atualização de cada origem segue a sua programação; digitar uma busca não inicia uma coleta.",
    ],
  ];
  function help() {
    return frame(
      `${header("Ajuda")}<h1 class="page-title">Pode perguntar.</h1><p class="lede">Respostas para comprar com mais contexto.</p>${faqs.map(([title, body]) => `<details><summary>${title}</summary><p>${body}</p></details>`).join("")}<div class="actions">${go("report", "Ainda preciso de ajuda", "full")}</div>`,
    );
  }
  function privacy() {
    return frame(
      `${header("Privacidade")}<div class="legal"><h1 class="page-title">Você no controle.</h1><h2>O que fica associado à conta</h2><p>Acompanhamentos, preferências de alerta e leitura da Central ajudam a manter sua experiência. O Radar não precisa do seu histórico de compras, saldo bancário ou CPF para consultar ofertas.</p><h2>Histórico e suporte</h2><p>Alertas permanecem disponíveis por até 90 dias. Relatos de problema seguem a retenção de 180 dias na aplicação conectada.</p><h2>Notificações</h2><p>A permissão do aparelho é opcional. Recusar não bloqueia catálogos ou histórico. Ao sair, o aparelho deixa de receber avisos desta sessão.</p><h2>Nesta demonstração</h2><p>Preferências, acompanhamentos e relatos ficam somente neste navegador. Nenhuma senha é gravada. O controle “Restaurar demonstração”, fora do celular, apaga apenas os registros deste protótipo.</p><h2>Falar com a equipe</h2><p>Não inclua senhas, documentos ou informações bancárias no seu relato.</p>${go("report", "Relatar uma dúvida de privacidade", "secondary full")}</div>`,
    );
  }
  function report(s) {
    return frame(
      `${header("Relatar problema")}<h1 class="page-title">O que aconteceu?</h1><p class="lede">Conte o problema e onde você o encontrou.</p><form data-form="report" novalidate>${label(
        "Assunto",
        select(
          "subject",
          [
            ["catalog", "Dados do catálogo"],
            ["access", "Acesso à conta"],
            ["notification", "Notificações"],
            ["privacy", "Privacidade"],
            ["other", "Outro"],
          ],
          s.reportDraft.subject,
        ),
      )}${label("Descrição", `<textarea name="description" maxlength="2000" minlength="10" placeholder="Descreva o que você esperava e o que aconteceu…" required>${e(s.reportDraft.description)}</textarea>`, "De 10 a 2.000 caracteres. Não inclua dados sensíveis.")}${s.formError ? `<p class="field-error" role="alert">${e(s.formError)}</p>` : ""}<button class="button full" type="submit" ${s.busy === "report" ? "disabled" : ""}>${s.busy === "report" ? "Salvando…" : "Registrar relato"}</button></form><p class="fine-print">O relato será salvo localmente para revisar a jornada de suporte.</p>`,
    );
  }
  function reports(s) {
    return frame(
      `${header("Meus relatos")}<h1 class="page-title">Seu retorno importa.</h1>${s.reports.length ? s.reports.map((r) => `<article class="report-receipt"><span class="badge">Registrado localmente</span><strong>${e(r.id)}</strong><p class="meta">${e(r.date)}</p><p>${e(r.description)}</p>${link("Copiar protocolo", "copy", `data-text="${e(r.id)}"`)}</article>`).join("") : empty("empty", "Nenhum relato por aqui", "Os relatos registrados neste navegador aparecem nesta tela.")}${go("report", "Novo relato", "full")}`,
    );
  }
  function admin(s) {
    if (s.role !== "admin")
      return frame(
        `${header("Administração")}${notice("Acesso restrito", "Esta área exige um perfil administrador.", "error")}${go("profile", "Voltar ao perfil", "secondary full")}`,
      );
    return frame(
      `${header("Administração")}<h1 class="page-title">Gestão por domínio.</h1><p class="lede">Operações independentes. Revise as consequências antes de confirmar.</p><div class="notice">${icon("info")}<div>Ambiente de demonstração. Estas ações alteram somente a amostra local.</div></div><div class="danger-zone"><h2>Zona de perigo</h2>${[
        [
          "livelo",
          "Apagar dados da Livelo",
          "Remove lojas, regras, medições e acompanhamentos da Livelo.",
        ],
        [
          "inter",
          "Resetar dados do Inter",
          "Remove Sites parceiros, Compre direto e seus históricos.",
        ],
      ]
        .map(
          ([id, t, b]) =>
            `<article class="report-receipt"><h3>${t}</h3><p class="meta">${b}</p>${button("Revisar operação", "admin-review", `data-domain="${id}"`, "outline full")}</article>`,
        )
        .join("")}</div>`,
    );
  }
  function confirm(s) {
    if (s.role !== "admin") return admin(s);
    const domain = s.params.domain === "livelo" ? "livelo" : "inter";
    const list =
      domain === "livelo"
        ? itemsFor(s, "livelo")
        : [...itemsFor(s, "partner"), ...itemsFor(s, "direct")];
    const phrase = domain === "livelo" ? "APAGAR LIVELO" : "RESETAR INTER";
    return frame(
      `${header("Revisar operação")}<h1 class="page-title">${domain === "livelo" ? "Apagar Livelo" : "Resetar Inter"}?</h1>${notice("Sem restauração automática", "Os dados deste domínio serão removidos da demonstração. Outros domínios, tema e sessão permanecem.", "warning")}<dl class="facts"><div><dt>Itens afetados</dt><dd>${list.length}</dd></div><div><dt>Acompanhamentos</dt><dd>${s.following.filter((id) => list.some((x) => x.id === id)).length}</dd></div></dl><form data-form="admin" novalidate>${label(`Digite ${phrase}`, `<input name="phrase" autocomplete="off" required placeholder="${phrase}">`)}${s.formError ? `<p class="field-error" role="alert">${e(s.formError)}</p>` : ""}<div class="actions">${button("Cancelar", "back", "", "secondary")}<button class="button danger" type="submit" ${s.busy === "admin" ? "disabled" : ""}>${s.busy === "admin" ? "Processando…" : "Confirmar"}</button></div></form>`,
    );
  }
  function launch() {
    return `<div class="launch" role="status" aria-label="Abrindo Radar"><div class="launch-mark"><span class="launch-ring"></span><span class="launch-ring second"></span><img class="brand-light" src="assets/brand/symbol.svg" alt=""><img class="brand-dark" src="assets/brand/symbol-dark.svg" alt=""></div><p class="launch-title">radar.</p><p class="launch-subtitle">Boas escolhas à vista.</p><div class="launch-progress" aria-hidden="true"></div></div>`;
  }

  function history(s, item) {
    const rows = D.history[item.id] || [],
      result = C.paginate(rows, s.sheet.page || 1, 5);
    if (item.domain === "direct") {
      const prices = rows.map((row) => row.price).filter((value) => value != null),
        minimo = prices.length ? Math.min(...prices) : null,
        maximo = prices.length ? Math.max(...prices) : null,
        metrics = (row) =>
          `<dl class="history-metrics"><div><dt>Preço atual</dt><dd>${C.money(row.price)}</dd></div><div class="cashback"><dt>Cashback</dt><dd>${row.cashback == null ? "Não informado" : C.money(row.cashback)}</dd></div><div><dt>Após cashback</dt><dd>${row.net == null ? "Não informado" : C.money(row.net)}</dd></div></dl>`;
      return `${
        minimo == null && maximo == null
          ? ""
          : `<div class="history-summary"><div class="history-summary-card"><span>Mínimo no contrato</span><strong>${C.money(minimo)}</strong></div><div class="history-summary-card"><span>Máximo no contrato</span><strong>${C.money(maximo)}</strong></div></div>`
      }<p class="history-total">${rows.length} ${rows.length === 1 ? "medição" : "medições"} nos últimos 30 dias</p>${rows.length ? result.items.map((row) => `<article class="history-row"><time>${e(row.date)}</time>${metrics(row)}</article>`).join("") + `<p class="history-note">O histórico é paginado e limitado à janela de 30 dias.</p>${pagination(result, "history")}` : empty("empty", "Ainda sem medições", "O histórico aparece depois de uma atualização válida.")}`;
    }
    const isLivelo = item.domain === "livelo",
      isPartner = item.domain === "partner";
    return `<p class="meta">${isLivelo ? "Últimas medições · até 30 registros" : isPartner ? "Medições completas de cashback" : "Medições dos últimos 30 dias"} · somente leitura</p>${rows.length ? result.items.map((r) => `<article class="history-row"><time>${e(r.date)}</time><div class="row between wrap"><strong>${isLivelo ? `${C.decimal(r.points)} pts/R$ 1` : isPartner ? e(r.benefitText) : C.money(r.price)}</strong><span class="badge">${e(r.status)}</span></div>${item.domain === "pichau" ? `<p class="meta no-margin">Cartão ${C.money(r.cardPrice)}</p>` : item.domain === "direct" ? `<p class="meta no-margin">Cashback ${e(r.benefitText)}</p>` : isLivelo && r.club > r.points ? `<p class="meta no-margin">Clube: ${C.decimal(r.club)} pts/R$ 1</p>` : ""}</article>`).join("") + pagination(result, "history") : empty("empty", "Ainda sem medições", "O histórico aparece depois de uma atualização válida.")}`;
  }
  function filters(s, domain) {
    const f = s.filters[domain],
      products = ["direct", "pichau"].includes(domain),
      list = itemsFor(s, domain);
    const categories = [...new Set(list.map((i) => i.category))].sort();
    const sorts =
      domain === "partner"
        ? [
            ["cashback", "Maior cashback"],
            ["name", "Nome da loja"],
          ]
        : domain === "livelo"
          ? [
              ["points", "Maior pontuação"],
              ["name", "Nome da loja"],
              ["validity", "Fim da campanha"],
            ]
          : domain === "pichau"
            ? [
                ["price", "Menor preço Pix"],
                ["name", "Nome"],
                ["discount", "Maior desconto Pix"],
              ]
            : [
                ["price", "Menor preço por loja"],
                ["name", "Nome por loja"],
              ];
    return `<form data-form="filters" data-domain="${domain}" novalidate>${label("Ordenar", select("order", sorts, f.order))}${
      domain === "direct"
        ? label(
            "Loja",
            select(
              "store",
              [
                ["all", "Todas as lojas"],
                ...new Set(list.map((i) => i.store)),
              ].map((x) => (Array.isArray(x) ? x : [x, x])),
              f.store,
            ),
          )
        : ""
    }${
      domain !== "pichau"
        ? label(
            "Categoria",
            select(
              "category",
              [
                ["all", "Todas as categorias"],
                ...categories.map((x) => [x, x]),
              ],
              f.category,
            ),
          )
        : label(
            "Disponibilidade",
            select(
              "availability",
              [
                ["all", "Todos"],
                ["available", "Disponíveis"],
                ["soldout", "Esgotados"],
                ["out", "Fora do catálogo"],
              ],
              f.availability,
            ),
          )
    }${products ? `<div class="form-grid">${label("Preço mínimo (R$)", `<input inputmode="decimal" name="min" value="${f.min == null ? "" : (f.min / 100).toFixed(2)}" placeholder="0,00">`)}${label("Preço máximo (R$)", `<input inputmode="decimal" name="max" value="${f.max == null ? "" : (f.max / 100).toFixed(2)}" placeholder="Sem limite">`)}</div>` : ""}${domain === "livelo" ? `<label class="row"><input type="checkbox" name="campaign" ${f.campaign ? "checked" : ""}> Somente pontuação comum ampliada</label>` : ""}<p class="field-error" id="filter-error" role="alert"></p><div class="sheet-footer">${button("Limpar", "filter-reset", `data-domain="${domain}"`, "secondary")}<button type="submit" class="button">Aplicar filtros</button></div></form>`;
  }
  function sheet(s) {
    if (!s.sheet) return "";
    const sh = s.sheet,
      item = find(s, sh.id);
    let title = "",
      body = "";
    if (sh.type === "filters") {
      title = `Filtros · ${D.domains[sh.domain].name}`;
      body = filters(s, sh.domain);
    }
    let description = "";
    if (sh.type === "history" && item) {
      title = "Histórico de preço";
      description = `${item.name} · ${item.store || D.domains[item.domain].name}`;
      body = history(s, item);
    }
    if (sh.type === "conditions" && item) {
      title = item.name;
      body = `<span class="badge">${D.domains[item.domain].name}</span><h3>Condições da oferta</h3><p class="conditions-copy">${e(item.conditions || "O Inter não informou condições adicionais nesta consulta")}</p>${item.secondary ? `<h3>Para não-correntista</h3><p class="conditions-copy">${e(item.secondary)}</p>` : ""}${item.domain === "livelo" ? `<dl class="facts"><div><dt>Pontuação comum</dt><dd>${C.decimal(item.points)} pts/R$ 1</dd></div><div><dt>Clube</dt><dd>${C.decimal(item.club)} pts/R$ 1</dd></div><div><dt>Validade</dt><dd>${e(item.validity || "Não informada")}</dd></div></dl>` : ""}<p class="meta">${e(item.updated)}</p><div class="sheet-footer">${button(`Abrir ${D.domains[item.domain].source} ${icon("external")}`, "external", `data-id="${item.id}"`)}</div>`;
    }
    if (sh.type === "external" && item) {
      title = `Abrir ${D.domains[item.domain].source}?`;
      body = `<p class="lede">Você será levado ao site oficial para conferir preços e condições.</p><p class="meta">Os itens desta demonstração são ilustrativos. O link abre o portal da origem, sem simular uma oferta real.</p><div class="sheet-footer">${button("Ficar aqui", "close", "", "secondary")}<a class="button" href="${e(C.safeExternal(item.sourceUrl))}" target="_blank" rel="noopener noreferrer" data-action="external-opened">Continuar ${icon("external")}</a></div>`;
    }
    if (sh.type === "logout") {
      title = "Sair do Radar?";
      body = `<p class="lede">Seus acompanhamentos ficam salvos. Os avisos deste aparelho serão desativados.</p><div class="sheet-footer">${button("Cancelar", "close", "", "secondary")}${button("Sair", "logout")}</div>`;
    }
    if (sh.type === "permission") {
      title = "Mudou. Te avisamos.";
      body = `<img class="permission-art" src="assets/illustrations/acompanhamentos.png" alt="" width="240" height="160"><p class="lede">Receba avisos sobre os itens que você acompanha. A Central funciona mesmo se você preferir não receber.</p><p class="meta">Escolha simulada neste protótipo. Nenhuma permissão real será solicitada.</p><div class="sheet-footer">${button("Agora não", "permission", 'data-value="denied"', "secondary")}${button("Permitir", "permission", 'data-value="granted"')}</div>`;
    }
    if (sh.type === "alert-filters") {
      title = "Filtrar mudanças";
      body = `<form data-form="alert-filters">${label("Origem", select("domain", [["all", "Todas as origens"], ...Object.entries(D.domains).map(([key, d]) => [key, d.name])], s.alertFilter.domain))}${label(
        "Tipo de mudança",
        select(
          "type",
          [
            ["all", "Todos os tipos"],
            ["price", "Preço"],
            ["cashback", "Cashback"],
            ["points", "Pontos"],
          ],
          s.alertFilter.type,
        ),
      )}<div class="sheet-footer"><button type="submit" class="button">Aplicar</button></div></form>`;
    }
    if (sh.type === "reset") {
      title = "Restaurar demonstração?";
      body = `<p class="lede">Os acompanhamentos, filtros, preferências e relatos de teste deste protótipo voltarão à amostra inicial.</p><div class="sheet-footer">${button("Cancelar", "close", "", "secondary")}${button("Restaurar", "reset-confirm")}</div>`;
    }
    if (!title) {
      title = "Conteúdo indisponível";
      body = "<p>Este item não está mais nesta amostra.</p>";
    }
    const sheetHeader =
      sh.type === "history"
        ? `<header class="sheet-header sheet-header--history"><div>${ib("back", "Voltar", "close", "", "sheet-back")}</div><div class="sheet-header-main"><h2 id="sheet-title">${e(title)}</h2><p>${e(description)}</p></div><div>${ib("close", "Fechar", "close")}</div></header>`
        : `<header class="sheet-header"><h2 id="sheet-title">${e(title)}</h2>${ib("close", "Fechar", "close")}</header>`;
    return `<div class="scrim" data-action="backdrop"><section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title" tabindex="-1"><div class="sheet-handle" aria-hidden="true"></div>${sheetHeader}${body}</section></div>`;
  }
  const routes = {
    launch: ["Abertura", launch],
    login: ["Entrar", login],
    recovery: ["Recuperar acesso", recovery],
    "recovery-sent": ["Pedido de recuperação", recoverySent],
    home: ["Início", home],
    explore: ["Explorar", explore],
    inter: ["Banco Inter", inter],
    partners: ["Sites parceiros", (s) => catalog(s, "partner")],
    direct: ["Compre direto", (s) => catalog(s, "direct")],
    livelo: ["Livelo", (s) => catalog(s, "livelo")],
    pichau: ["Pichau", (s) => catalog(s, "pichau")],
    detail: ["Detalhe de item", detail],
    watching: ["No seu radar", watching],
    alerts: ["Alertas", alerts],
    profile: ["Perfil", profile],
    appearance: ["Aparência", appearance],
    notifications: ["Notificações", notifications],
    help: ["Ajuda", help],
    privacy: ["Privacidade", privacy],
    report: ["Relatar problema", report],
    reports: ["Meus relatos", reports],
    admin: ["Administração", admin],
    confirm: ["Confirmar operação", confirm],
  };
  function render(s) {
    return (routes[s.route] || routes.home)[1](s);
  }
  function nav(s) {
    if (["launch", "login", "recovery", "recovery-sent"].includes(s.route))
      return "";
    return [
      ["home", "home", "Início"],
      ["explore", "explore", "Explorar"],
      ["watching", "bookmark", "Meu radar"],
      ["profile", "profile", "Perfil"],
    ]
      .map(
        ([r, i, t]) =>
          `<button class="nav-button" data-action="tab" data-route="${r}" ${s.tab === r ? 'aria-current="page"' : ""}><span class="nav-glyph">${icon(i)}</span><span>${t}</span></button>`,
      )
      .join("");
  }
  root.RadarUI = { render, nav, sheet, routes, icon, find, itemsFor, launch };
})(window);
