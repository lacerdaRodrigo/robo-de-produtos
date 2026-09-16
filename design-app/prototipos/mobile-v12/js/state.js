import { alerts, cashbackStores, liveloStores, pichauItems, productItems } from "./data.js";

const clone = (value) => JSON.parse(JSON.stringify(value));

export const appState = {
  session: { authenticated: false, role: "user", name: "Rodrigo", email: "" },
  theme: "light",
  notification: "unknown",
  route: "#/abertura",
  overlay: null,
  toast: null,
  demo: {
    screenState: "success",
    loading: false,
    offline: false,
  },
  search: {
    livelo: "",
    cashback: "",
    produtos: "",
    pichau: "",
  },
  tabs: {
    livelo: "todas",
    cashback: "todas",
    compre: "todas",
    pichau: "todas",
    alerts: "todas",
  },
  pages: {
    livelo: 1,
    cashback: 1,
    produtos: 1,
    pichau: 1,
    alerts: 1,
  },
  filters: {
    livelo: { category: "Todas", sort: "Mais recentes" },
    cashback: { sort: "Maior cashback" },
    produtos: { stores: "Todas as lojas", min: "", max: "" },
    pichau: { availability: "Todas", sort: "Nome" },
  },
  followed: {
    livelo: new Set(liveloStores.filter((item) => item.followed).map((item) => item.id)),
    cashback: new Set(cashbackStores.filter((item) => item.followed).map((item) => item.id)),
    produtos: new Set(productItems.filter((item) => item.followed).map((item) => item.id)),
    pichau: new Set(pichauItems.filter((item) => item.followed).map((item) => item.id)),
  },
  alerts: clone(alerts),
  categoryPath: [],
  selectedCategories: [],
  selectedStores: new Set(["store-1", "store-2"]),
};

export function setRoute(route) {
  appState.route = route;
}

export function setTheme(theme) {
  appState.theme = theme;
}

export function setToast(message) {
  appState.toast = message;
  window.clearTimeout(setToast.timeout);
  setToast.timeout = window.setTimeout(() => {
    appState.toast = null;
    document.dispatchEvent(new CustomEvent("radar:render"));
  }, 3200);
}

export function toggleFollow(domain, id) {
  const collection = appState.followed[domain];
  if (!collection) return false;
  if (collection.has(id)) {
    collection.delete(id);
    return false;
  }
  collection.add(id);
  return true;
}

export function markAlert(id, read = true) {
  const item = appState.alerts.find((alert) => alert.id === id);
  if (item) item.read = read;
}

export function markAllAlerts() {
  appState.alerts.forEach((alert) => { alert.read = true; });
}

export function resetCatalogView(domain) {
  appState.pages[domain] = 1;
}

export function resetSession() {
  appState.session.authenticated = false;
  appState.session.email = "";
  appState.notification = "unknown";
  appState.overlay = null;
}

export function isAuthenticatedRoute(route) {
  return ["#/resumo", "#/servicos", "#/livelo", "#/inter", "#/cashback", "#/compre", "#/produtos", "#/pichau", "#/alertas", "#/perfil", "#/aparencia", "#/ajuda", "#/relatar-problema", "#/privacidade", "#/administracao", "#/admin/livelo", "#/admin/inter", "#/permissao-notificacoes"].some((prefix) => route.startsWith(prefix));
}
