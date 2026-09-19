(function (root) {
  "use strict";
  const normalize = (value) =>
    String(value || "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/ponto\s*frio|pontofrio/g, "ponto")
      .replace(/celulares|celular/g, "smartphone")
      .replace(/[^a-z0-9 ]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  const tokens = (value) =>
    normalize(value)
      .split(" ")
      .filter(
        (word) =>
          word &&
          !["de", "da", "do", "das", "dos", "com", "e", "o", "a"].includes(
            word,
          ),
      );
  const match = (item, query) =>
    tokens(query).every((term) =>
      normalize(
        [
          item.name,
          item.brand,
          item.store,
          item.externalId,
          item.slug,
          item.category,
        ].join(" "),
      ).includes(term),
    );
  const money = (cents) =>
    cents == null
      ? "Não informado"
      : new Intl.NumberFormat("pt-BR", {
          style: "currency",
          currency: "BRL",
        }).format(cents / 100);
  const decimal = (value) =>
    value == null
      ? "—"
      : new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 2 }).format(
          value,
        );
  const parseMoney = (value) => {
    const text = String(value || "").trim();
    if (!text) return null;
    if (!/^\d+(?:[.,]\d{1,2})?$/.test(text)) return NaN;
    const [integer, fraction = ""] = text.replace(",", ".").split(".");
    const cents = Number(integer) * 100 + Number(fraction.padEnd(2, "0"));
    return Number.isSafeInteger(cents) ? cents : NaN;
  };
  const compareNullable = (a, b, direction = 1) =>
    a == null ? (b == null ? 0 : 1) : b == null ? -1 : direction * (a - b);
  const byName = (a, b) =>
    a.name.localeCompare(b.name, "pt-BR") || a.id.localeCompare(b.id);
  function filterItems(items, filter = {}, followed = []) {
    const set = new Set(followed);
    const selected = items.filter(
      (item) =>
        match(item, filter.query) &&
        (!filter.followed || set.has(item.id)) &&
        (!filter.category ||
          filter.category === "all" ||
          item.category === filter.category) &&
        (!filter.store ||
          filter.store === "all" ||
          item.store === filter.store) &&
        (filter.min == null ||
          (item.price != null && item.price >= filter.min)) &&
        (filter.max == null ||
          (item.price != null && item.price <= filter.max)) &&
        (!filter.campaign ||
          (item.points != null && item.points > item.base)) &&
        (!filter.availability ||
          filter.availability === "all" ||
          (filter.availability === "available"
            ? item.active && item.available
            : filter.availability === "soldout"
              ? item.active && item.available === false
              : !item.active)),
    );
    return selected.sort((a, b) => {
      const group = filter.groupStore
        ? a.store.localeCompare(b.store, "pt-BR")
        : 0;
      if (group) return group;
      if (filter.order === "name") return byName(a, b);
      if (filter.order === "cashback")
        return (
          Number(!a.active) - Number(!b.active) ||
          compareNullable(
            a.benefit > 0 ? a.benefit : null,
            b.benefit > 0 ? b.benefit : null,
            -1,
          ) ||
          byName(a, b)
        );
      if (filter.order === "points")
        return compareNullable(a.points, b.points, -1) || byName(a, b);
      if (filter.order === "validity")
        return (
          compareNullable(
            a.validity ? a.validityOrder : null,
            b.validity ? b.validityOrder : null,
          ) || byName(a, b)
        );
      if (filter.order === "discount")
        return compareNullable(a.discount, b.discount, -1) || byName(a, b);
      return compareNullable(a.price, b.price) || byName(a, b);
    });
  }
  function paginate(items, page = 1, size = 10) {
    const pages = Math.max(1, Math.ceil(items.length / size));
    const current = Math.min(pages, Math.max(1, Number(page) || 1));
    return {
      items: items.slice((current - 1) * size, current * size),
      page: current,
      pages,
      total: items.length,
      size,
    };
  }
  function safeExternal(url) {
    try {
      const u = new URL(url);
      return u.protocol === "https:" &&
        [
          "shopping.inter.co",
          "www.livelo.com.br",
          "www.pichau.com.br",
        ].includes(u.hostname) &&
        !u.username &&
        !u.password
        ? u.href
        : null;
    } catch {
      return null;
    }
  }
  const escape = (value) =>
    String(value ?? "").replace(
      /[&<>"']/g,
      (c) =>
        ({
          "&": "&amp;",
          "<": "&lt;",
          ">": "&gt;",
          '"': "&quot;",
          "'": "&#39;",
        })[c],
    );
  const api = {
    normalize,
    match,
    money,
    decimal,
    parseMoney,
    filterItems,
    paginate,
    safeExternal,
    escape,
  };
  root.RadarCore = api;
  if (typeof module !== "undefined") module.exports = api;
})(typeof window !== "undefined" ? window : globalThis);
