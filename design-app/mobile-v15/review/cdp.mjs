import { writeFile } from "node:fs/promises";

export async function connect() {
  const pages = await (await fetch("http://127.0.0.1:9225/json/list")).json();
  const tab = pages.find((p) => p.type === "page");
  if (!tab) throw new Error("Abra o Chrome de revisão na porta 9225.");
  const ws = new WebSocket(tab.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    ws.addEventListener("open", resolve, { once: true });
    ws.addEventListener("error", reject, { once: true });
  });
  let serial = 0;
  const pending = new Map(),
    issues = [];
  ws.addEventListener("message", (event) => {
    const m = JSON.parse(event.data);
    if (m.method === "Runtime.exceptionThrown")
      issues.push(
        m.params.exceptionDetails.exception?.description ||
          m.params.exceptionDetails.text,
      );
    if (
      m.method === "Runtime.consoleAPICalled" &&
      ["error", "warning"].includes(m.params.type)
    )
      issues.push(m.params.args.map((x) => x.value || x.description).join(" "));
    if (
      m.method === "Log.entryAdded" &&
      ["error", "warning"].includes(m.params.entry.level)
    )
      issues.push(m.params.entry.text);
    if (
      m.method === "Network.responseReceived" &&
      m.params.response.status >= 400 &&
      m.params.response.url.startsWith("http://127.0.0.1:4175")
    )
      issues.push(`${m.params.response.status} ${m.params.response.url}`);
    if (!m.id || !pending.has(m.id)) return;
    const p = pending.get(m.id);
    pending.delete(m.id);
    clearTimeout(p.timer);
    m.error ? p.reject(new Error(m.error.message)) : p.resolve(m.result);
  });
  function call(method, params = {}) {
    const id = ++serial;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error(`Timeout: ${method}`));
      }, 15000);
      pending.set(id, { resolve, reject, timer });
      ws.send(JSON.stringify({ id, method, params }));
    });
  }
  async function evaluate(expression) {
    const r = await call("Runtime.evaluate", {
      expression,
      awaitPromise: true,
      returnByValue: true,
    });
    if (r.exceptionDetails)
      throw new Error(
        r.exceptionDetails.exception?.description || r.exceptionDetails.text,
      );
    return r.result.value;
  }
  async function navigate(url) {
    await call("Page.navigate", { url });
    await new Promise((r) => setTimeout(r, 400));
    await evaluate("document.fonts.ready.then(()=>true)");
    await new Promise((r) => setTimeout(r, 350));
  }
  async function screenshot(path, clip) {
    const result = await call("Page.captureScreenshot", {
      format: "png",
      ...(clip ? { clip } : {}),
      captureBeyondViewport: true,
    });
    await writeFile(path, Buffer.from(result.data, "base64"));
  }
  await call("Page.enable");
  await call("Runtime.enable");
  await call("Network.enable");
  await call("Network.setCacheDisabled", { cacheDisabled: true });
  await call("Log.enable");
  return {
    call,
    evaluate,
    navigate,
    screenshot,
    issues,
    close: () => ws.close(),
  };
}
