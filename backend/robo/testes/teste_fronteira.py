"""CT-074 — a fronteira entre nucleo e adaptador (PRD 9.3).

A estrutura de pastas e plana por decisao (PRD 4.4), entao a separacao entre
nucleo e adaptador so existe se for testada. Este teste e o que paga aquela
divida: sem ele, nada impede um `import requests` dentro das regras.
"""

from __future__ import annotations

import ast
import tomllib
from pathlib import Path

import pytest

from robo_compartilhado import __version__ as versao_compartilhada
from robo_inter import __version__ as versao_inter
from robo_livelo import __version__ as versao_livelo
from robo_pichau import __version__ as versao_pichau

SRC = Path(__file__).resolve().parents[1] / "src"
RAIZ_REPOSITORIO = Path(__file__).resolve().parents[3]

# O nucleo nao faz entrada e saida: nada de rede, disco ou ambiente.
# beautifulsoup4 e permitido de proposito — transforma texto em estrutura,
# nao abre conexao nem arquivo (PRD 4.1).
MODULOS_LIVELO = [
    "modelos.py",
    "extrator.py",
    "categorias.py",
    "alertas.py",
    "retrato.py",
]
MODULOS_INTER = [
    "modelos_inter.py",
    "extrator_inter.py",
    "ranking_inter.py",
    "retrato_inter.py",
    "modelos_produtos_inter.py",
    "extrator_produtos_inter.py",
]
MODULOS_POR_PACOTE = {
    "robo_livelo": MODULOS_LIVELO,
    "robo_inter": MODULOS_INTER,
}
MODULOS_DO_NUCLEO = [
    (pacote, modulo) for pacote, modulos in MODULOS_POR_PACOTE.items() for modulo in modulos
]
IMPORTS_PROIBIDOS = {"requests", "tomllib", "os", "pathlib", "dotenv", "socket"}


def imports_de(caminho: Path) -> set[str]:
    arvore = ast.parse(caminho.read_text(encoding="utf-8"))
    encontrados: set[str] = set()
    for no in ast.walk(arvore):
        if isinstance(no, ast.Import):
            encontrados.update(alias.name.split(".")[0] for alias in no.names)
        elif isinstance(no, ast.ImportFrom) and no.module and no.level == 0:
            encontrados.add(no.module.split(".")[0])
    return encontrados


@pytest.mark.parametrize(("pacote", "modulo"), MODULOS_DO_NUCLEO)
def teste_ct074_ct188_nucleos_nao_fazem_io(pacote, modulo):
    proibidos = imports_de(SRC / pacote / modulo) & IMPORTS_PROIBIDOS
    assert not proibidos, f"{pacote}/{modulo} importa {sorted(proibidos)}, que fazem I/O"


def teste_nucleo_nao_importa_adaptadores():
    """A dependencia aponta para dentro: adaptador conhece nucleo, nunca o contrario."""
    for pacote, modulo in MODULOS_DO_NUCLEO:
        assert "adaptadores" not in "".join(imports_de(SRC / pacote / modulo))


def teste_inter_nao_importa_o_pacote_livelo():
    for caminho in (SRC / "robo_inter").glob("*.py"):
        assert "robo_livelo" not in imports_de(caminho)


def teste_versionamento_aponta_para_os_arquivos_apos_reorganizacao():
    configuracao = tomllib.loads(
        (RAIZ_REPOSITORIO / "backend/robo/pyproject.toml").read_text(encoding="utf-8")
    )["tool"]["semantic_release"]
    workflow = (RAIZ_REPOSITORIO / ".github/workflows/versao.yml").read_text(encoding="utf-8")

    assert configuracao["version_toml"] == ["backend/robo/pyproject.toml:project.version"]
    assert configuracao["version_variables"] == [
        "backend/robo/src/robo_compartilhado/__init__.py:__version__",
        "app/pubspec.yaml:version",
    ]
    assert "semantic-release -c backend/robo/pyproject.toml version" in workflow


def teste_ct415_coletores_publicam_a_mesma_versao():
    assert versao_livelo == versao_inter == versao_pichau == versao_compartilhada
