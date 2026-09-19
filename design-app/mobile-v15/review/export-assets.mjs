import { connect } from "./cdp.mjs";
const b = await connect();
await b.call("Emulation.setDefaultBackgroundColorOverride", {
  color: { r: 0, g: 0, b: 0, a: 0 },
});
for (const [source, name, size] of [
  ["app-icon", "app-icon-1024", 1024],
  ["app-icon", "app-icon-512", 512],
  ["app-icon", "app-icon-192", 192],
  ["app-icon", "app-icon-48", 48],
  ["ios-icon", "ios-icon-1024", 1024],
]) {
  await b.call("Emulation.setDeviceMetricsOverride", {
    width: size,
    height: size,
    deviceScaleFactor: 1,
    mobile: false,
  });
  await b.navigate(`http://127.0.0.1:4175/assets/brand/${source}.svg`);
  await b.screenshot(`assets/brand/${name}.png`, {
    x: 0,
    y: 0,
    width: size,
    height: size,
    scale: 1,
  });
  console.log(`Exportado ${name}.png`);
}
await b.call("Emulation.setDefaultBackgroundColorOverride");
b.close();
