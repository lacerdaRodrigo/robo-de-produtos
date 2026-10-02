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
NAVIGATION_DESTINATIONS = ("Início", "Explorar", "Meu radar", "Perfil")
HOME_ALERTS_BUTTON = "Alertas"


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

    def find_all_inputs(self) -> list[dict[str, Any]]:
        assert self.session_id
        value = self.request(
            "POST",
            f"/session/{self.session_id}/elements",
            {
                "using": "-android uiautomator",
                "value": 'new UiSelector().className("android.widget.EditText")',
            },
        )
        return value if isinstance(value, list) else []

    def find_all_text(self, text: str) -> list[dict[str, Any]]:
        assert self.session_id
        safe = text.replace("\\", "\\\\").replace('"', '\\"')
        value = self.request(
            "POST",
            f"/session/{self.session_id}/elements",
            {
                "using": "-android uiautomator",
                "value": f'new UiSelector().textContains("{safe}")',
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

    def rect(self, element_id: str) -> dict[str, int]:
        assert self.session_id
        value = self.request("GET", f"/session/{self.session_id}/element/{element_id}/rect")
        return value if isinstance(value, dict) else {}

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

    def replace_text(self, value: str) -> None:
        targets: list[str] = []
        elements = self.find_all_inputs()
        targets = [
            item["element-6066-11e4-a52e-4f735466cecf"]
            for item in elements
            if "element-6066-11e4-a52e-4f735466cecf" in item
            and self.displayed(item["element-6066-11e4-a52e-4f735466cecf"])
        ]
        if not targets:
            raise AcceptanceError("O campo de busca não ficou visível.")
        target = min(targets, key=lambda item: self.rect(item).get("y", 0))
        assert self.session_id
        self.request("POST", f"/session/{self.session_id}/element/{target}/click", {})
        self.request("POST", f"/session/{self.session_id}/element/{target}/clear", {})
        if value:
            self.request(
                "POST",
                f"/session/{self.session_id}/element/{target}/value",
                {"text": value, "value": list(value)},
            )

    def submit_search(self) -> None:
        assert self.session_id
        self.request(
            "POST",
            f"/session/{self.session_id}/execute/sync",
            {"script": "mobile: pressKey", "args": [{"keycode": 66}]},
        )

    def click_lowest(self, description: str) -> None:
        """Click the lower matching control when a sheet overlays the page."""
        elements = self.find_all(description)
        if not elements:
            elements = self.find_all_text(description)
        targets = [
            item["element-6066-11e4-a52e-4f735466cecf"]
            for item in elements
            if "element-6066-11e4-a52e-4f735466cecf" in item
            and self.displayed(item["element-6066-11e4-a52e-4f735466cecf"])
            and self.clickable(item["element-6066-11e4-a52e-4f735466cecf"])
        ]
        if not targets:
            raise AcceptanceError(f"Não encontrei o controle acessível '{description}'.")
        target = max(targets, key=lambda item: self.rect(item).get("y", 0))
        assert self.session_id
        self.request("POST", f"/session/{self.session_id}/element/{target}/click", {})

    def click_after_scroll(self, description: str, max_swipes: int = 12) -> None:
        """Reveal a sheet action that moves below the viewport with enlarged text."""
        for _ in range(max_swipes):
            if self.is_visible(description):
                self.click(description, timeout=2)
                return
            self.scroll_down()
        raise AcceptanceError(
            f"O controle '{description}' não apareceu após rolar a folha."
        )

    def tap_center_lowest(self, description: str) -> None:
        """Tap a visible match when Flutter exposes no click action."""
        elements = self.find_all(description)
        if not elements:
            elements = self.find_all_text(description)
        targets = [
            item["element-6066-11e4-a52e-4f735466cecf"]
            for item in elements
            if "element-6066-11e4-a52e-4f735466cecf" in item
            and self.displayed(item["element-6066-11e4-a52e-4f735466cecf"])
        ]
        if not targets:
            raise AcceptanceError(f"Não encontrei o texto acessível '{description}'.")
        rect = self.rect(max(targets, key=lambda item: self.rect(item).get("y", 0)))
        x = rect.get("x", 0) + rect.get("width", 0) // 2
        y = rect.get("y", 0) + rect.get("height", 0) // 2
        assert self.session_id
        self.request(
            "POST",
            f"/session/{self.session_id}/execute/sync",
            {"script": "mobile: clickGesture", "args": [{"x": x, "y": y}]},
        )

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
        self._swipe_list("up")

    def scroll_up(self) -> None:
        self._swipe_list("down")

    def _swipe_list(self, direction: str) -> None:
        size = subprocess.run(
            ["adb", "-s", self.serial, "shell", "wm", "size"],
            check=False,
            capture_output=True,
            text=True,
        )
        match = re.search(r"(?:Physical|Override) size: (\d+)x(\d+)", size.stdout)
        if size.returncode != 0 or match is None:
            raise AcceptanceError("Não foi possível ler a resolução do Samsung autorizado.")
        width, height = map(int, match.groups())
        x = int(width * 0.92)
        top = int(height * 0.21)
        bottom = int(height * 0.70)
        start_y, end_y = (bottom, top) if direction == "up" else (top, bottom)
        result = subprocess.run(
            [
                "adb",
                "-s",
                self.serial,
                "shell",
                "input",
                "swipe",
                str(x),
                str(start_y),
                str(x),
                str(end_y),
                "350",
            ],
            check=False,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise AcceptanceError("Não foi possível rolar a lista no Samsung autorizado.")
        time.sleep(0.35)

    def screenshot(self, path: Path) -> None:
        assert self.session_id
        encoded = self.request("GET", f"/session/{self.session_id}/screenshot")
        path.write_bytes(base64.b64decode(encoded))
        path.chmod(0o600)

    def page_source(self) -> str:
        assert self.session_id
        value = self.request("GET", f"/session/{self.session_id}/source")
        return value if isinstance(value, str) else ""

    def wait_for_source(self, text: str, *, present: bool, timeout: float = 20) -> None:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            found = text in self.page_source()
            if found == present:
                return
            time.sleep(0.4)
        state = "aparecer" if present else "sumir"
        raise AcceptanceError(f"O texto de tela '{text}' não chegou a {state}.")

    def wait_for_source_any(self, texts: tuple[str, ...], timeout: float = 45) -> str:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            source = self.page_source()
            if any(text in source for text in texts):
                return source
            time.sleep(0.5)
        raise AcceptanceError(
            "A lista não chegou a um estado final conhecido antes do timeout."
        )

    def wait_for_catalog_rows(self, texts: tuple[str, ...], timeout: float = 60) -> str:
        """Accept a settled visible count when enlarged text moves card actions offscreen."""
        deadline = time.monotonic() + timeout
        previous = ""
        stable_samples = 0
        count_pattern = re.compile(
            r'(?:text|content-desc)="[^"]*\b\d[\d.,]*\s+(?:lojas|produtos|ofertas)\b'
        )
        while time.monotonic() < deadline:
            source = self.page_source()
            if any(text in source for text in texts):
                return source
            settled_count = (
                count_pattern.search(source) is not None
                and "android.widget.ProgressBar" not in source
            )
            if settled_count and source == previous:
                stable_samples += 1
                if stable_samples >= 2:
                    return source
            else:
                stable_samples = 0
            previous = source
            time.sleep(0.5)
        raise AcceptanceError(
            "A lista não apresentou conteúdo final nem uma contagem estável antes do timeout."
        )

    def wait_for_source_change(self, original: str, timeout: float = 30) -> str:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            source = self.page_source()
            if source != original:
                return source
            time.sleep(0.5)
        raise AcceptanceError("O conteúdo visível não mudou depois da navegação.")

    def wait_for_pagination(self, page: int, original: str, timeout: float = 60) -> str:
        deadline = time.monotonic() + timeout
        label = f"Paginação, página {page} de"
        label_seen = False
        while time.monotonic() < deadline:
            source = self.page_source()
            label_seen = label_seen or label in source
            loading = "android.widget.ProgressBar" in source
            if source != original and label in source and not loading:
                return source
            if label not in source:
                self.scroll_down()
            time.sleep(0.5)
        raise AcceptanceError(
            f"A paginação não confirmou a página {page} (rótulo visto: {label_seen})."
        )


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

    def inspect_profile_route(title: str, screenshot: str) -> None:
        driver.click(NAVIGATION_DESTINATIONS[3])
        driver.wait_for("Olá.")
        driver.click_after_scroll(title)
        driver.wait_for(title)
        passed(f"Perfil abre {title} e o conteúdo está disponível", screenshot)
        driver.back()
        driver.wait_for("Olá.")

    exit_code = 0
    status = "aprovado"
    try:
        driver.start()
        for _ in range(4):
            if driver.is_visible(NAVIGATION_DESTINATIONS[0]):
                break
            driver.back()
            time.sleep(0.4)
        driver.wait_for(NAVIGATION_DESTINATIONS[0], timeout=45)
        for destination in NAVIGATION_DESTINATIONS:
            driver.wait_for(destination)
        driver.click(NAVIGATION_DESTINATIONS[0])
        driver.wait_for(HOME_ALERTS_BUTTON)
        passed("Home carregada e quatro destinos principais acessíveis", "home.png")

        driver.click(NAVIGATION_DESTINATIONS[1])
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
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja do Inter foi encontrada.",
                "Não foi possível carregar o cashback do Inter.",
            )
        )
        passed("Sites parceiros abre a lista e os filtros", "inter-parceiros.png")

        for _ in range(20):
            if driver.is_visible("Próxima página"):
                break
            driver.scroll_down()
        driver.wait_for("Próxima página")
        primeira_pagina = driver.page_source()
        driver.click("Próxima página")
        driver.wait_for_pagination(2, primeira_pagina)
        passed("Sites parceiros pagina a lista real", "inter-parceiros-pagina-2.png")
        for _ in range(20):
            if driver.is_visible("Página anterior"):
                break
            driver.scroll_down()
        driver.wait_for("Página anterior")
        segunda_pagina = driver.page_source()
        driver.click("Página anterior")
        driver.wait_for_pagination(1, segunda_pagina)

        for _ in range(20):
            if any(
                driver.displayed(item["element-6066-11e4-a52e-4f735466cecf"])
                for item in driver.find_all_inputs()
                if "element-6066-11e4-a52e-4f735466cecf" in item
            ):
                break
            driver.scroll_up()
        if not any(
            driver.displayed(item["element-6066-11e4-a52e-4f735466cecf"])
            for item in driver.find_all_inputs()
            if "element-6066-11e4-a52e-4f735466cecf" in item
        ):
            raise AcceptanceError("O campo de busca dos Sites parceiros não apareceu.")
        driver.replace_text("Sam")
        driver.submit_search()
        busca_inter_pronta = driver.wait_for_source_any(
            (
                "Acompanhar",
                "Acompanhando",
                "Sam’s Club BR",
                "Nenhuma loja encontrada para",
                "Não foi possível carregar o cashback do Inter.",
            )
        )
        if "Sam" not in busca_inter_pronta:
            raise AcceptanceError("A busca dos Sites parceiros não preservou o termo.")
        passed("Sites parceiros aplica a busca por loja", "inter-parceiros-busca-sam.png")

        driver.replace_text("zzradarsemresultado")
        driver.submit_search()
        driver.wait_for("Nenhuma loja encontrada para")
        passed("Sites parceiros apresenta vazio para busca sem correspondência", "inter-parceiros-busca-vazia.png")
        driver.replace_text("")
        driver.submit_search()
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja do Inter foi encontrada.",
                "Não foi possível carregar o cashback do Inter.",
            )
        )

        driver.click("Filtros")
        driver.wait_for("Filtros · Sites parceiros")
        driver.click_lowest("Todas as categorias")
        driver.wait_for("Outros")
        driver.click_lowest("Outros")
        driver.click_after_scroll("Aplicar filtros")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja do Inter foi encontrada.",
                "Não foi possível carregar o cashback do Inter.",
            )
        )
        passed("Sites parceiros aplica o filtro real de categoria", "inter-parceiros-filtro-outros.png")

        driver.click("Filtros")
        driver.wait_for("Filtros · Sites parceiros")
        driver.tap_center_lowest("Maior cashback")
        driver.wait_for("Nome da loja")
        driver.click_lowest("Nome da loja")
        driver.click("Aplicar filtros")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja do Inter foi encontrada.",
                "Não foi possível carregar o cashback do Inter.",
            )
        )
        passed("Sites parceiros aplica a ordenação Nome A–Z", "inter-parceiros-ordenado.png")

        driver.click("No radar")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja está acompanhada ainda.",
                "Não foi possível carregar o cashback do Inter.",
            )
        )
        passed("Sites parceiros mostra o recorte No radar", "inter-parceiros-no-radar.png")
        driver.click("Todos")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja do Inter foi encontrada.",
                "Não foi possível carregar o cashback do Inter.",
            )
        )
        driver.click("Filtros")
        driver.click("Limpar")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja do Inter foi encontrada.",
                "Não foi possível carregar o cashback do Inter.",
            )
        )
        driver.back()
        driver.wait_for("Como você quer comprar?")
        driver.wait_for("Compre direto")
        passed("Back Android de Sites parceiros retorna ao hub", "inter-back.png")

        driver.click("Compre direto")
        driver.wait_for("Produtos por loja")
        driver.wait_for("Todos")
        driver.wait_for("No radar")
        driver.wait_for("Filtros")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum produto encontrado com esses filtros.",
                "Não foi possível buscar produtos agora.",
            )
        )
        passed("Compre direto abre Produtos por loja com Todos, No radar e filtros", "inter-produtos.png")

        driver.replace_text("Suporte Fixo")
        driver.submit_search()
        busca_direto_pronta = driver.wait_for_source_any(
            (
                "Acompanhar",
                "Acompanhando",
                "Suporte Fixo",
                "Nenhum produto encontrado com esses filtros.",
                "Não foi possível buscar produtos agora.",
            )
        )
        if "Nenhum produto encontrado com esses filtros." in busca_direto_pronta:
            raise AcceptanceError("A busca pelo produto real acompanhado ficou vazia.")
        passed("Compre direto busca no catálogo real", "inter-produtos-busca.png")

        driver.replace_text("zzradarsemresultado")
        driver.submit_search()
        driver.wait_for("Nenhum produto encontrado com esses filtros.")
        passed("Compre direto mostra estado vazio da busca", "inter-produtos-vazio.png")
        driver.replace_text("")
        driver.submit_search()
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum produto encontrado com esses filtros.",
                "Não foi possível buscar produtos agora.",
            )
        )

        driver.click("Filtros")
        driver.wait_for("Filtros · Compre direto")
        driver.wait_for("Todas as categorias")
        driver.click_lowest("Todas as categorias")
        driver.wait_for("Acessórios")
        driver.click_lowest("Acessórios")
        driver.click_after_scroll("Aplicar filtros")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum produto encontrado com esses filtros.",
                "Não foi possível buscar produtos agora.",
            )
        )
        passed("Compre direto aplica o filtro real de categoria", "inter-produtos-filtro-acessorios.png")

        driver.click("No radar")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum produto encontrado com esses filtros.",
                "Não foi possível buscar produtos agora.",
            )
        )
        passed("Compre direto aplica o recorte No radar", "inter-produtos-no-radar.png")
        driver.click("Todos")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum produto encontrado com esses filtros.",
                "Não foi possível buscar produtos agora.",
            )
        )
        driver.click("Filtros")
        driver.wait_for("Filtros · Compre direto")
        driver.click_after_scroll("Limpar")
        driver.click_after_scroll("Aplicar filtros")
        driver.wait_for_source("Filtros (1)", present=False)
        driver.wait_for("Filtros")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum produto encontrado com esses filtros.",
                "Não foi possível buscar produtos agora.",
            )
        )
        passed("Compre direto restaura filtros e aba Todos", "inter-produtos-restaurado.png")
        for _ in range(20):
            if driver.is_visible("Próxima página"):
                break
            driver.scroll_down()
        if driver.is_visible("Próxima página"):
            primeira_pagina = driver.page_source()
            driver.click("Próxima página")
            driver.wait_for_pagination(2, primeira_pagina)
            passed("Compre direto pagina o catálogo real", "inter-produtos-pagina-2.png")
            for _ in range(20):
                if driver.is_visible("Página anterior"):
                    break
                driver.scroll_down()
            driver.wait_for("Página anterior")
            segunda_pagina = driver.page_source()
            driver.click("Página anterior")
            driver.wait_for_pagination(1, segunda_pagina)
        else:
            raise AcceptanceError("O catálogo atual de Compre direto não expôs a página 2.")
        driver.back()
        driver.wait_for("Como você quer comprar?")
        driver.back()
        driver.wait_for("ESCOLHA SEU CAMINHO")
        passed("Back Android retorna do Compre direto ao hub e a Explorar", "inter-return.png")

        driver.click("Livelo")
        driver.wait_for("Filtros")
        driver.wait_for("Lojas")
        driver.wait_for("No radar")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhuma loja está acompanhada.",
                "Nenhuma loja corresponde aos filtros atuais.",
                "Não foi possível carregar o catálogo Livelo.",
            )
        )
        passed("Catálogo Livelo abre com controles de filtro", "livelo.png")
        driver.back()
        driver.wait_for("ESCOLHA SEU CAMINHO")

        driver.scroll_down()
        driver.click("Pichau")
        driver.wait_for("Filtros")
        driver.wait_for("Todos")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum PC Gamer foi encontrado na última coleta completa.",
                "Não foi possível carregar o catálogo Pichau.",
            )
        )
        driver.click("Filtros")
        driver.wait_for("Disponibilidade")
        driver.click_lowest("Todos")
        driver.wait_for("Fora do catálogo")
        driver.click("Fora do catálogo")
        driver.click_after_scroll("Aplicar filtros")
        driver.wait_for_source_any(
            (
                "Nenhum PC Gamer corresponde aos filtros atuais.",
                "Não foi possível carregar o catálogo Pichau.",
            )
        )
        passed(
            "Pichau aplica a aba Fora do catálogo no catálogo real",
            "pichau-fora-catalogo.png",
        )
        driver.click("Filtros")
        driver.click_after_scroll("Limpar")
        driver.click_after_scroll("Aplicar filtros")
        driver.wait_for_catalog_rows(
            (
                "Acompanhar",
                "Acompanhando",
                "Nenhum PC Gamer foi encontrado na última coleta completa.",
                "Não foi possível carregar o catálogo Pichau.",
            )
        )
        passed("Catálogo Pichau abre com filtros e abas", "pichau.png")
        driver.back()
        driver.wait_for("Pichau")
        passed("Back Android preserva a rota Explorar", "pichau-return.png")

        driver.click(NAVIGATION_DESTINATIONS[2])
        driver.wait_for("No seu radar")
        driver.wait_for_source_any(
            (
                "acompanhados por você.",
                "Seu radar ainda está vazio.",
                "Nenhum item encontrado.",
                "Não foi possível carregar os acompanhamentos",
            )
        )
        passed("Meu radar abre e mostra o estado atual da conta", "meu-radar.png")

        driver.click(NAVIGATION_DESTINATIONS[0])
        driver.wait_for(HOME_ALERTS_BUTTON)
        driver.click(HOME_ALERTS_BUTTON)
        alert_marker = "Tudo lido por enquanto"
        try:
            driver.wait_for(alert_marker, timeout=8)
        except AcceptanceError:
            driver.wait_for("Marcar todos como lidos", timeout=8)
        driver.wait_for_source("Motorola Edge", present=True)
        passed("Central de Alertas abre em estado real da conta", "alertas.png")
        driver.click("Não lidos")
        driver.wait_for("Marcar todos como lidos")
        passed("Aba Não lidos carrega o recorte da conta", "alertas-nao-lidos.png")
        driver.click("Filtrar")
        driver.wait_for("Filtrar mudanças")
        driver.click_lowest("Todas as origens")
        driver.wait_for("Sites parceiros")
        driver.click_lowest("Sites parceiros")
        driver.screenshot(args.artifacts / "alertas-filtro-sites-selecionado.png")
        driver.click("Aplicar")
        driver.wait_for("Nenhum alerta corresponde a este filtro.")
        driver.wait_for_source("Motorola Edge", present=False)
        passed("Filtro por origem aplica-se à Central", "alertas-filtrado-sites.png")
        driver.click("Filtrar")
        driver.tap_center_lowest("Sites parceiros")
        driver.wait_for("Todas as origens")
        driver.click_lowest("Todas as origens")
        driver.click("Aplicar")
        driver.wait_for("Marcar todos como lidos")
        driver.click("Todos")
        driver.wait_for("Marcar todos como lidos")
        driver.wait_for_source("Motorola Edge", present=True)
        passed("Central retorna à lista Todos após limpar o filtro", "alertas-todos.png")
        driver.back()
        driver.wait_for(HOME_ALERTS_BUTTON)
        passed("Back Android da Central retorna à Home", "alertas-back.png")

        driver.click(NAVIGATION_DESTINATIONS[3])
        driver.wait_for("Olá.")
        passed("Perfil e identificação da conta abrem", "perfil.png")
        inspect_profile_route("Aparência", "perfil-aparencia.png")
        inspect_profile_route("Notificações", "perfil-notificacoes.png")
        inspect_profile_route("Ajuda", "perfil-ajuda.png")
        inspect_profile_route("Privacidade", "perfil-privacidade.png")
        inspect_profile_route("Relatar problema", "perfil-relatar-problema.png")
        inspect_profile_route("Meus relatos", "perfil-meus-relatos.png")
        inspect_profile_route("Administração", "perfil-administracao.png")

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
