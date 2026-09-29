#!/usr/bin/env python3
"""Local-only Android acceptance runner for the Samsung SM-M135M."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


PACKAGE = "br.com.radarbeneficios.app"
DEFAULT_URL = "http://127.0.0.1:4723/wd/hub"


class AcceptanceError(RuntimeError):
    pass


class Appium:
    def __init__(self, base_url: str, serial: str) -> None:
        self.base_url = base_url.rstrip("/")
        self.serial = serial
        self.session_id: str | None = None

    def request(self, method: str, route: str, body: dict[str, Any] | None = None) -> Any:
        payload = None if body is None else json.dumps(body).encode()
        request = urllib.request.Request(
            f"{self.base_url}{route}",
            data=payload,
            method=method,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=90) as response:
                decoded = json.loads(response.read())
        except urllib.error.HTTPError as error:
            try:
                details = json.loads(error.read())
                details = details.get("value", {})
                appium_error = details.get("error", "HTTPError")
                message = str(details.get("message", "")).splitlines()[0]
                message = message.replace(self.serial, "<device>")
                message = re.sub(r"/[^\s:]+", "<path>", message)
                message = message[:240]
            except (json.JSONDecodeError, AttributeError):
                appium_error = "HTTPError"
                message = ""
            raise AcceptanceError(
                f"Appium {method} {route.split('/')[-1]} retornou HTTP {error.code} "
                f"({appium_error}) {message}."
            ) from None
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as error:
            raise AcceptanceError(
                f"Appium {method} {route.split('/')[-1]} falhou ({type(error).__name__})."
            ) from None
        value = decoded.get("value") if isinstance(decoded, dict) else None
        if isinstance(value, dict) and value.get("error"):
            code = value.get("error", "erro")
            raise AcceptanceError(f"Appium recusou o comando ({code}).")
        return value if isinstance(decoded, dict) else decoded

    def start(self) -> None:
        caps = {
            "platformName": "Android",
            "appium:automationName": "UiAutomator2",
            "appium:udid": self.serial,
            "appium:appPackage": PACKAGE,
            "appium:appActivity": ".MainActivity",
            "appium:noReset": True,
            "appium:fullReset": False,
            "appium:autoGrantPermissions": False,
            "appium:newCommandTimeout": 600,
            "appium:adbExecTimeout": 60_000,
            "appium:disableWindowAnimation": True,
        }
        result = self.request(
            "POST",
            "/session",
            {"capabilities": {"alwaysMatch": caps, "firstMatch": [{}]}},
        )
        if not isinstance(result, dict) or not result.get("sessionId"):
            raise AcceptanceError("Appium não criou a sessão do aparelho selecionado.")
        self.session_id = result["sessionId"]

    def stop(self) -> None:
        if self.session_id:
            try:
                self.request("DELETE", f"/session/{self.session_id}")
            finally:
                self.session_id = None

    def find_all(self, description: str) -> list[dict[str, Any]]:
        assert self.session_id
        safe = description.replace("\\", "\\\\").replace('"', '\\"')
        value = self.request(
            "POST",
            f"/session/{self.session_id}/elements",
            {
                "using": "-android uiautomator",
                "value": f'new UiSelector().descriptionContains("{safe}")',
            },
        )
        return value if isinstance(value, list) else []

    def clickable(self, element_id: str) -> bool:
        assert self.session_id
        value = self.request(
            "GET", f"/session/{self.session_id}/element/{element_id}/attribute/clickable"
        )
        return str(value).lower() == "true"

    def displayed(self, element_id: str) -> bool:
        assert self.session_id
        value = self.request(
            "GET", f"/session/{self.session_id}/element/{element_id}/attribute/displayed"
        )
        return str(value).lower() == "true"

    def click(self, description: str, timeout: float = 12) -> None:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            elements = self.find_all(description)
            targets = [
                item["element-6066-11e4-a52e-4f735466cecf"]
                for item in elements
                if "element-6066-11e4-a52e-4f735466cecf" in item
                and self.displayed(item["element-6066-11e4-a52e-4f735466cecf"])
                and self.clickable(item["element-6066-11e4-a52e-4f735466cecf"])
            ]
            if len(targets) == 1:
                assert self.session_id
                self.request(
                    "POST", f"/session/{self.session_id}/element/{targets[0]}/click", {}
                )
                return
            if len(targets) > 1:
                raise AcceptanceError(
                    f"O rótulo acessível '{description}' encontrou mais de um alvo clicável."
                )
            time.sleep(0.35)
        raise AcceptanceError(f"Não encontrei o controle acessível '{description}'.")

    def wait_for(self, description: str, timeout: float = 20) -> None:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if self.is_visible(description):
                return
            time.sleep(0.4)
        raise AcceptanceError(f"Não apareceu o estado acessível '{description}'.")

    def is_visible(self, description: str) -> bool:
        elements = self.find_all(description)
        return any(
            self.displayed(item["element-6066-11e4-a52e-4f735466cecf"])
            for item in elements
            if "element-6066-11e4-a52e-4f735466cecf" in item
        )

    def back(self) -> None:
        assert self.session_id
        self.request(
            "POST",
            f"/session/{self.session_id}/execute/sync",
            {"script": "mobile: pressKey", "args": [{"keycode": 4}]},
        )

    def scroll_down(self) -> None:
        self.scroll("down")

    def scroll_up(self) -> None:
        self.scroll("up")

    def scroll(self, direction: str) -> None:
        assert self.session_id
        self.request(
            "POST",
            f"/session/{self.session_id}/execute/sync",
            {
                "script": "mobile: scrollGesture",
                "args": [
                    {
                        "left": 32,
                        "top": 180,
                        "width": 1016,
                        "height": 1740,
                        "direction": direction,
                        "percent": 0.72,
                    }
                ],
            },
        )

    def screenshot(self, path: Path) -> None:
        assert self.session_id
        encoded = self.request("GET", f"/session/{self.session_id}/screenshot")
        path.write_bytes(base64.b64decode(encoded))
        path.chmod(0o600)


def verify_device(serial: str) -> None:
    result = subprocess.run(
        ["adb", "devices", "-l"], check=True, capture_output=True, text=True
    )
    targets = [line.split()[0] for line in result.stdout.splitlines()[1:] if line.strip()]
    if targets != [serial]:
        raise AcceptanceError(
            "Conecte somente o Samsung SM-M135M autorizado; o runner exige esse serial único."
        )
    package = subprocess.run(
        ["adb", "-s", serial, "shell", "pm", "path", PACKAGE],
        check=True,
        capture_output=True,
        text=True,
    )
    if "package:" not in package.stdout:
        raise AcceptanceError("O APK Radar Benefícios não está instalado neste aparelho.")


def build_metadata(serial: str) -> dict[str, str]:
    repo_root = Path(__file__).resolve().parents[2]
    apk_path = repo_root / "app/build/app/outputs/flutter-apk/app-debug.apk"
    if not apk_path.is_file():
        raise AcceptanceError("O APK instalado não está disponível para identificar a build.")
    package = subprocess.run(
        ["adb", "-s", serial, "shell", "dumpsys", "package", PACKAGE],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    version_name = re.search(r"\bversionName=(\S+)", package)
    version_code = re.search(r"\bversionCode=(\d+)", package)
    if not version_name or not version_code:
        raise AcceptanceError("Não consegui identificar a versão instalada no aparelho.")
    digest = hashlib.sha256()
    with apk_path.open("rb") as apk:
        for block in iter(lambda: apk.read(1024 * 1024), b""):
            digest.update(block)
    commit = subprocess.run(
        ["git", "-C", str(repo_root), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()
    return {
        "version_name": version_name.group(1),
        "version_code": version_code.group(1),
        "apk_sha256": digest.hexdigest(),
        "commit": commit,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default=os.environ.get("ANDROID_SERIAL"))
    parser.add_argument("--appium-url", default=os.environ.get("APPIUM_URL", DEFAULT_URL))
    parser.add_argument("--artifacts", type=Path, required=True)
    args = parser.parse_args()
    if not args.serial:
        parser.error("defina ANDROID_SERIAL ou informe --serial")

    args.artifacts.mkdir(parents=True, exist_ok=True, mode=0o700)
    args.artifacts.chmod(0o700)
    os.umask(0o077)
    verify_device(args.serial)
    build = build_metadata(args.serial)

    driver = Appium(args.appium_url, args.serial)
    outcomes: list[dict[str, str]] = []

    def passed(name: str, screenshot: str) -> None:
        driver.screenshot(args.artifacts / screenshot)
        outcomes.append({"cenario": name, "resultado": "aprovado"})
        print(f"PASS {name}", flush=True)

    exit_code = 0
    status = "aprovado"
    try:
        driver.start()
        driver.wait_for("Tab 1 of 4", timeout=45)
        for tab in ("Tab 1 of 4", "Tab 2 of 4", "Tab 3 of 4", "Tab 4 of 4"):
            driver.wait_for(tab)
        driver.click("Tab 1 of 4")
        driver.wait_for("Abrir alertas")
        passed("Home carregada e quatro destinos principais acessíveis", "home.png")

        driver.click("Tab 2 of 4")
        for _ in range(3):
            if driver.is_visible("ESCOLHA SEU CAMINHO"):
                break
            driver.scroll_up()
        driver.wait_for("ESCOLHA SEU CAMINHO")
        for section in ("Livelo", "Banco Inter"):
            driver.wait_for(section)
        passed("Explorar apresenta os cards Livelo e Banco Inter", "explorar.png")

        driver.click("Banco Inter")
        for _ in range(3):
            if driver.is_visible("Como você quer comprar?"):
                break
            driver.back()
        driver.wait_for("Como você quer comprar?")
        driver.wait_for("Sites parceiros")
        driver.wait_for("Compre direto")
        passed("Hub Banco Inter oferece as duas modalidades", "inter-hub.png")

        driver.click("Sites parceiros")
        driver.wait_for("Filtros")
        driver.wait_for("Todos")
        driver.wait_for("No radar")
        passed("Sites parceiros abre a lista e os filtros", "inter-parceiros.png")
        driver.back()
        driver.wait_for("Como você quer comprar?")
        driver.wait_for("Compre direto")
        passed("Back Android de Sites parceiros retorna ao hub", "inter-back.png")

        driver.click("Compre direto")
        driver.wait_for("Produtos por loja")
        driver.wait_for("Todos")
        driver.wait_for("No radar")
        driver.wait_for("Filtros")
        passed("Compre direto abre Produtos por loja com Todos, No radar e filtros", "inter-produtos.png")
        driver.back()
        driver.wait_for("Como você quer comprar?")
        driver.back()
        driver.wait_for("ESCOLHA SEU CAMINHO")
        passed("Back Android retorna do Compre direto ao hub e a Explorar", "inter-return.png")

        driver.click("Livelo")
        driver.wait_for("Filtros")
        driver.wait_for("Lojas")
        driver.wait_for("No radar")
        passed("Catálogo Livelo abre com controles de filtro", "livelo.png")
        driver.back()
        driver.wait_for("ESCOLHA SEU CAMINHO")

        driver.scroll_down()
        driver.click("Pichau")
        driver.wait_for("Filtros")
        driver.wait_for("Todos")
        passed("Catálogo Pichau abre com filtros e abas", "pichau.png")
        driver.back()
        driver.wait_for("Pichau")
        passed("Back Android preserva a rota Explorar", "pichau-return.png")

        driver.click("Tab 3 of 4")
        driver.wait_for("No seu radar")
        passed("Meu radar abre e mostra o estado atual da conta", "meu-radar.png")

        driver.click("Tab 1 of 4")
        driver.wait_for("Abrir alertas")
        driver.click("Abrir alertas")
        alert_marker = "Tudo lido por enquanto"
        try:
            driver.wait_for(alert_marker, timeout=8)
        except AcceptanceError:
            driver.wait_for("Marcar todos como lidos", timeout=8)
        passed("Central de Alertas abre em estado real da conta", "alertas.png")
        driver.back()
        driver.wait_for("Abrir alertas")
        passed("Back Android da Central retorna à Home", "alertas-back.png")

    except AcceptanceError as error:
        print(f"BLOCK {error}", file=sys.stderr, flush=True)
        if driver.session_id:
            try:
                driver.screenshot(args.artifacts / "falha.png")
            except AcceptanceError:
                pass
        outcomes.append({"cenario": "suite", "resultado": "bloqueado", "motivo": str(error)})
        status = "bloqueado"
        exit_code = 2
    except Exception as error:
        print(f"FAIL erro inesperado ({type(error).__name__}).", file=sys.stderr, flush=True)
        outcomes.append({"cenario": "suite", "resultado": "erro", "motivo": type(error).__name__})
        status = "erro"
        exit_code = 1
    finally:
        try:
            driver.stop()
        except AcceptanceError:
            print("WARN Appium não confirmou o encerramento da sessão.", file=sys.stderr)

    run = {
        "data_utc": datetime.now(timezone.utc).isoformat(),
        "aparelho": "Samsung SM-M135M",
        "serial": args.serial,
        "pacote": PACKAGE,
        "build": build,
        "resultado_suite": status,
        "cenarios": outcomes,
    }
    manifest = args.artifacts / "resultado.json"
    manifest.write_text(json.dumps(run, ensure_ascii=False, indent=2) + "\n")
    manifest.chmod(0o600)
    print(f"Evidências privadas: {args.artifacts}")
    return exit_code


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AcceptanceError as error:
        print(f"BLOCK {error}", file=sys.stderr)
        raise SystemExit(2) from None
