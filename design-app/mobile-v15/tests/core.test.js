const { test } = require("node:test");
const assert = require("node:assert/strict");
const C = require("../js/core.js");
const D = require("../js/data.js");

test("Busca tolera acentos e sinônimo aprovado sem misturar variantes", () => {
  const matches = C.filterItems(D.collections.direct, {
    query: "celular MOTOROLA edge 60 pro 512",
    groupStore: true,
  });
  assert.equal(matches.length, 2);
  assert.ok(matches.every((x) => x.name.includes("512 GB")));
  assert.ok(
    C.match(
      D.collections.partner.find((x) => x.slug === "cea"),
      "C&A",
    ),
  );
  assert.ok(
    C.match(
      D.collections.partner.find((x) => x.slug === "ponto"),
      "Ponto Frio",
    ),
  );
});

test("Faixa monetária usa centavos e rejeita entrada inválida", () => {
  assert.equal(C.parseMoney("2199,99"), 219999);
  assert.equal(C.parseMoney("0"), 0);
  assert.equal(C.parseMoney(""), null);
  assert.ok(Number.isNaN(C.parseMoney("-2")));
  assert.ok(Number.isNaN(C.parseMoney("1.999,999")));
  assert.notEqual(C.money(null), C.money(0));
});

test("Cashback preserva até, zero, ausência e loja inativa no final", () => {
  const items = C.filterItems(D.collections.partner, { order: "cashback" });
  assert.equal(items[0].id, "partner:magalu");
  assert.equal(items[0].benefitText, "Até 18%");
  assert.equal(items.at(-1).active, false);
  assert.equal(items.find((x) => x.slug === "boticario").benefit, 0);
  assert.equal(items.find((x) => x.slug === "extra").benefit, null);
});

test("Compre direto agrupa por loja, filtra preço e preserva identidade composta", () => {
  const items = C.filterItems(D.collections.direct, {
    groupStore: true,
    min: 200000,
    max: 330000,
    order: "price",
  });
  const shops = [...new Set(items.map((x) => x.store))];
  assert.deepEqual(shops, ["Casas Bahia", "Ponto"]);
  assert.equal(new Set(items.map((x) => x.id)).size, items.length);
  for (const store of shops) {
    const prices = items.filter((x) => x.store === store).map((x) => x.price);
    assert.deepEqual(
      prices,
      [...prices].sort((a, b) => a - b),
    );
  }
});

test("Livelo separa Clube de aumento da pontuação comum", () => {
  const items = C.filterItems(D.collections.livelo, {
    campaign: true,
    category: "Eletrônicos",
    order: "points",
  });
  assert.ok(items.length > 0);
  assert.ok(items.every((x) => x.points > x.base));
  assert.ok(!items.some((x) => x.campaign === "CLUB"));
});

test("Pichau diferencia esgotado de fora do catálogo e preço ausente", () => {
  const sold = C.filterItems(D.collections.pichau, { availability: "soldout" });
  const out = C.filterItems(D.collections.pichau, { availability: "out" });
  assert.ok(sold.length > 0 && out.length > 0);
  assert.ok(sold.every((x) => x.active && x.available === false));
  assert.ok(out.every((x) => !x.active));
  assert.equal(out[0].price, null);
});

test("Paginação não acumula, não duplica e corrige página fora do recorte", () => {
  const first = C.paginate(D.collections.partner, 1, 10);
  const second = C.paginate(D.collections.partner, 2, 10);
  assert.equal(first.items.length, 10);
  assert.equal(second.items.length, 4);
  assert.ok(!second.items.some((x) => first.items.includes(x)));
  assert.equal(C.paginate([1], 7, 10).page, 1);
});

test("Acompanhamentos são pessoais, sem alterar as coleções originais", () => {
  const list = C.filterItems(D.collections.livelo, { followed: true }, [
    "livelo:natura",
  ]);
  assert.deepEqual(
    list.map((x) => x.id),
    ["livelo:natura"],
  );
  assert.equal(D.collections.livelo.length, 14);
});

test("Links rejeitam protocolos, hosts e credenciais não permitidos", () => {
  assert.equal(
    C.safeExternal("https://www.pichau.com.br/"),
    "https://www.pichau.com.br/",
  );
  for (const bad of [
    "javascript:alert(1)",
    "http://shopping.inter.co/",
    "https://shopping.inter.co.evil.test/",
    "https://u:p@www.livelo.com.br/",
    "garbage",
  ])
    assert.equal(C.safeExternal(bad), null);
  assert.equal(C.escape('<script>"&'), "&lt;script&gt;&quot;&amp;");
});

test("Histórico está vinculado ao item correto e mantém nulo sem inventar zero", () => {
  assert.ok(
    D.history["pichau:0-0"].every((x) => x.id.startsWith("pichau:0-0:")),
  );
  assert.deepEqual(D.history["pichau:5-1"], []);
  assert.ok(D.history["livelo:natura"].length <= 30);
  const allIds = new Set(
    Object.values(D.collections)
      .flat()
      .map((x) => x.id),
  );
  assert.ok(D.events.every((x) => allIds.has(x.itemId)));
});
