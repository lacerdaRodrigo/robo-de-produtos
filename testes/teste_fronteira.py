"""CT-074 — a fronteira entre nucleo e adaptador (PRD 9.3).

A estrutura de pastas e plana por decisao (PRD 4.4), entao a separacao entre
nucleo e adaptador so existe se for testada. Este teste e o que paga aquela
divida: sem ele, nada impede um `import requests` dentro das regras.
"""

from __future__ import annotations

import ast
from pathlib import Path

import pytest

PACOTE = Path(__file__).resolve().parents[1] / "src" / "robo_livelo"

# O nucleo nao faz entrada e saida: nada de rede, disco, ambiente ou SMTP.
# beautifulsoup4 e permitido de proposito — transforma texto em estrutura,
# nao abre conexao nem arquivo (PRD 4.1).
MODULOS_DO_NUCLEO = [
    "modelos.py",
    "extrator.py",
    "categorias.py",
    "montador_email.py",
    "alertas.py",
    "retrato.py",
]
IMPORTS_PROIBIDOS = {"requests", "smtplib", "tomllib", "os", "pathlib", "dotenv", "socket"}


def imports_de(caminho: Path) -> set[str]:
    arvore = ast.parse(caminho.read_text(encoding="utf-8"))
    encontrados: set[str] = set()
    for no in ast.walk(arvore):
        if isinstance(no, ast.Import):
            encontrados.update(alias.name.split(".")[0] for alias in no.names)
        elif isinstance(no, ast.ImportFrom) and no.module and no.level == 0:
            encontrados.add(no.module.split(".")[0])
    return encontrados


@pytest.mark.parametrize("modulo", MODULOS_DO_NUCLEO)
def teste_ct074_nucleo_nao_faz_io(modulo):
    proibidos = imports_de(PACOTE / modulo) & IMPORTS_PROIBIDOS
    assert not proibidos, f"{modulo} importa {sorted(proibidos)}, que fazem I/O"


def teste_nucleo_nao_importa_adaptadores():
    """A dependencia aponta para dentro: adaptador conhece nucleo, nunca o contrario."""
    for modulo in MODULOS_DO_NUCLEO:
        assert "adaptadores" not in "".join(imports_de(PACOTE / modulo))
