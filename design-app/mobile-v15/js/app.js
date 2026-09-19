(function () {
  "use strict";
  const D = window.RadarData,
    C = window.RadarCore,
    U = window.RadarUI;
  const KEY = "radar-mobile-15",
    SESSION = "radar-mobile-15-session";
  const app = document.querySelector("#app-content"),
    nav = document.querySelector("#bottom-nav"),
    device = document.querySelector("#device"),
    overlay = document.querySelector("#overlay");
  const publicRoutes = ["launch", "login", "recovery", "recovery-sent"];
  const domainRoutes = {
    partners: "partner",
    direct: "direct",
    livelo: "livelo",
    pichau: "pichau",
  };
  const roots = ["home", "explore", "watching", "profile"];
  const freshFilters = (domain) => ({
    query: "",
    followed: false,
    category: "all",
    store: "all",
    availability: "all",
    min: null,
    max: null,
    campaign: false,
    page: 1,
    order:
      domain === "partner"
        ? "cashback"
        : domain === "livelo"
          ? "points"
          : "price",
  });
  const defaults = () => ({
    theme: "light",
    motion: false,
    following: [...D.initialFollowed],
    reads: D.events.filter((x) => x.read).map((x) => x.id),
    prefs: { push: false, price: true, cashback: true, points: true },
    cleared: [],
    reports: [],
    filters: Object.fromEntries(
      Object.keys(D.domains).map((d) => [d, freshFilters(d)]),
    ),
  });
  let saved = {};
  let storageAvailable = true;
  try {
    saved = JSON.parse(localStorage.getItem(KEY) || "{}");
  } catch {
    storageAvailable = false;
  }
  if (!saved || typeof saved !== "object" || Array.isArray(saved)) saved = {};
  const base = defaults();
  const validIds = new Set(
    Object.values(D.collections)
      .flat()
      .map((x) => x.id),
  );
  const s = {
    ...base,
    ...saved,
    route: "launch",
    tab: "home",
    params: {},
    role: "user",
    reviewState: "normal",
    pending: new Set(),
    sheet: null,
    busy: null,
    formError: "",
    loginEmail: "",
    loginPassword: "",
    showPassword: false,
    recoveryEmail: "",
    reportDraft: { subject: "catalog", description: "" },
    savedDomain: "all",
    savedQuery: "",
    savedPage: 1,
    alertFilter: { domain: "all", type: "all", read: "all", page: 1 },
    resume: null,
    session: false,
    stacks: Object.fromEntries(
      roots.map((r) => [r, [{ route: r, params: {}, scroll: 0 }]]),
    ),
    scroll: {},
  };
  s.theme = ["light", "dark", "system"].includes(s.theme) ? s.theme : "light";
  s.following = Array.isArray(saved.following)
    ? saved.following.filter((x) => validIds.has(x))
    : base.following;
  s.reads = Array.isArray(saved.reads)
    ? saved.reads.filter((x) => D.events.some((a) => a.id === x))
    : base.reads;
  s.cleared = Array.isArray(saved.cleared)
    ? saved.cleared.filter((x) => Object.hasOwn(D.domains, x))
    : [];
  s.reports = Array.isArray(saved.reports)
    ? saved.reports
        .filter(
          (x) =>
            x && typeof x.description === "string" && typeof x.id === "string",
        )
        .slice(0, 100)
    : [];
  s.prefs = Object.fromEntries(
    Object.keys(base.prefs).map((k) => [
      k,
      typeof saved.prefs?.[k] === "boolean" ? saved.prefs[k] : base.prefs[k],
    ]),
  );
  s.filters = Object.fromEntries(
    Object.keys(D.domains).map((d) => [
      d,
      { ...freshFilters(d), ...(saved.filters?.[d] || {}) },
    ]),
  );
  s.motion = saved.motion === true;
  try {
    s.session = sessionStorage.getItem(SESSION) === "demo";
  } catch {
    storageAvailable = false;
  }
  let splashTimer,
    toastTimer,
    mutationGeneration = 0,
    transitionTimer,
    scrollTimer;
  let toastUndo = null,
    returnFocus = null;
  const mediaTheme = matchMedia("(prefers-color-scheme: dark)"),
    mediaMotion = matchMedia("(prefers-reduced-motion: reduce)");
  const reduced = () => s.motion || mediaMotion.matches;
  function persist() {
    try {
      localStorage.setItem(
        KEY,
        JSON.stringify({
          theme: s.theme,
          motion: s.motion,
          following: s.following,
          reads: s.reads,
          prefs: s.prefs,
          cleared: s.cleared,
          reports: s.reports,
          filters: s.filters,
        }),
      );
    } catch {
      if (storageAvailable) {
        storageAvailable = false;
        toast(
          "Armazenamento indisponível. Suas escolhas valem para esta sessão.",
        );
      }
    }
  }
  function auth(value) {
    s.session = value;
    try {
      value
        ? sessionStorage.setItem(SESSION, "demo")
        : sessionStorage.removeItem(SESSION);
    } catch {
      /* A sessão em memória continua disponível. */
    }
  }
  function announce(text) {
    document.querySelector("#announcer").textContent = text;
  }
  function toast(text, undo = null) {
    clearTimeout(toastTimer);
    toastUndo = undo;
    document.querySelector("#toast").innerHTML =
      `<span>${C.escape(text)}</span>${undo ? '<button data-action="undo">Desfazer</button>' : ""}`;
    toastTimer = setTimeout(
      () => {
        document.querySelector("#toast").replaceChildren();
        toastUndo = null;
      },
      undo ? 9000 : 5200,
    );
  }
  function applyTheme() {
    device.dataset.theme =
      s.theme === "system" ? (mediaTheme.matches ? "dark" : "light") : s.theme;
    device.dataset.reduceMotion = String(s.motion);
    document
      .querySelectorAll("#review-theme button")
      .forEach((b) =>
        b.setAttribute("aria-pressed", String(b.dataset.theme === s.theme)),
      );
    document.querySelector("#review-motion").checked = s.motion;
  }
  const routeKey = () => s.route + ":" + JSON.stringify(s.params);
  function snapshot() {
    return {
      route: s.route,
      params: { ...s.params },
      tab: s.tab,
      scroll: app.scrollTop,
    };
  }
  function historyState(replace = false) {
    const value = { radar: true, ...snapshot() };
    (replace
      ? history.replaceState.bind(history)
      : history.pushState.bind(history))(value, "");
  }
  function rememberScroll() {
    s.scroll[routeKey()] = app.scrollTop;
    const stack = s.stacks[s.tab];
    if (stack?.length && stack[stack.length - 1].route === s.route)
      stack[stack.length - 1].scroll = app.scrollTop;
  }
  function render({ keepScroll = false, focus = false } = {}) {
    const top = keepScroll ? app.scrollTop : 0;
    applyTheme();
    app.innerHTML = U.render(s);
    nav.innerHTML = U.nav(s);
    app.scrollTop = top;
    document.title = `${U.routes[s.route]?.[0] || "Radar"} · Radar V15`;
    document.querySelector("#review-route").value = s.route;
    document.querySelector("#review-state").value = s.reviewState;
    renderOverlay();
    if (focus && !s.sheet) {
      const heading =
        app.querySelector("h1") || app.querySelector(".header-title");
      if (heading) {
        heading.tabIndex = -1;
        heading.focus({ preventScroll: true });
      }
    }
  }
  function renderOverlay() {
    const expired =
      s.reviewState === "expired" && !publicRoutes.includes(s.route);
    overlay.innerHTML = expired
      ? `<div class="scrim"><section class="session-dialog" role="alertdialog" aria-modal="true" aria-labelledby="expired-title" tabindex="-1"><h2 id="expired-title">Sua sessão expirou.</h2><p>Entre novamente para continuar de onde parou.</p><button class="button full" data-action="reauth">Entrar novamente</button></section></div>`
      : U.sheet(s);
    const modal = Boolean(s.sheet || expired);
    app.inert = modal;
    nav.inert = modal;
  }
  function rootFor(route) {
    if (
      [
        "explore",
        "inter",
        "partners",
        "direct",
        "livelo",
        "pichau",
        "detail",
      ].includes(route)
    )
      return "explore";
    if (
      [
        "profile",
        "appearance",
        "notifications",
        "help",
        "privacy",
        "report",
        "reports",
        "admin",
        "confirm",
      ].includes(route)
    )
      return "profile";
    if (route === "watching") return "watching";
    return "home";
  }
  function assignRoute(route, params = {}) {
    if (["login", "recovery", "report", "admin"].includes(s.busy)) {
      mutationGeneration++;
      s.busy = null;
    }
    if (!Object.hasOwn(U.routes, route)) route = "home";
    if (!s.session && !publicRoutes.includes(route)) {
      s.resume = { route, params, tab: rootFor(route), scroll: 0 };
      route = "login";
      params = {};
    }
    if (["admin", "confirm"].includes(route) && s.role !== "admin")
      route = "admin";
    if (route === "detail" && !params.id) params = { id: "pichau:0-0" };
    s.route = route;
    s.params = params;
    s.formError = "";
    s.sheet = null;
    clearTimeout(splashTimer);
  }
  function go(route, params = {}, options = {}) {
    rememberScroll();
    if (s.sheet) {
      s.sheet = null;
      renderOverlay();
      if (history.state?.overlay)
        history.replaceState({ ...snapshot(), radar: true }, "");
    }
    clearTimeout(transitionTimer);
    if (roots.includes(route) && !options.replace) {
      tab(route);
      return;
    }
    assignRoute(route, params);
    if (!publicRoutes.includes(s.route)) {
      const entry = { route: s.route, params: { ...s.params }, scroll: 0 };
      options.replace
        ? s.stacks[s.tab].splice(-1, 1, entry)
        : s.stacks[s.tab].push(entry);
    }
    render({ focus: true });
    historyState(Boolean(options.replace));
  }
  function tab(route) {
    rememberScroll();
    s.tab = route;
    const entry = s.stacks[route].at(-1);
    assignRoute(entry.route, entry.params);
    render({ focus: true });
    app.scrollTop = entry.scroll || 0;
    historyState();
  }
  function back() {
    if (s.sheet) {
      closeSheet();
      return;
    }
    if (publicRoutes.includes(s.route)) {
      go("login", {}, { replace: true });
      return;
    }
    const stack = s.stacks[s.tab];
    if (stack.length > 1) {
      rememberScroll();
      stack.pop();
      const target = stack.at(-1);
      assignRoute(target.route, target.params);
      render({ focus: true });
      app.scrollTop = target.scroll || 0;
      app.querySelector(".screen")?.classList.add("enter-back");
      historyState(true);
    } else if (s.tab !== "home") tab("home");
  }
  function openSheet(type, extra = {}) {
    const had = s.sheet;
    if (!had) returnFocus = document.activeElement;
    s.sheet = { type, page: 1, ...extra };
    renderOverlay();
    if (!had)
      history.pushState({ radar: true, ...snapshot(), overlay: true }, "");
    overlay.querySelector('[role="dialog"]')?.focus({ preventScroll: true });
  }
  async function closeSheet({ restore = true, historyBack = true } = {}) {
    const layer = overlay.querySelector(".scrim");
    if (!s.sheet) return;
    layer?.classList.add("closing");
    const old = s.sheet;
    await new Promise((r) => setTimeout(r, reduced() ? 0 : 160));
    if (s.sheet !== old) return;
    s.sheet = null;
    renderOverlay();
    if (restore && returnFocus && document.contains(returnFocus))
      returnFocus.focus({ preventScroll: true });
    returnFocus = null;
    if (historyBack && history.state?.overlay) {
      skipNextPop = true;
      history.back();
    }
  }
  let skipNextPop = false;
  window.addEventListener("popstate", (event) => {
    if (skipNextPop) {
      skipNextPop = false;
      return;
    }
    const st = event.state;
    if (!st?.radar) return;
    if (s.sheet) {
      s.sheet = null;
      renderOverlay();
      returnFocus?.focus?.({ preventScroll: true });
      return;
    }
    rememberScroll();
    s.tab = st.tab || rootFor(st.route);
    assignRoute(st.route, st.params);
    const stack = s.stacks[s.tab],
      index = stack.findLastIndex(
        (x) =>
          x.route === s.route &&
          JSON.stringify(x.params) === JSON.stringify(s.params),
      );
    if (index >= 0) stack.splice(index + 1);
    else
      stack.push({
        route: s.route,
        params: { ...s.params },
        scroll: st.scroll || 0,
      });
    render({ focus: true });
    app.scrollTop = st.scroll || 0;
  });
  app.addEventListener(
    "scroll",
    () => {
      clearTimeout(scrollTimer);
      scrollTimer = setTimeout(() => {
        rememberScroll();
        if (!s.sheet) historyState(true);
      }, 100);
    },
    { passive: true },
  );
  async function mutateFollow(id) {
    if (s.pending.has(id) || !U.find(s, id)) return;
    if (!s.session) {
      s.resume = snapshot();
      go("login");
      return;
    }
    const existed = s.following.includes(id),
      generation = mutationGeneration,
      shouldFail =
        ["offline", "error"].includes(s.reviewState) || !navigator.onLine;
    s.pending.add(id);
    s.following = existed
      ? s.following.filter((x) => x !== id)
      : [...s.following, id];
    render({ keepScroll: true });
    await new Promise((r) => setTimeout(r, 480));
    if (generation !== mutationGeneration) return;
    s.pending.delete(id);
    if (shouldFail) {
      s.following = existed
        ? [...new Set([...s.following, id])]
        : s.following.filter((x) => x !== id);
      render({ keepScroll: true });
      toast("Não foi possível salvar. Seu acompanhamento foi restaurado.");
      return;
    }
    persist();
    render({ keepScroll: true });
    toast(
      existed ? "Item removido do seu radar." : "Item adicionado ao seu radar.",
      existed
        ? () => {
            s.following = [...new Set([...s.following, id])];
            persist();
            render({ keepScroll: true });
            toast("Acompanhamento restaurado.");
          }
        : null,
    );
  }
  async function refresh() {
    if (s.busy === "refresh") return;
    s.busy = "refresh";
    s.reviewState = "refreshing";
    render({ keepScroll: true });
    const generation = mutationGeneration;
    await new Promise((r) => setTimeout(r, 650));
    if (generation !== mutationGeneration) return;
    s.busy = null;
    s.reviewState = navigator.onLine ? "normal" : "offline";
    render({ keepScroll: true });
    toast(
      navigator.onLine
        ? "Última amostra disponível exibida."
        : "Sem conexão. Os dados anteriores continuam disponíveis.",
    );
  }
  function clearFilters() {
    const domain = domainRoutes[s.route];
    if (domain) s.filters[domain] = freshFilters(domain);
    if (s.route === "watching") {
      s.savedQuery = "";
      s.savedDomain = "all";
      s.savedPage = 1;
    }
    s.reviewState = "normal";
    persist();
    render({ focus: true });
  }
  function finishLogin() {
    auth(true);
    s.loginPassword = "";
    s.formError = "";
    s.busy = null;
    const target = s.resume || {
      route: "home",
      params: {},
      tab: "home",
      scroll: 0,
    };
    s.resume = null;
    s.tab = target.tab || rootFor(target.route);
    assignRoute(target.route, target.params);
    s.stacks[s.tab] =
      target.route === s.tab
        ? [{ route: s.tab, params: {}, scroll: target.scroll || 0 }]
        : [
            { route: s.tab, params: {}, scroll: 0 },
            {
              route: target.route,
              params: target.params || {},
              scroll: target.scroll || 0,
            },
          ];
    render({ focus: true });
    app.scrollTop = target.scroll || 0;
    historyState(true);
    toast("Bem-vindo ao seu Radar.");
  }
  function launch() {
    if (["login", "recovery", "report", "admin"].includes(s.busy)) {
      mutationGeneration++;
      s.busy = null;
    }
    rememberScroll();
    const target = s.session ? snapshot() : null;
    s.route = "launch";
    s.params = {};
    s.sheet = null;
    render();
    clearTimeout(splashTimer);
    splashTimer = setTimeout(
      () => {
        if (s.route !== "launch") return;
        assignRoute(
          target?.route && !publicRoutes.includes(target.route)
            ? target.route
            : s.session
              ? "home"
              : "login",
          target?.params || {},
        );
        render({ focus: true });
        historyState(true);
      },
      reduced() ? 120 : 1650,
    );
  }
  function setRole(role) {
    s.role = role === "admin" ? "admin" : "user";
    if (s.role !== "admin" && ["admin", "confirm"].includes(s.route))
      s.route = "profile";
    render({ keepScroll: true });
  }
  document.addEventListener("click", async (event) => {
    const el = event.target.closest("[data-action]");
    if (!el || el.disabled) return;
    const action = el.dataset.action;
    if (action === "backdrop") {
      if (event.target === el) await closeSheet();
      return;
    }
    if (action === "go") go(el.dataset.route);
    else if (action === "tab") tab(el.dataset.route);
    else if (action === "back") back();
    else if (action === "detail") go("detail", { id: el.dataset.id });
    else if (action === "sheet")
      openSheet(el.dataset.sheet, {
        id: el.dataset.id,
        domain: el.dataset.domain,
      });
    else if (action === "close") await closeSheet();
    else if (action === "follow") await mutateFollow(el.dataset.id);
    else if (action === "undo") {
      const undo = toastUndo;
      toastUndo = null;
      undo?.();
    } else if (action === "refresh") await refresh();
    else if (action === "external")
      openSheet("external", { id: el.dataset.id });
    else if (action === "external-opened") {
      await closeSheet();
      toast("O portal foi aberto em outra aba.");
    } else if (action === "catalog-tab") {
      const f = s.filters[el.dataset.domain];
      f.followed = el.dataset.value === "following";
      f.page = 1;
      persist();
      render();
    } else if (action === "page") {
      const page = Number(el.dataset.page),
        scope = el.dataset.scope;
      if (scope === "history") {
        s.sheet.page = page;
        renderOverlay();
        overlay.querySelector(".sheet")?.focus({ preventScroll: true });
      } else {
        if (scope === "saved") s.savedPage = page;
        else if (scope === "alerts") s.alertFilter.page = page;
        else if (s.filters[scope]) s.filters[scope].page = page;
        persist();
        render({ focus: true });
        announce(`Página ${page}`);
      }
    } else if (action === "filter-reset") {
      const old = s.filters[el.dataset.domain];
      s.filters[el.dataset.domain] = {
        ...freshFilters(el.dataset.domain),
        query: old.query,
        followed: old.followed,
      };
      persist();
      render({ keepScroll: true });
      overlay.querySelector('[role="dialog"]')?.focus();
    } else if (action === "clear-filters") clearFilters();
    else if (action === "saved-domain") {
      s.savedDomain = el.dataset.value;
      s.savedPage = 1;
      render();
    } else if (action === "alerts-tab") {
      s.alertFilter.read = el.dataset.value;
      s.alertFilter.page = 1;
      render();
    } else if (action === "read") {
      s.reads = [...new Set([...s.reads, el.dataset.id])];
      persist();
      render({ keepScroll: true });
      toast("Alerta marcado como lido.");
    } else if (action === "read-all") {
      s.reads = D.events.map((x) => x.id);
      persist();
      render({ keepScroll: true });
      toast("Todos os alertas foram marcados como lidos.");
    } else if (action === "alert") {
      const item = D.events.find((x) => x.id === el.dataset.id);
      if (!item) return;
      s.reads = [...new Set([...s.reads, item.id])];
      persist();
      go("detail", { id: item.itemId });
    } else if (action === "theme") {
      s.theme = el.dataset.value;
      persist();
      render({ keepScroll: true });
      toast("Aparência atualizada.");
    } else if (action === "motion") {
      s.motion = !s.motion;
      persist();
      render({ keepScroll: true });
    } else if (action === "preference") {
      if (el.dataset.key === "push" && !s.prefs.push) openSheet("permission");
      else {
        s.prefs[el.dataset.key] = !s.prefs[el.dataset.key];
        persist();
        render({ keepScroll: true });
        announce("Preferência salva.");
      }
    } else if (action === "permission") {
      s.prefs.push = el.dataset.value === "granted";
      persist();
      await closeSheet();
      render({ keepScroll: true });
      toast(
        s.prefs.push
          ? "Avisos ativados nesta demonstração."
          : "Sem avisos no aparelho. A Central continua disponível.",
      );
    } else if (action === "logout") {
      await closeSheet();
      mutationGeneration++;
      s.pending.clear();
      s.busy = null;
      auth(false);
      s.prefs.push = false;
      s.loginPassword = "";
      s.loginEmail = "";
      s.resume = null;
      s.reviewState = "normal";
      s.stacks = Object.fromEntries(
        roots.map((r) => [r, [{ route: r, params: {}, scroll: 0 }]]),
      );
      persist();
      go("login", {}, { replace: true });
      toast("Você saiu desta sessão.");
    } else if (action === "password") {
      const input = app.querySelector("[name=password]");
      s.showPassword = !s.showPassword;
      if (input) input.type = s.showPassword ? "text" : "password";
      el.setAttribute(
        "aria-label",
        s.showPassword ? "Ocultar senha" : "Mostrar senha",
      );
    } else if (action === "demo") {
      if (!s.busy) finishLogin();
    } else if (action === "reauth") {
      s.resume = snapshot();
      s.reviewState = "normal";
      auth(false);
      s.sheet = null;
      go("login", {}, { replace: true });
    } else if (action === "admin-review") {
      if (s.role !== "admin") {
        toast("Acesso restrito a administradores.");
        return;
      }
      go("confirm", { domain: el.dataset.domain });
    } else if (action === "copy") {
      try {
        await navigator.clipboard.writeText(el.dataset.text);
        toast("Protocolo copiado.");
      } catch {
        toast(`Protocolo: ${el.dataset.text}`);
      }
    } else if (action === "reset-confirm") {
      await closeSheet();
      mutationGeneration++;
      Object.assign(s, defaults());
      s.pending = new Set();
      s.busy = null;
      s.sheet = null;
      s.savedDomain = "all";
      s.savedQuery = "";
      s.savedPage = 1;
      s.alertFilter = { domain: "all", type: "all", read: "all", page: 1 };
      s.reportDraft = { subject: "catalog", description: "" };
      s.reviewState = "normal";
      s.resume = null;
      s.stacks = Object.fromEntries(
        roots.map((r) => [r, [{ route: r, params: {}, scroll: 0 }]]),
      );
      persist();
      auth(false);
      go("login", {}, { replace: true });
      toast("Demonstração restaurada.");
    }
  });
  document.addEventListener("input", (event) => {
    const form = event.target.closest("form");
    if (!form) return;
    if (form.dataset.form === "login") {
      if (event.target.name === "email") s.loginEmail = event.target.value;
      if (event.target.name === "password")
        s.loginPassword = event.target.value;
    }
    if (form.dataset.form === "recovery" && event.target.name === "email")
      s.recoveryEmail = event.target.value;
    if (form.dataset.form === "report") {
      if (event.target.name === "description")
        s.reportDraft.description = event.target.value;
      if (event.target.name === "subject")
        s.reportDraft.subject = event.target.value;
    }
  });
  document.addEventListener("submit", async (event) => {
    const form = event.target;
    if (!form.matches("form[data-form]")) return;
    event.preventDefault();
    const type = form.dataset.form,
      data = new FormData(form);
    if (["login", "recovery", "report", "admin"].includes(type) && s.busy)
      return;
    if (type === "search") {
      const domain = form.dataset.domain;
      s.filters[domain].query = String(data.get("query") || "").trim();
      s.filters[domain].page = 1;
      s.reviewState = "normal";
      persist();
      render({ focus: true });
      announce("Resultados atualizados.");
    }
    if (type === "saved-search") {
      s.savedQuery = String(data.get("query") || "");
      s.savedPage = 1;
      render({ focus: true });
    }
    if (type === "filters") {
      const domain = form.dataset.domain,
        min = C.parseMoney(data.get("min")),
        max = C.parseMoney(data.get("max"));
      if (
        Number.isNaN(min) ||
        Number.isNaN(max) ||
        (min != null && max != null && min > max)
      ) {
        const err = document.querySelector("#filter-error");
        err.textContent =
          "Use valores válidos. O preço máximo deve ser maior ou igual ao mínimo.";
        err.tabIndex = -1;
        err.focus();
        return;
      }
      const oldQuery = s.filters[domain].query,
        oldFollowed = s.filters[domain].followed;
      s.filters[domain] = {
        ...freshFilters(domain),
        query: oldQuery,
        followed: oldFollowed,
        order: data.get("order") || "price",
        category: data.get("category") || "all",
        store: data.get("store") || "all",
        availability: data.get("availability") || "all",
        min,
        max,
        campaign: data.has("campaign"),
        page: 1,
      };
      persist();
      await closeSheet({ restore: false });
      render({ focus: true });
      announce("Filtros aplicados.");
    }
    if (type === "alert-filters") {
      s.alertFilter = {
        ...s.alertFilter,
        domain: data.get("domain"),
        type: data.get("type"),
        page: 1,
      };
      await closeSheet({ restore: false });
      render({ focus: true });
    }
    if (type === "login") {
      s.loginEmail = String(data.get("email") || "").trim();
      s.loginPassword = String(data.get("password") || "");
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.loginEmail)) {
        s.formError = "Informe um e-mail válido.";
        render({ keepScroll: true });
        app.querySelector("[name=email]")?.focus();
        return;
      }
      if (!s.loginPassword) {
        s.formError = "Informe sua senha.";
        render({ keepScroll: true });
        app.querySelector("[name=password]")?.focus();
        return;
      }
      const generation = mutationGeneration;
      s.busy = "login";
      s.formError = "";
      render({ keepScroll: true });
      await new Promise((r) => setTimeout(r, 550));
      if (generation !== mutationGeneration) return;
      s.busy = null;
      if (["offline", "error"].includes(s.reviewState) || !navigator.onLine) {
        s.formError =
          "Não foi possível entrar. Confira a conexão e tente novamente.";
        render({ keepScroll: true });
        return;
      }
      if (
        s.loginEmail.toLowerCase() !== "demo@radar.app" ||
        s.loginPassword !== "radar123"
      ) {
        s.formError =
          "Acesso não reconhecido. Use demo@radar.app e a senha radar123.";
        render({ keepScroll: true });
        return;
      }
      finishLogin();
    }
    if (type === "recovery") {
      s.recoveryEmail = String(data.get("email") || "").trim();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.recoveryEmail)) {
        s.formError = "Informe um e-mail válido.";
        render({ keepScroll: true });
        return;
      }
      s.busy = "recovery";
      s.formError = "";
      render({ keepScroll: true });
      const generation = mutationGeneration;
      await new Promise((r) => setTimeout(r, 450));
      if (generation !== mutationGeneration) return;
      s.busy = null;
      if (["offline", "error"].includes(s.reviewState) || !navigator.onLine) {
        s.formError = "Conexão indisponível. Tente novamente.";
        render({ keepScroll: true });
        return;
      }
      go("recovery-sent");
    }
    if (type === "report") {
      const description = String(data.get("description") || "").trim();
      s.reportDraft = { subject: String(data.get("subject")), description };
      if (description.length < 10 || description.length > 2000) {
        s.formError = "Descreva o problema usando de 10 a 2.000 caracteres.";
        render({ keepScroll: true });
        return;
      }
      s.busy = "report";
      s.formError = "";
      render({ keepScroll: true });
      const generation = mutationGeneration;
      await new Promise((r) => setTimeout(r, 450));
      if (generation !== mutationGeneration) return;
      s.busy = null;
      if (["offline", "error"].includes(s.reviewState) || !navigator.onLine) {
        s.formError = "Não foi possível enviar. Seu texto foi preservado.";
        render({ keepScroll: true });
        return;
      }
      const id = `RAD-${Date.now().toString(36).toUpperCase()}`;
      s.reports.unshift({
        id,
        description,
        subject: s.reportDraft.subject,
        date: new Date().toLocaleString("pt-BR"),
      });
      s.reportDraft = { subject: "catalog", description: "" };
      persist();
      go("reports");
      toast("Relato salvo localmente. Protocolo disponível.");
    }
    if (type === "admin") {
      if (s.role !== "admin" || !s.session) {
        s.formError = "Esta operação exige perfil administrador.";
        render();
        return;
      }
      const domain = s.params.domain === "livelo" ? "livelo" : "inter",
        phrase = domain === "livelo" ? "APAGAR LIVELO" : "RESETAR INTER";
      if (String(data.get("phrase") || "").trim() !== phrase) {
        s.formError = `Digite exatamente ${phrase}.`;
        render({ keepScroll: true });
        return;
      }
      s.busy = "admin";
      s.formError = "";
      render({ keepScroll: true });
      const generation = mutationGeneration;
      await new Promise((r) => setTimeout(r, 650));
      if (generation !== mutationGeneration) return;
      s.busy = null;
      if (
        s.role !== "admin" ||
        !s.session ||
        ["offline", "error"].includes(s.reviewState)
      ) {
        s.formError = "Operação não concluída. Os dados foram preservados.";
        render({ keepScroll: true });
        return;
      }
      const affected = domain === "livelo" ? ["livelo"] : ["partner", "direct"];
      s.cleared = [...new Set([...s.cleared, ...affected])];
      s.following = s.following.filter(
        (id) => !affected.includes(id.split(":")[0]),
      );
      persist();
      go("admin", {}, { replace: true });
      toast(
        "A amostra deste domínio foi removida. Outros dados foram preservados.",
      );
    }
  });
  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && s.sheet) {
      event.preventDefault();
      closeSheet();
    }
    if (event.altKey && event.key === "ArrowLeft") {
      event.preventDefault();
      back();
    }
    if (event.key === "Tab" && (s.sheet || s.reviewState === "expired")) {
      const dialog = overlay.querySelector(
        '[role="dialog"],[role="alertdialog"]',
      );
      const elements = [
        ...dialog.querySelectorAll(
          "a[href],button:not([disabled]),input:not([disabled]),select,textarea",
        ),
      ].filter((x) => x.getClientRects().length);
      const first = elements[0],
        last = elements.at(-1);
      if (!first) {
        event.preventDefault();
        dialog.focus();
        return;
      }
      if (
        event.shiftKey &&
        (document.activeElement === first || document.activeElement === dialog)
      ) {
        event.preventDefault();
        last.focus();
      } else if (
        !event.shiftKey &&
        (document.activeElement === last ||
          !dialog.contains(document.activeElement))
      ) {
        event.preventDefault();
        first.focus();
      }
    }
  });
  const routeSelect = document.querySelector("#review-route");
  routeSelect.innerHTML = Object.entries(U.routes)
    .map(([key, [title]]) => `<option value="${key}">${title}</option>`)
    .join("");
  routeSelect.addEventListener("change", () => {
    if (!publicRoutes.includes(routeSelect.value)) auth(true);
    s.tab = rootFor(routeSelect.value);
    s.reviewState = "normal";
    if (routeSelect.value === "launch") launch();
    else
      go(
        routeSelect.value,
        routeSelect.value === "confirm" ? { domain: "livelo" } : {},
        { replace: true },
      );
  });
  document
    .querySelector("#review-state")
    .addEventListener("change", (event) => {
      s.reviewState = event.target.value;
      s.sheet = null;
      render({ keepScroll: true });
      if (s.reviewState === "expired")
        overlay.querySelector('[role="alertdialog"]')?.focus();
    });
  document.querySelector("#review-theme").addEventListener("click", (event) => {
    const b = event.target.closest("[data-theme]");
    if (b) {
      s.theme = b.dataset.theme;
      persist();
      render({ keepScroll: true });
    }
  });
  document
    .querySelector("#review-width")
    .addEventListener("change", (event) =>
      document
        .querySelector(".workspace")
        .style.setProperty("--device-width", `${event.target.value}px`),
    );
  document
    .querySelector("#review-scale")
    .addEventListener("change", (event) => {
      device.style.setProperty("--text-scale", event.target.value);
      device.dataset.scale = event.target.value;
    });
  document
    .querySelector("#review-role")
    .addEventListener("change", (event) => setRole(event.target.value));
  document
    .querySelector("#review-motion")
    .addEventListener("change", (event) => {
      s.motion = event.target.checked;
      persist();
      applyTheme();
    });
  document.querySelector("#review-rtl").addEventListener("change", (event) => {
    device.dir = event.target.checked ? "rtl" : "ltr";
  });
  document.querySelector("#replay").addEventListener("click", launch);
  document
    .querySelector("#reset-demo")
    .addEventListener("click", () => openSheet("reset"));
  mediaTheme.addEventListener("change", () => {
    if (s.theme === "system") applyTheme();
  });
  window.addEventListener("offline", () => {
    s.reviewState = "offline";
    render({ keepScroll: true });
  });
  window.addEventListener("online", () => {
    if (s.reviewState === "offline") {
      s.reviewState = "normal";
      render({ keepScroll: true });
      toast("Conexão restabelecida.");
    }
  });
  const query = new URLSearchParams(location.search),
    screen = query.get("screen");
  if (["light", "dark", "system"].includes(query.get("theme")))
    s.theme = query.get("theme");
  if (["320", "390", "430"].includes(query.get("width"))) {
    document
      .querySelector(".workspace")
      .style.setProperty("--device-width", `${query.get("width")}px`);
    document.querySelector("#review-width").value = query.get("width");
  }
  if (["1", "1.3", "2"].includes(query.get("text"))) {
    device.style.setProperty("--text-scale", query.get("text"));
    device.dataset.scale = query.get("text");
    document.querySelector("#review-scale").value = query.get("text");
  }
  if (query.get("role") === "admin") {
    s.role = "admin";
    document.querySelector("#review-role").value = "admin";
  }
  if (query.get("motion") === "reduce") s.motion = true;
  if (query.get("dir") === "rtl") {
    device.dir = "rtl";
    document.querySelector("#review-rtl").checked = true;
  }
  if (screen && Object.hasOwn(U.routes, screen) && screen !== "launch") {
    if (!publicRoutes.includes(screen)) auth(true);
    s.tab = rootFor(screen);
    assignRoute(screen, {
      ...(query.get("id") ? { id: query.get("id") } : {}),
      ...(screen === "confirm" ? { domain: "livelo" } : {}),
    });
  }
  if (
    [...document.querySelector("#review-state").options].some(
      (o) => o.value === query.get("state"),
    )
  )
    s.reviewState = query.get("state");
  render();
  historyState(true);
  if (s.route === "launch") launch();
  if (!storageAvailable)
    toast("Armazenamento indisponível. Suas escolhas valem para esta sessão.");
  window.RadarPrototype = {
    snapshot: () => ({
      route: s.route,
      params: { ...s.params },
      theme: s.theme,
      following: [...s.following],
      reads: [...s.reads],
      filters: structuredClone(s.filters),
      prefs: { ...s.prefs },
      cleared: [...s.cleared],
      reportCount: s.reports.length,
      session: s.session,
      role: s.role,
    }),
    routes: Object.keys(U.routes),
  };
})();
