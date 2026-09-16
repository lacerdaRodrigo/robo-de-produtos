import { appState, isAuthenticatedRoute, setRoute } from "./state.js";

export function readRoute() {
  return window.location.hash || "#/abertura";
}

export function navigate(route) {
  if (window.location.hash === route) {
    setRoute(route);
    window.scrollTo({ top: 0, left: 0, behavior: "auto" });
    document.dispatchEvent(new CustomEvent("radar:render"));
    return;
  }
  window.location.hash = route;
}

export function initializeRouter() {
  setRoute(readRoute());
  window.addEventListener("hashchange", () => {
    setRoute(readRoute());
    window.scrollTo({ top: 0, left: 0, behavior: "auto" });
    document.dispatchEvent(new CustomEvent("radar:render"));
  });
}

export function guardRoute(route) {
  if (isAuthenticatedRoute(route) && !appState.session.authenticated) {
    return "#/entrar";
  }
  return route;
}

export function routeName(route) {
  return route.split("?")[0];
}

export function routeQuery(route) {
  const query = route.split("?")[1] || "";
  return new URLSearchParams(query);
}
