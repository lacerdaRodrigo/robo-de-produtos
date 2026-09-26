"""Worker único do Samsung: agenda local e despacho de pedidos manuais."""

from __future__ import annotations

import argparse
import logging
import os
import re
import time
from collections.abc import Callable
from datetime import UTC, datetime
from pathlib import Path

from dotenv import load_dotenv

from robo_celular import fila
from robo_celular.agenda import FUSO_BRASILIA, coletas_devidas
from robo_celular.estado_local import EstadoLocal
from robo_celular.executores import executar_fonte
from robo_celular.github import ClienteRunsGitHub, FalhaGitHub, fonte_da_execucao
from robo_pichau import fila_android

_log = logging.getLogger("robo_celular")
INTERVALO_GITHUB_MINIMO = 120
INTERVALO_GITHUB_MAXIMO = 3600


def validar_intervalo_github(valor: str) -> int:
    try:
        intervalo = int(valor)
    except ValueError as erro:
        raise ValueError("intervalo deve ser inteiro entre 120 e 3600") from erro
    if not INTERVALO_GITHUB_MINIMO <= intervalo <= INTERVALO_GITHUB_MAXIMO:
        raise ValueError("intervalo deve ser inteiro entre 120 e 3600")
    return intervalo


def caminho_estado() -> Path:
    configurado = os.getenv("ROBO_CELULAR_STATE_FILE", "").strip()
    if configurado:
        return Path(configurado)
    prefixo = Path(os.getenv("PREFIX", "/tmp/robo-termux"))
    return prefixo / "var" / "lib" / "robo-celular" / "estado.sqlite3"


class WorkerCelular:
    def __init__(
        self,
        database_url: str,
        estado: EstadoLocal,
        *,
        github: ClienteRunsGitHub | None = None,
        executar=executar_fonte,
        processar_pichau=fila_android.executar_trabalho,
        obter_pichau=fila_android.obter_por_github_run_id,
        sincronizar: Callable[[str], None] = fila_android.sincronizar_checkout,
        agora=lambda: datetime.now(UTC),
    ) -> None:
        self.database_url = fila.validar_database_url(database_url)
        self.estado = estado
        self.github = github or ClienteRunsGitHub(
            os.getenv("ROBO_GITHUB_REPOSITORY", "lacerdaRodrigo/robo-de-produtos")
        )
        self.executar = executar
        self.processar_pichau = processar_pichau
        self.obter_pichau = obter_pichau
        self.sincronizar = sincronizar
        self._checkout_sincronizado_no_boot = False
        self.agora = agora

    def inicializar(self) -> None:
        self.consultar_github()
        self.processar_pendentes_no_boot()

    def processar_pendentes_no_boot(self) -> bool:
        if not self._checkout_sincronizado_no_boot:
            try:
                self.sincronizar("github-bootstrap")
            except fila_android.FalhaFilaAndroid as erro:
                _log.warning("Checkout Android indisponível; pedidos continuam pendentes: %s", erro)
                return False
            self._checkout_sincronizado_no_boot = True

        filas_saudaveis = True
        for fonte in ("livelo", "inter"):
            while True:
                try:
                    resultado = fila.processar_pedido(
                        self.database_url,
                        fonte,
                        executar=self.executar,
                    )
                except fila.FalhaFilaColeta as erro:
                    _log.warning("Fila %s indisponível na partida: %s", fonte, erro)
                    filas_saudaveis = False
                    break
                if resultado is None:
                    break
                _log.info("Pedido manual %s concluído: sucesso=%s", fonte, resultado)

        while True:
            try:
                resultado = self.processar_pichau(self.database_url)
            except Exception as erro:
                _log.warning("Fila Pichau indisponível na partida (%s).", type(erro).__name__)
                filas_saudaveis = False
                break
            if resultado is None:
                break
        return filas_saudaveis

    def executar_agendamentos(self, agora: datetime | None = None) -> None:
        momento = (agora or self.agora()).astimezone(FUSO_BRASILIA)
        for horario, slot in coletas_devidas(momento):
            chave = horario.chave(slot.date())
            if not self.estado.reservar_agendamento(chave, momento.isoformat()):
                continue
            _log.info("Coleta agendada iniciada: fonte=%s slot=%s", horario.fonte, chave)
            try:
                codigo = self.executar(horario.fonte)
            except Exception:
                codigo = 1
            self.estado.concluir_agendamento(
                chave,
                sucesso=codigo == 0,
                concluida_em=self.agora().astimezone(FUSO_BRASILIA).isoformat(),
            )
            _log.info(
                "Coleta agendada encerrada: fonte=%s sucesso=%s",
                horario.fonte,
                codigo == 0,
            )

    def _processar_execucao_manual(self, execucao: dict[str, object], fonte: str) -> bool:
        run_id = execucao.get("id")
        if not isinstance(run_id, int) or run_id <= 0:
            return False
        if fonte in {"livelo", "inter"}:
            sha = execucao.get("head_sha")
            chave = f"github-{run_id}"
            if isinstance(sha, str) and re.fullmatch(r"[0-9a-f]{40}", sha):
                chave = f"{chave}-{sha}"
            self.sincronizar(chave)
            resultado = fila.processar_pedido(
                self.database_url,
                fonte,
                github_run_id=run_id,
                executar=self.executar,
            )
            if resultado is not None:
                _log.info(
                    "Pedido manual concluído: fonte=%s run=%s sucesso=%s",
                    fonte,
                    run_id,
                    resultado,
                )
                return True
            estado = fila.consultar_estado(self.database_url, fonte, run_id)
            return estado in {"sucesso", "falha"}

        trabalho = self.obter_pichau(self.database_url, run_id)
        if trabalho is None:
            return False
        if trabalho.estado in fila_android.ESTADOS_TERMINAIS:
            return True
        self.processar_pichau(self.database_url)
        atual = self.obter_pichau(self.database_url, run_id)
        return atual is not None and atual.estado in fila_android.ESTADOS_TERMINAIS

    def consultar_github(self) -> None:
        etag = self.estado.metadado("github_etag")
        try:
            resposta = self.github.consultar(etag)
        except FalhaGitHub as erro:
            _log.warning("GitHub indisponível; pedidos manuais serão revistos depois: %s", erro)
            return
        if resposta.sem_alteracao:
            return

        if self.estado.metadado("github_inicializado") is None:
            # Um executor que ficou desligado pode ter mais de 100 runs
            # acumuladas. A fila é a fonte durável; drená-la antes do baseline
            # evita perder pedidos antigos que não cabem na primeira página da API.
            if not self.processar_pendentes_no_boot():
                return
            self.estado.inicializar_github(
                (
                    identificador
                    for execucao in resposta.execucoes
                    if isinstance((identificador := execucao.get("id")), int)
                ),
                resposta.etag,
            )
            return

        execucoes = sorted(
            resposta.execucoes,
            key=lambda item: item.get("id") if isinstance(item.get("id"), int) else 0,
        )
        manter_etag_anterior = False
        for execucao in execucoes:
            run_id = execucao.get("id")
            if not isinstance(run_id, int) or self.estado.run_foi_visto(run_id):
                continue
            fonte = fonte_da_execucao(execucao)
            if fonte is None:
                self.estado.marcar_run_visto(run_id)
                continue
            try:
                concluida = self._processar_execucao_manual(execucao, fonte)
            except Exception as erro:
                _log.warning(
                    "Pedido manual pendente: fonte=%s run=%s erro=%s",
                    fonte,
                    run_id,
                    type(erro).__name__,
                )
                manter_etag_anterior = True
                continue
            if concluida:
                self.estado.marcar_run_visto(run_id)
            else:
                manter_etag_anterior = True

        if resposta.etag and not manter_etag_anterior:
            self.estado.gravar_metadado("github_etag", resposta.etag)

    def executar_once(self) -> None:
        self.inicializar()
        self.executar_agendamentos()

    def executar_daemon(
        self,
        *,
        intervalo_github: int = 180,
        intervalo_agenda: int = 30,
    ) -> None:
        self.inicializar()
        proxima_consulta = time.monotonic() + intervalo_github
        while True:
            self.executar_agendamentos()
            if time.monotonic() >= proxima_consulta:
                self.consultar_github()
                proxima_consulta = time.monotonic() + intervalo_github
            time.sleep(intervalo_agenda)


def principal(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--once", action="store_true", help="executa um ciclo e termina")
    opcoes = parser.parse_args(argv)
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(levelname)s %(message)s")
    load_dotenv()
    try:
        database_url = fila.validar_database_url(os.getenv("DATABASE_URL"))
        worker = WorkerCelular(database_url, EstadoLocal(caminho_estado()))
    except fila.FalhaFilaColeta as erro:
        _log.error("Worker celular não iniciou: %s", erro)
        return 2
    if opcoes.once:
        worker.executar_once()
        return 0
    try:
        intervalo_github = validar_intervalo_github(os.getenv("ROBO_GITHUB_POLL_SECONDS", "180"))
    except ValueError as erro:
        _log.error("ROBO_GITHUB_POLL_SECONDS %s.", erro)
        return 2
    try:
        worker.executar_daemon(intervalo_github=intervalo_github)
    except KeyboardInterrupt:
        _log.info("Worker celular encerrado pelo sistema.")
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(principal())
