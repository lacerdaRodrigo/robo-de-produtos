const paths = {
  arrow: '<path d="M19 12H5m7 7-7-7 7-7"/>',
  chevron: '<path d="m9 18 6-6-6-6"/>',
  check: '<path d="m5 12 4 4L19 6"/>',
  close: '<path d="M6 6l12 12M18 6 6 18"/>',
  search: '<circle cx="11" cy="11" r="6.5"/><path d="m16 16 4 4"/>',
  user: '<circle cx="12" cy="8" r="3.2"/><path d="M5 20c.8-3.2 3.2-5 7-5s6.2 1.8 7 5"/>',
  home: '<path d="m4 10 8-6 8 6v9H4z"/><path d="M9 19v-5h6v5"/>',
  layers: '<path d="m4 8 8-4 8 4-8 4zM4 12l8 4 8-4M4 16l8 4 8-4"/>',
  bell: '<path d="M18 9a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 22h4"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m9.4 9.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4m9.4-9.4 1.4-1.4"/>',
  moon: '<path d="M20 15.5A8.5 8.5 0 0 1 8.5 4 8.5 8.5 0 1 0 20 15.5z"/>',
  settings: '<path d="M12 15.2a3.2 3.2 0 1 0 0-6.4 3.2 3.2 0 0 0 0 6.4z"/><path d="m19.4 15 .1.1-1.8 3.1-.2-.1-1.8-1a8 8 0 0 1-1.8 1.1V20H10v-1.8a8 8 0 0 1-1.8-1.1l-1.8 1-.2.1-1.8-3.1.1-.1 1.7-1a8 8 0 0 1 0-2.1l-1.7-1-.1-.1 1.8-3.1.2.1 1.8 1A8 8 0 0 1 10 7.7V6h3.8v1.7a8 8 0 0 1 1.8 1.1l1.8-1 .2-.1 1.8 3.1-.1.1-1.7 1a8 8 0 0 1 0 2.1z"/>',
  info: '<circle cx="12" cy="12" r="9"/><path d="M12 11v5m0-8v.1"/>',
  refresh: '<path d="M20 11a8 8 0 0 0-14.7-4L3 10m0-4v4h4M4 13a8 8 0 0 0 14.7 4L21 14m0 4v-4h-4"/>',
  filter: '<path d="M4 6h16M7 12h10m-7 6h4"/>',
  sort: '<path d="M8 5v14m0 0-3-3m3 3 3-3M16 19V5m0 0-3 3m3-3 3 3"/>',
  history: '<path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 5v5h5M12 7v5l3 2"/>',
  external: '<path d="M14 5h5v5m0-5-7 7"/><path d="M18 13v5H5V5h5"/>',
  lock: '<rect x="5" y="10" width="14" height="10" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
  help: '<circle cx="12" cy="12" r="9"/><path d="M9.6 9a2.6 2.6 0 1 1 4.5 1.8c-1.2 1-2.1 1.3-2.1 3m0 3v.1"/>',
  flag: '<path d="M5 21V4m0 0c4-3 6 3 14 0v9c-8 3-10-3-14 0"/>',
  shield: '<path d="M12 3 5 6v5c0 4.3 2.5 7.5 7 10 4.5-2.5 7-5.7 7-10V6z"/><path d="m9 12 2 2 4-4"/>',
  logout: '<path d="M10 5H5v14h5m4-4 4-3-4-3m4 3H9"/>',
  key: '<circle cx="8" cy="15" r="3"/><path d="m10.5 12.5 6.5-6.5m-2 2 2 2m-4 0 2 2"/>',
  eye: '<path d="M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12z"/><circle cx="12" cy="12" r="2.5"/>',
  eyeOff: '<path d="m3 3 18 18M10.6 6.2A10 10 0 0 1 12 6c6.5 0 10 6 10 6a17 17 0 0 1-3.1 3.7M6.5 6.6C3.6 8.2 2 12 2 12s3.5 6 10 6a9.8 9.8 0 0 0 3-.5"/>',
  trash: '<path d="M4 7h16m-10 4v6m4-6v6M9 7V4h6v3m-9 0 1 14h10l1-14"/>',
  zap: '<path d="m13 2-8 11h6l-1 9 8-11h-6z"/>',
};

const escapeAttribute = (value = "") => String(value).replace(/[&<>'"]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[char]);

export function icon(name, size = "") {
  return `<svg class="icon ${size ? `icon--${size}` : ""}" viewBox="0 0 24 24" aria-hidden="true">${paths[name] || paths.info}</svg>`;
}

export function brand() {
  return `<a class="brand-lockup" href="#/abertura" data-route="#/abertura" aria-label="Radar de Benefícios, início"><span class="brand-lockup__mark"><span>R</span></span><span>Radar de Benefícios</span></a>`;
}

export function button(label, action, variant = "outline", iconName = "") {
  return `<button class="button button--${variant}" type="button" data-action="${action}">${iconName ? icon(iconName, "small") : ""}<span>${label}</span></button>`;
}

export function routeButton(label, route, variant = "outline", iconName = "") {
  return `<a class="button button--${variant}" href="${route}" data-route="${route}">${iconName ? icon(iconName, "small") : ""}<span>${label}</span></a>`;
}

export function iconButton(label, action, iconName = "close", extra = "") {
  return `<button class="icon-button ${extra}" type="button" data-action="${action}" aria-label="${label}">${icon(iconName)}</button>`;
}

export function sourceMark(source) {
  return `<span class="source-mark source-mark--${source}" aria-hidden="true"></span>`;
}

export function statusMarker(label, tone = "good") {
  return `<span class="status-marker status-marker--${tone}">${label}</span>`;
}

export function signalLine(label, tone = "good") {
  return `<span class="signal-line source-${tone === "danger" ? "pichau" : tone === "info" ? "cashback" : "livelo"}"><span class="signal-line__track" aria-hidden="true"></span>${label}</span>`;
}

export function searchField(domain, value, placeholder) {
  return `<label class="search-field"><span class="sr-only">${placeholder}</span>${icon("search")}<input class="input" type="search" value="${escapeAttribute(value)}" placeholder="${escapeAttribute(placeholder)}" data-search="${escapeAttribute(domain)}" autocomplete="off" /></label>`;
}

export function tabs(items, active, action) {
  return `<div class="tab-row" role="tablist">${items.map((item) => `<button class="tab" type="button" role="tab" aria-selected="${item.id === active}" data-tab-action="${action}" data-tab-value="${item.id}">${item.label}</button>`).join("")}</div>`;
}

export function followControl(domain, id, followed) {
  return `<button class="follow-control" type="button" data-follow-domain="${domain}" data-follow-id="${id}" aria-pressed="${followed}" aria-label="${followed ? "Deixar de acompanhar" : "Acompanhar"}">${icon("bell", "small")}<span>${followed ? "Acompanhando" : "Acompanhar"}</span></button>`;
}

export function pagination(domain, page, totalPages = 2) {
  if (totalPages <= 1) return "";
  return `<nav class="pagination" aria-label="Paginação"><button class="button button--ghost" type="button" data-page-domain="${domain}" data-page="${Math.max(1, page - 1)}" ${page <= 1 ? "disabled" : ""}>${icon("arrow", "small")} Anterior</button><div class="pagination__pages">${Array.from({ length: totalPages }, (_, index) => `<button class="page-number" type="button" data-page-domain="${domain}" data-page="${index + 1}" aria-current="${page === index + 1 ? "page" : "false"}">${index + 1}</button>`).join("")}</div><button class="button button--ghost" type="button" data-page-domain="${domain}" data-page="${Math.min(totalPages, page + 1)}" ${page >= totalPages ? "disabled" : ""}>Próxima ${icon("chevron", "small")}</button></nav>`;
}

export function stateBox(state, domain, retryAction) {
  const configs = {
    loading: { tone: "info", title: "Atualizando o retrato", copy: "Os dados anteriores continuam visíveis enquanto a nova resposta chega." },
    empty: { tone: "info", title: "Ainda não há itens aqui", copy: "Quando uma fonte publicar dados válidos, eles aparecem nesta área." },
    searchEmpty: { tone: "info", title: "Nenhum resultado para esta busca", copy: "Tente outro termo. A busca não altera o acompanhamento por conta própria." },
    stale: { tone: "warning", title: "Este retrato está atrasado", copy: "A última coleta válida continua disponível. O atraso não transforma seus dados em zero." },
    partial: { tone: "warning", title: "Retrato parcial", copy: "A coleta não terminou. O último retrato completo continua sendo preservado." },
    error: { tone: "danger", title: "Não foi possível atualizar", copy: "O último retrato válido continua na tela. Tente novamente quando quiser." },
    offline: { tone: "warning", title: "Você está sem conexão", copy: "O que já foi carregado continua disponível; novas páginas aguardam conexão." },
    noSync: { tone: "info", title: "Nenhuma coleta concluída", copy: "Ainda não existe retrato válido para este domínio." },
  };
  const config = configs[state] || configs.empty;
  return `<section class="state-box state-box--${config.tone}" aria-live="polite"><div class="stack stack--tight"><span class="eyebrow">Estado do retrato</span><h2 class="section-title">${config.title}</h2><p class="body-copy">${config.copy}</p>${retryAction ? button("Tentar novamente", retryAction, "dark", "refresh") : ""}</div></section>`;
}

export function shell({ title, route, content, active = "resumo", back = "", eyebrow = "Radar de Benefícios" }) {
  const showBack = back ? `<a class="icon-button" href="${back}" data-route="${back}" aria-label="Voltar">${icon("arrow")}</a>` : "";
  return `<div class="page"><header class="topbar"><div class="topbar__context">${showBack}<div><p class="eyebrow">${eyebrow}</p><h1 class="sr-only">${title}</h1></div></div><a class="profile-button" href="#/perfil" data-route="#/perfil" aria-label="Abrir Perfil"><span class="avatar">RS</span><span class="sr-only">Perfil</span>${icon("user", "small")}</a></header><main id="main-content" tabindex="-1">${content}</main>${bottomNav(active)}</div>`;
}

export function bottomNav(active) {
  return `<nav class="bottom-nav" aria-label="Navegação principal"><a class="bottom-nav__item" href="#/resumo" data-route="#/resumo" aria-current="${active === "resumo" ? "page" : "false"}">${icon("home")}<span>Resumo</span></a><a class="bottom-nav__item" href="#/servicos" data-route="#/servicos" aria-current="${active === "servicos" ? "page" : "false"}">${icon("layers")}<span>Serviços</span></a></nav>`;
}

export function pageIntro(eyebrow, title, copy = "") {
  return `<div class="stack stack--tight"><p class="eyebrow">${eyebrow}</p><h2 class="screen-title">${title}</h2>${copy ? `<p class="body-copy">${copy}</p>` : ""}</div>`;
}

export function sheetFrame(title, content, action = "close-overlay") {
  return `<div class="backdrop" data-backdrop="true"><section class="sheet" role="dialog" aria-modal="true" aria-labelledby="sheet-title"><div class="sheet__grabber" aria-hidden="true"></div><header class="sheet__header"><h2 class="sheet__title" id="sheet-title">${title}</h2>${iconButton("Fechar", action)}</header>${content}</section></div>`;
}

export function dialogFrame(title, content, action = "close-overlay") {
  return `<div class="backdrop" data-backdrop="true"><section class="dialog" role="dialog" aria-modal="true" aria-labelledby="dialog-title"><header class="dialog__header"><h2 class="dialog__title" id="dialog-title">${title}</h2>${iconButton("Fechar", action)}</header>${content}</section></div>`;
}
