// Local, disposable-browser review. Never connects to production services.
import assert from "node:assert/strict";
import { writeFile } from "node:fs/promises";
import { connect } from "./cdp.mjs";
const b = await connect(),
  results = [];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const js = (s) => JSON.stringify(s);
async function check(name, fn) {
  try {
    await fn();
    results.push({ name, ok: true });
    console.log("OK", name);
  } catch (e) {
    results.push({ name, ok: false, error: e.message });
    console.error("FAIL", name, e.message);
  }
}
const ev = b.evaluate;
const click = async (selector) => {
  await ev(
    `(()=>{const el=document.querySelector(${js(selector)});if(!el)throw Error('Missing: '+${js(selector)});el.focus();el.click();})()`,
  );
  await sleep(220);
};
const field = async (selector, value) =>
  ev(
    `(()=>{const el=document.querySelector(${js(selector)});if(!el)throw Error('Missing input');el.value=${js(value)};el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}));})()`,
  );
const submit = async (form, wait = 0) => {
  await ev(
    `document.querySelector('form[data-form="${form}"]').requestSubmit()`,
  );
  if (wait) await sleep(wait);
};
const state = () => ev("RadarPrototype.snapshot()");
const text = () => ev('document.querySelector("#app-content").innerText');
const route = async (value) => {
  await field("#review-route", value);
  await sleep(350);
};
const cards = () =>
  ev('[...document.querySelectorAll(".offer-card")].map(x=>x.dataset.item)');
async function fresh(screen = "home", extra = "") {
  await b.navigate("http://127.0.0.1:4175/?screen=login");
  await ev(
    `localStorage.removeItem('radar-mobile-15');sessionStorage.removeItem('radar-mobile-15-session')`,
  );
  await b.navigate(`http://127.0.0.1:4175/?screen=${screen}${extra}`);
}
await b.call("Emulation.setDeviceMetricsOverride", {
  width: 1360,
  height: 1040,
  deviceScaleFactor: 1,
  mobile: false,
});
await check(
  "Abertura anima até login e respeita movimento reduzido",
  async () => {
    await fresh("launch");
    assert.equal((await state()).route, "launch");
    assert.equal(
      await ev(
        'document.querySelector(".launch-mark img").getAnimations().length>0',
      ),
      true,
    );
    await sleep(1150);
    assert.equal((await state()).route, "login");
    await fresh("launch", "&motion=reduce");
    assert.equal((await state()).route, "login");
  },
);
await check(
  "Acesso: validação, senha visível, duplo envio e sessão sem senha gravada",
  async () => {
    await fresh("login");
    await field("[name=email]", "invalido");
    await submit("login");
    assert.match(await text(), /e-mail válido/);
    await field("[name=email]", "demo@radar.app");
    await field("[name=password]", "radar123");
    await click("[data-action=password]");
    assert.equal(
      await ev('document.querySelector("[name=password]").type'),
      "text",
    );
    await submit("login");
    assert.equal(
      await ev('document.querySelector("form button[type=submit]").disabled'),
      true,
    );
    await submit("login");
    await sleep(700);
    assert.equal((await state()).route, "home");
    assert.equal(
      await ev('JSON.stringify(localStorage).includes("radar123")'),
      false,
    );
  },
);
await check(
  "Recuperação preserva email, registra simulação e cancela retorno tardio",
  async () => {
    await route("recovery");
    await field("[name=email]", "teste@radar.app");
    await submit("recovery", 600);
    assert.equal((await state()).route, "recovery-sent");
    assert.match(await text(), /teste@radar.app/);
    await route("recovery");
    await submit("recovery");
    await route("login");
    await sleep(600);
    assert.equal((await state()).route, "login");
  },
);
await check(
  "Inter: escolha real, condições completas, foco e link oficial",
  async () => {
    await fresh("explore");
    await click("[data-action=go][data-route=inter]");
    assert.match(await text(), /Sites parceiros/);
    assert.match(await text(), /Compre direto/);
    await click("[data-route=partners]");
    const selector = '[data-sheet=conditions][data-id="partner:magalu"]';
    await click(selector);
    assert.equal(
      await ev(
        'document.querySelector(".conditions-copy").textContent===RadarData.collections.partner.find(x=>x.id==="partner:magalu").conditions',
      ),
      true,
    );
    assert.equal(
      await ev('document.querySelector("#app-content").inert'),
      true,
    );
    await click("[data-action=close]");
    assert.equal(
      await ev(`document.activeElement.matches(${js(selector)})`),
      true,
    );
    await click('[data-action=external][data-id="partner:magalu"]');
    assert.equal(
      await ev('document.querySelector("#overlay a").hostname'),
      "shopping.inter.co",
    );
    await click("[data-action=close]");
  },
);
await check(
  "Paginação troca recorte sem acumular; acompanhadas mostra lista completa",
  async () => {
    const first = await cards();
    assert.equal(first.length, 10);
    await click('[data-scope=partner][data-page="2"]');
    const second = await cards();
    assert.equal(second.length, 4);
    assert.ok(second.every((x) => !first.includes(x)));
    await click("[data-action=catalog-tab][data-value=following]");
    assert.deepEqual((await cards()).sort(), [
      "partner:casas-bahia",
      "partner:magalu",
    ]);
  },
);
await check(
  "Acompanhar: pendência, desfazer, persistência e rollback offline",
  async () => {
    await fresh("partners");
    await click('[data-action=follow][data-id="partner:magalu"]');
    assert.equal(
      await ev(
        `document.querySelector(${js('[data-action=follow][data-id="partner:magalu"]')}).disabled`,
      ),
      true,
    );
    await sleep(500);
    assert.ok(!(await state()).following.includes("partner:magalu"));
    await click("[data-action=undo]");
    assert.ok((await state()).following.includes("partner:magalu"));
    await field("#review-state", "offline");
    await click('[data-action=follow][data-id="partner:magalu"]');
    await sleep(500);
    assert.ok((await state()).following.includes("partner:magalu"));
    await field("#review-state", "normal");
    await click('[data-action=follow][data-id="partner:magalu"]');
    await sleep(500);
    await b.navigate("http://127.0.0.1:4175/?screen=partners");
    assert.ok(!(await state()).following.includes("partner:magalu"));
  },
);
await check(
  "Compre direto: busca por variante, faixa válida, loja e paginação isoladas",
  async () => {
    await fresh("direct");
    await field("[name=query]", "celular motorola edge 60 pro 512");
    await submit("search");
    assert.equal((await cards()).length, 2);
    await click("[data-sheet=filters]");
    await field("[name=min]", "5000");
    await field("[name=max]", "2000");
    await submit("filters");
    assert.match(
      await ev('document.querySelector("#filter-error").textContent'),
      /máximo/,
    );
    await field("[name=min]", "2000");
    await field("[name=max]", "5000");
    await field("[name=store]", "Ponto");
    await submit("filters", 300);
    assert.equal((await cards()).length, 1);
    assert.match((await cards())[0], /ponto/);
    await click("[data-sheet=filters]");
    await click("[data-action=filter-reset]");
    await submit("filters", 300);
    assert.equal((await cards()).length, 2);
    assert.equal(
      (await state()).filters.direct.query,
      "celular motorola edge 60 pro 512",
    );
  },
);
await check(
  "Livelo: pontuação comum separada do Clube; condições e histórico paginados",
  async () => {
    await fresh("livelo");
    await click("[data-sheet=filters]");
    await field("[name=category]", "Eletrônicos");
    await ev('document.querySelector("[name=campaign]").checked=true');
    await submit("filters", 300);
    const ids = await cards();
    assert.ok(ids.length > 0);
    assert.equal(
      await ev(
        `RadarData.collections.livelo.filter(x=>${js(ids)}.includes(x.id)).every(x=>x.points>x.base&&x.campaign!=='CLUB')`,
      ),
      true,
    );
    await route("detail");
    await b.navigate("http://127.0.0.1:4175/?screen=detail&id=livelo:natura");
    await click("[data-sheet=history]");
    assert.equal(
      await ev('document.querySelectorAll(".history-row").length'),
      5,
    );
    const first = await ev(
      'document.querySelector(".history-row time").textContent',
    );
    await click('[data-scope=history][data-page="2"]');
    assert.notEqual(
      await ev('document.querySelector(".history-row time").textContent'),
      first,
    );
    await click("[data-action=close]");
  },
);
await check(
  "Pichau: esgotado, ausência, histórico vazio e destino desabilitado",
  async () => {
    await fresh("pichau");
    await click("[data-sheet=filters]");
    await field("[name=availability]", "soldout");
    await submit("filters", 300);
    assert.ok((await cards()).length > 0);
    assert.match(await text(), /Esgotado/);
    await click("[data-sheet=filters]");
    await field("[name=availability]", "out");
    await submit("filters", 300);
    assert.deepEqual(await cards(), ["pichau:5-1"]);
    await click("[data-action=detail]");
    assert.match(await text(), /Não informado/);
    assert.equal(
      await ev('document.querySelector(".sticky-action button").disabled'),
      true,
    );
    await click("[data-sheet=history]");
    assert.match(
      await ev('document.querySelector("#overlay").innerText'),
      /Ainda sem medições/,
    );
    await click("[data-action=close]");
  },
);
await check(
  "Navegação preserva busca, página e posição entre abas e botão voltar",
  async () => {
    await fresh("explore");
    await click("[data-route=pichau]");
    await click('[data-scope=pichau][data-page="2"]');
    await ev('document.querySelector("#app-content").scrollTop=260');
    await sleep(200);
    await click("#bottom-nav [data-route=profile]");
    await click("#bottom-nav [data-route=explore]");
    assert.equal((await state()).route, "pichau");
    assert.equal((await state()).filters.pichau.page, 2);
    assert.ok(await ev('document.querySelector("#app-content").scrollTop>100'));
    await click("[data-action=detail]");
    await click("[data-action=back]");
    assert.equal((await state()).route, "pichau");
    assert.equal((await state()).filters.pichau.page, 2);
    await click("[data-sheet=filters]");
    await ev("history.back()");
    await sleep(300);
    assert.equal(
      await ev('document.querySelector("#overlay").childElementCount'),
      0,
    );
  },
);
await check(
  "Central: ler muda destaque inicial, filtros e marcar todos",
  async () => {
    await fresh("home");
    await click(".change-ticket [data-action=alert]");
    await click("[data-action=back]");
    assert.equal(
      await ev(
        'document.querySelector(".change-ticket [data-action=alert]").dataset.id',
      ),
      "a2",
    );
    await click("[data-route=alerts]");
    await click("[data-sheet=alert-filters]");
    await field("[name=domain]", "livelo");
    await submit("alert-filters", 300);
    assert.equal(
      await ev('document.querySelectorAll(".alert-card").length'),
      1,
    );
    await click("[data-action=read-all]");
    await route("home");
    assert.match(await text(), /Tudo lido por enquanto/);
    assert.equal(await ev('!!document.querySelector(".change-ticket")'), false);
  },
);
await check(
  "Preferências, permissão opcional, tema e movimento reduzido persistem",
  async () => {
    await fresh("notifications");
    await click("[data-key=push]");
    await click("[data-action=permission][data-value=denied]");
    assert.equal((await state()).prefs.push, false);
    await click("[data-key=push]");
    await click("[data-action=permission][data-value=granted]");
    assert.equal((await state()).prefs.push, true);
    await route("appearance");
    await click("[data-action=theme][data-value=dark]");
    await click("[data-action=motion]");
    await b.navigate("http://127.0.0.1:4175/?screen=appearance");
    assert.equal((await state()).theme, "dark");
    assert.equal(
      await ev(
        'getComputedStyle(document.querySelector(".screen")).animationDuration',
      ),
      "0.001s",
    );
  },
);
await check(
  "Suporte: validação, texto preservado offline, protocolo e escape HTML",
  async () => {
    await fresh("report");
    await field("[name=description]", "curto");
    await submit("report");
    assert.match(await text(), /10 a 2.000/);
    const body = "Condições não abriram <img src=x onerror=alert(1)> na loja.";
    await field("[name=description]", body);
    await field("#review-state", "offline");
    await submit("report", 600);
    assert.equal(await ev('document.querySelector("textarea").value'), body);
    await field("#review-state", "normal");
    await submit("report", 600);
    assert.equal((await state()).route, "reports");
    assert.equal((await state()).reportCount, 1);
    assert.equal(await ev('!!document.querySelector("img[src=x]")'), false);
    assert.match(await text(), /RAD-/);
  },
);
await check(
  "Sessão expirada retoma o catálogo e logout remove sessão, não acompanhamentos",
  async () => {
    await fresh("direct");
    await field("[name=query]", "motorola");
    await submit("search");
    await field("#review-state", "expired");
    assert.equal(
      await ev('!!document.querySelector("[role=alertdialog]")'),
      true,
    );
    await click("[data-action=reauth]");
    await click("[data-action=demo]");
    assert.equal((await state()).route, "direct");
    assert.equal((await state()).filters.direct.query, "motorola");
    const followed = (await state()).following;
    await route("profile");
    await click("[data-sheet=logout]");
    await click("[data-action=logout]");
    assert.equal((await state()).session, false);
    assert.equal((await state()).route, "login");
    assert.deepEqual((await state()).following, followed);
  },
);
await check(
  "Admin: restrição, frase exata e reset isolado de cada domínio",
  async () => {
    await fresh("admin");
    assert.match(await text(), /Acesso restrito/);
    assert.equal(
      await ev('!!document.querySelector("[data-action=admin-review]")'),
      false,
    );
    await field("#review-role", "admin");
    await click("[data-action=admin-review][data-domain=livelo]");
    await field("[name=phrase]", "errado");
    await submit("admin");
    assert.deepEqual((await state()).cleared, []);
    await field("[name=phrase]", "APAGAR LIVELO");
    await submit("admin", 800);
    assert.deepEqual((await state()).cleared, ["livelo"]);
    assert.ok((await state()).following.includes("partner:magalu"));
    await click("[data-action=admin-review][data-domain=inter]");
    await field("[name=phrase]", "RESETAR INTER");
    await submit("admin", 800);
    assert.deepEqual((await state()).cleared, ["livelo", "partner", "direct"]);
    assert.ok((await state()).following.includes("pichau:0-0"));
    assert.equal((await state()).session, true);
  },
);
await check(
  "Todas as telas: claro/escuro e texto 200% em 320 px sem overflow horizontal",
  async () => {
    await fresh("home");
    const routes = (await ev("RadarPrototype.routes")).filter(
      (x) => x !== "launch",
    );
    const errors = [];
    for (const theme of ["light", "dark"])
      for (const scale of ["1", "2"]) {
        await b.navigate(
          `http://127.0.0.1:4175/?screen=home&theme=${theme}&text=${scale}&width=320&role=admin&motion=reduce`,
        );
        for (const screen of routes) {
          await route(screen);
          const result = await ev(
            `(()=>{const a=document.querySelector('#app-content'),n=document.querySelector('#bottom-nav');return {overflow:a.scrollWidth>a.clientWidth+1||n.scrollWidth>n.clientWidth+1,body:getComputedStyle(document.querySelector('.lede')||document.querySelector('.screen')).fontSize,unnamed:[...document.querySelectorAll('#device button')].filter(x=>!x.textContent.trim()&&!x.getAttribute('aria-label')).length}})()`,
          );
          if (result.overflow || result.unnamed)
            errors.push({ theme, scale, screen, ...result });
          if (scale === "2" && screen === "pichau")
            assert.equal(result.body, "28px");
        }
      }
    assert.deepEqual(errors, []);
  },
);
await check(
  "Estados do catálogo, folhas, foco preso, RTL e viewport mobile",
  async () => {
    await fresh("pichau", "&width=320&text=2&motion=reduce&dir=rtl");
    for (const value of [
      "loading",
      "empty",
      "no-results",
      "offline",
      "stale",
      "partial",
      "error",
      "error-empty",
      "refreshing",
      "normal",
    ]) {
      await field("#review-state", value);
      assert.ok((await text()).length > 20);
      assert.equal(
        await ev(
          'document.querySelector("#app-content").scrollWidth>document.querySelector("#app-content").clientWidth+1',
        ),
        false,
      );
    }
    await click("[data-sheet=filters]");
    assert.equal(
      await ev(
        'document.querySelector(".sheet").scrollWidth>document.querySelector(".sheet").clientWidth+1',
      ),
      false,
    );
    await ev(
      `(()=>{const e=[...document.querySelectorAll('.sheet button,.sheet select,.sheet input')];e.at(-1).focus();document.dispatchEvent(new KeyboardEvent('keydown',{key:'Tab',bubbles:true}));})()`,
    );
    assert.equal(await ev("document.activeElement.dataset.action"), "close");
    await click("[data-action=close]");
    await b.call("Emulation.setDeviceMetricsOverride", {
      width: 320,
      height: 740,
      deviceScaleFactor: 1,
      mobile: true,
    });
    await route("home");
    assert.equal(await ev("document.documentElement.scrollWidth"), 320);
    assert.equal(
      await ev(
        'document.querySelector("#device").getBoundingClientRect().width',
      ),
      320,
    );
  },
);
await check(
  "Sem exceções, avisos ou recursos locais quebrados nas jornadas",
  async () => assert.deepEqual(b.issues, []),
);
b.close();
const report = {
  passed: results.filter((x) => x.ok).length,
  total: results.length,
  results,
};
console.log(JSON.stringify(report, null, 2));
await writeFile(
  new URL("./results.json", import.meta.url),
  JSON.stringify(report, null, 2) + "\n",
);
if (results.some((x) => !x.ok)) process.exitCode = 1;
