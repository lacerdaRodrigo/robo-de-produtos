import { appState, markAlert, markAllAlerts, resetSession, setRoute, setTheme, setToast, toggleFollow } from "./state.js";
import { categories } from "./data.js";
import { icon } from "./components/index.js";
import { renderOverlay, renderScreen } from "./screens/index.js";
import { guardRoute, initializeRouter, navigate, routeName } from "./router.js";

const app = document.querySelector("#app");
const overlayRoot = document.querySelector("#overlay-root");
const toastRoot = document.querySelector("#toast-root");
let searchTimer;
let hasRendered = false;

function applyTheme() {
  const systemDark = window.matchMedia?.("(prefers-color-scheme: dark)").matches;
  const resolved = appState.theme === "system" ? (systemDark ? "dark" : "light") : appState.theme;
  document.documentElement.dataset.theme = resolved;
  document.documentElement.dataset.themeChoice = appState.theme;
}

function renderToast() {
  toastRoot.innerHTML = appState.toast ? `<div class="toast" role="status">${appState.toast}</div>` : "";
}

function renderApp() {
  const guarded = guardRoute(appState.route);
  if (guarded !== appState.route) {
    navigate(guarded);
    return;
  }
  applyTheme();
  app.innerHTML = renderScreen();
  overlayRoot.innerHTML = renderOverlay();
  renderToast();
  const main = document.querySelector("#main-content");
  if (main && hasRendered && document.activeElement === document.body) {
    main.focus({ preventScroll: true });
    window.scrollTo({ top: 0, left: 0, behavior: "auto" });
  }
  hasRendered = true;
}

function refresh() {
  renderApp();
}

function closeOverlay() {
  appState.overlay = null;
  renderApp();
}

function completeAsync(message, callback) {
  setToast(message);
  window.setTimeout(() => {
    callback();
    renderApp();
  }, 700);
}

function parseAction(value) {
  const [action, ...parts] = value.split(":");
  return { action, parts };
}

function updateFilter(key, value) {
  const [domain, field] = key.split(".");
  if (appState.filters[domain] && field) appState.filters[domain][field] = value;
}

function handleAction(value, element) {
  const { action, parts } = parseAction(value);
  if (action === "close-overlay") return closeOverlay();
  if (action === "go-login") return navigate("#/entrar");
  if (action === "toggle-password") {
    const input = document.querySelector('input[name="password"]');
    if (!input) return;
    const showing = input.type === "text";
    input.type = showing ? "password" : "text";
    element.setAttribute("aria-label", showing ? "Mostrar senha" : "Ocultar senha");
    element.innerHTML = icon(showing ? "eye" : "eyeOff");
    return;
  }
  if (action === "logout") {
    resetSession();
    navigate("#/entrar");
    setToast("Sessão encerrada. O token de notificação atual foi removido.");
    return;
  }
  if (action === "confirm-logout") {
    appState.overlay = { type: "logout" };
    return refresh();
  }
  if (action === "allow-notifications") {
    appState.notification = "allowed";
    setToast("Permissão simulada. A Central continua disponível.");
    return navigate("#/resumo");
  }
  if (action === "deny-notifications") {
    appState.notification = "denied";
    setToast("Tudo certo. Você continua com acesso ao histórico.");
    return navigate("#/resumo");
  }
  if (action === "refresh-summary" || action === "request-refresh" || action === "retry-demo") {
    appState.demo.screenState = "loading";
    refresh();
    return window.setTimeout(() => {
      appState.demo.screenState = "success";
      setToast("Retrato atualizado no protótipo.");
      refresh();
    }, 700);
  }
  if (action === "open-filters") {
    appState.overlay = { type: "filters", domain: parts[0] };
    return refresh();
  }
  if (action === "clear-filters") {
    const domain = parts[0];
    if (domain === "livelo") appState.filters.livelo = { category: "Todas", sort: "Mais recentes" };
    if (domain === "cashback") appState.filters.cashback = { sort: "Maior cashback" };
    if (domain === "produtos") appState.filters.produtos = { stores: "Todas as lojas", min: "", max: "" };
    if (domain === "pichau") appState.filters.pichau = { availability: "Todas", sort: "Nome" };
    return refresh();
  }
  if (action === "clear-search") {
    const domain = parts[0];
    if (domain in appState.search) appState.search[domain] = "";
    appState.pages[domain] = 1;
    setToast("Busca limpa.");
    return refresh();
  }
  if (action === "apply-filters") {
    const form = element.closest("form");
    form?.querySelectorAll("[data-filter-key]").forEach((input) => updateFilter(input.dataset.filterKey, input.value));
    appState.overlay = null;
    setToast("Filtros aplicados. A página voltou ao início.");
    refresh();
    return;
  }
  if (action === "open-conditions") {
    appState.overlay = { type: "conditions", domain: parts[0], id: parts[1] };
    return refresh();
  }
  if (action === "open-history") {
    appState.overlay = { type: "history", domain: parts[0], id: parts[1] };
    return refresh();
  }
  if (action === "open-external") {
    appState.overlay = { type: "external", domain: parts[0], id: parts[1] };
    return refresh();
  }
  if (action === "simulate-external") {
    appState.overlay = null;
    setToast("Abertura externa simulada com segurança.");
    return refresh();
  }
  if (action === "open-alert-preferences") {
    appState.overlay = { type: "alert-preferences" };
    return refresh();
  }
  if (action === "save-preferences") {
    appState.overlay = null;
    setToast("Preferências de alertas salvas no protótipo.");
    return refresh();
  }
  if (action === "mark-all-alerts") {
    markAllAlerts();
    setToast("Todos os alertas foram marcados como lidos.");
    return refresh();
  }
  if (action === "read-alert") {
    const id = parts[0];
    const alert = appState.alerts.find((item) => item.id === id);
    const wasRead = Boolean(alert?.read);
    markAlert(id, !wasRead);
    setToast(wasRead ? "Alerta marcado como não lido." : "Alerta marcado como lido.");
    return refresh();
  }
  if (action === "open-categories") {
    appState.categoryPath = [];
    appState.overlay = { type: "categories" };
    return refresh();
  }
  if (action === "category-back") {
    appState.categoryPath.pop();
    return refresh();
  }
  if (action === "apply-category") {
    const category = parts.join(":");
    if (category === "Outros / novas categorias") {
      appState.selectedCategories = [category];
    } else if (!appState.selectedCategories.includes(category)) {
      appState.selectedCategories.push(category);
    }
    appState.categoryPath = [];
    appState.overlay = null;
    setToast("Área adicionada ao recorte.");
    return refresh();
  }
  if (action === "remove-category") {
    const category = decodeURIComponent(parts.join(":"));
    appState.selectedCategories = appState.selectedCategories.filter((item) => item !== category);
    return refresh();
  }
  if (action === "clear-categories") {
    appState.selectedCategories = [];
    setToast("Áreas removidas.");
    return refresh();
  }
  if (action === "quick-category") {
    const category = decodeURIComponent(parts.join(":"));
    appState.search.produtos = category;
    appState.pages.produtos = 1;
    setToast(`Busca rápida: ${category}.`);
    return refresh();
  }
  if (action === "toggle-store") {
    const id = parts[0];
    if (appState.selectedStores.has(id)) appState.selectedStores.delete(id);
    else appState.selectedStores.add(id);
    setToast("Seleção de loja atualizada.");
    return refresh();
  }
  if (action === "set-user-role") {
    appState.session.role = "user";
    setToast("Laboratório: usuário comum.");
    return refresh();
  }
  if (action === "set-admin-role") {
    appState.session.role = "admin";
    setToast("Laboratório: administrador.");
    return refresh();
  }
  if (action === "cycle-theme") {
    const order = ["light", "dark", "system"];
    setTheme(order[(order.indexOf(appState.theme) + 1) % order.length]);
    return refresh();
  }
  if (action === "open-admin-confirm") {
    appState.overlay = { type: "admin-confirm", domain: parts[0] };
    return refresh();
  }
  if (action === "submit-destructive") {
    const form = element.closest("form");
    const expected = form?.dataset.domain === "livelo" ? "APAGAR LIVELO" : "RESETAR INTER";
    const phrase = form?.querySelector("[name=phrase]")?.value.trim();
    if (phrase !== expected) {
      setToast("A frase não confere. Nada foi alterado.");
      return;
    }
    appState.overlay = null;
    setToast("Operação simulada com sucesso. Nenhum dado real foi excluído.");
    return refresh();
  }
}

function handleTab(element) {
  const action = element.dataset.tabAction;
  const value = element.dataset.tabValue;
  if (action === "compre") {
    appState.tabs.compre = value;
    return navigate(`#/compre?tab=${value}`);
  }
  appState.tabs[action] = value;
  appState.pages[action] = 1;
  refresh();
}

function handlePage(element) {
  const domain = element.dataset.pageDomain;
  appState.pages[domain] = Number(element.dataset.page) || 1;
  setToast(`Página ${appState.pages[domain]} exibida.`);
  refresh();
}

function handleCategoryOption(element) {
  const option = decodeURIComponent(element.dataset.categoryOption);
  if (categories[option]) {
    appState.categoryPath.push(option);
    return refresh();
  }
  appState.selectedCategories = appState.selectedCategories.filter((item) => item !== "Outros / novas categorias");
  if (!appState.selectedCategories.includes(option)) appState.selectedCategories.push(option);
  appState.categoryPath = [];
  appState.overlay = null;
  setToast(`${option} adicionado ao recorte.`);
  refresh();
}

function handleForm(form) {
  if (!form.reportValidity()) return;
  const formData = new FormData(form);
  if (form.dataset.form === "login") {
    const email = String(formData.get("email") || "").trim();
    const password = String(formData.get("password") || "");
    if (password.length < 4) return setToast("Use uma senha com pelo menos 4 caracteres.");
    if (email.includes("sem-convite")) return navigate("#/acesso-negado");
    appState.session.authenticated = true;
    appState.session.email = email;
    appState.session.name = email.split("@")[0] || "Rodrigo";
    return navigate(appState.notification === "unknown" ? "#/permissao-notificacoes" : "#/resumo");
  }
  if (form.dataset.form === "recover") {
    setToast("Se o endereço estiver cadastrado, as instruções serão enviadas.");
    return navigate("#/entrar");
  }
  if (form.dataset.form === "report") {
    completeAsync("Enviando relato no protótipo...", () => setToast("Relato registrado no protótipo. Nenhuma API foi chamada."));
    form.reset();
    return;
  }
  if (form.dataset.form === "preferences") return handleAction("save-preferences", form.querySelector("button[data-action=save-preferences]"));
  if (form.dataset.form === "filters") return handleAction("apply-filters", form.querySelector("button[data-action=apply-filters]"));
  if (form.dataset.form === "destructive") return handleAction("submit-destructive", form.querySelector("button[data-action=submit-destructive]"));
}

document.addEventListener("click", (event) => {
  const backdrop = event.target.closest("[data-backdrop]");
  if (backdrop && event.target === backdrop) return closeOverlay();
  const categoryOption = event.target.closest("[data-category-option]");
  if (categoryOption) return handleCategoryOption(categoryOption);
  const tab = event.target.closest("[data-tab-action]");
  if (tab) return handleTab(tab);
  const page = event.target.closest("[data-page-domain]");
  if (page) return handlePage(page);
  const follow = event.target.closest("[data-follow-domain]");
  if (follow) {
    const followed = toggleFollow(follow.dataset.followDomain, follow.dataset.followId);
    setToast(followed ? "Item adicionado aos acompanhados." : "Item removido dos acompanhados.");
    return refresh();
  }
  const theme = event.target.closest("[data-theme-value]");
  if (theme) {
    setTheme(theme.dataset.themeValue);
    setToast(`Tema ${theme.dataset.themeValue === "system" ? "do sistema" : theme.dataset.themeValue} aplicado.`);
    return refresh();
  }
  const demoState = event.target.closest("[data-demo-state]");
  if (demoState) {
    appState.demo.screenState = demoState.dataset.demoState;
    setToast(`Estado de revisão: ${demoState.dataset.demoState}.`);
    return refresh();
  }
  const action = event.target.closest("[data-action]");
  if (action) return handleAction(action.dataset.action, action);
});

document.addEventListener("input", (event) => {
  const search = event.target.closest("[data-search]");
  if (!search) return;
  appState.search[search.dataset.search] = search.value;
  clearTimeout(searchTimer);
  searchTimer = window.setTimeout(refresh, 260);
});

document.addEventListener("change", (event) => {
  const input = event.target.closest("[data-filter-key]");
  if (input) updateFilter(input.dataset.filterKey, input.value);
});

document.addEventListener("submit", (event) => {
  event.preventDefault();
  handleForm(event.target);
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && appState.overlay) closeOverlay();
});

document.addEventListener("radar:render", renderApp);
window.matchMedia?.("(prefers-color-scheme: dark)").addEventListener?.("change", () => {
  if (appState.theme === "system") renderApp();
});

initializeRouter();
renderApp();
