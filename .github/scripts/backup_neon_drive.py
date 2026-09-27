#!/usr/bin/env python3
"""Gera dump Postgres, cifra com age e guarda cópia privada no Google Drive."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from collections.abc import Callable, Iterable, Mapping
from contextlib import suppress
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, quote, unquote, urlsplit, urlunsplit

DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file"
DRIVE_FOLDER_MIME = "application/vnd.google-apps.folder"
BACKUP_PROPERTY = "radar_neon_backup"
FOLDER_PROPERTY = "radar_neon_backup_folder"
RETENTION_COUNT = 12
AGE_HEADER = b"age-encryption.org/v1"


class BackupError(RuntimeError):
    """Falha operacional sem imprimir URL de banco ou material secreto."""


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise BackupError(f"variável obrigatória ausente: {name}")
    return value


def _drive_query_value(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def validate_database_url(value: str) -> str:
    url = value.strip()
    try:
        parsed = urlsplit(url)
        sslmode = parse_qs(parsed.query).get("sslmode", [""])[0].lower()
    except ValueError:
        raise BackupError("NEON_BACKUP_DATABASE_URL inválida") from None
    if parsed.scheme not in {"postgres", "postgresql"} or not parsed.hostname:
        raise BackupError("NEON_BACKUP_DATABASE_URL precisa ser uma URL Postgres")
    if sslmode not in {"require", "verify-ca", "verify-full"}:
        raise BackupError("a conexão de backup precisa exigir SSL")
    return url


def validate_age_recipient(value: str) -> str:
    recipient = value.strip()
    if not recipient.startswith("age1") or len(recipient) < 20:
        raise BackupError("BACKUP_AGE_RECIPIENT não parece uma chave pública age")
    return recipient


def _pgpass_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace(":", "\\:")


def _pg_url_without_password(url: str) -> tuple[str, str]:
    parsed = urlsplit(url)
    if not parsed.username or parsed.password is None:
        raise BackupError("NEON_BACKUP_DATABASE_URL precisa ter usuário e senha")
    database = unquote(parsed.path.lstrip("/"))
    username = unquote(parsed.username)
    password = unquote(parsed.password)
    if not database or not username or not password:
        raise BackupError("NEON_BACKUP_DATABASE_URL tem credenciais incompletas")
    host = parsed.hostname or ""
    if ":" in host and not host.startswith("["):
        host = f"[{host}]"
    try:
        porta = parsed.port
    except ValueError:
        raise BackupError("NEON_BACKUP_DATABASE_URL contém porta inválida") from None
    netloc = f"{quote(username, safe='')}@{host}" + (f":{porta}" if porta else "")
    sem_senha = urlunsplit((parsed.scheme, netloc, parsed.path, parsed.query, ""))
    return sem_senha, ":".join(
        _pgpass_escape(campo)
        for campo in (parsed.hostname or "*", str(porta or 5432), database, username, password)
    )


def gerar_backup_criptografado(
    database_url: str,
    recipient: str,
    destino: Path,
    *,
    executar: Callable[..., subprocess.CompletedProcess[bytes]] = subprocess.run,
) -> Path:
    """Usa pg_dump em formato custom, cifra e remove o dump em claro sempre."""

    url = validate_database_url(database_url)
    chave_publica = validate_age_recipient(recipient)
    destino.parent.mkdir(parents=True, exist_ok=True)
    descritor, caminho_plano = tempfile.mkstemp(
        prefix=".radar-neon-", suffix=".dump", dir=destino.parent
    )
    os.close(descritor)
    caminho_temporario = Path(caminho_plano)
    caminho_senha = caminho_temporario.with_suffix(".pgpass")
    try:
        url_sem_senha, entrada_pgpass = _pg_url_without_password(url)
        descritor_senha = os.open(caminho_senha, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(descritor_senha, "w", encoding="utf-8") as arquivo_senha:
            arquivo_senha.write(f"{entrada_pgpass}\n")
        ambiente = os.environ.copy()
        ambiente["PGPASSFILE"] = str(caminho_senha)
        ambiente["PGCONNECT_TIMEOUT"] = "20"
        try:
            dump = executar(
                [
                    "pg_dump",
                    "--no-password",
                    "--no-owner",
                    "--no-acl",
                    "--format=custom",
                    "--file",
                    str(caminho_temporario),
                    "--dbname",
                    url_sem_senha,
                ],
                check=False,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                timeout=900,
                env=ambiente,
            )
        except (OSError, subprocess.TimeoutExpired):
            raise BackupError("pg_dump não terminou dentro do prazo") from None
        if dump.returncode != 0 or not caminho_temporario.is_file():
            raise BackupError("pg_dump falhou; backup não foi enviado")

        try:
            cifra = executar(
                [
                    "age",
                    "--encrypt",
                    "--recipient",
                    chave_publica,
                    "--output",
                    str(destino),
                    str(caminho_temporario),
                ],
                check=False,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                timeout=900,
            )
        except (OSError, subprocess.TimeoutExpired):
            raise BackupError("age não terminou dentro do prazo") from None
        if cifra.returncode != 0 or not destino.is_file():
            raise BackupError("age falhou; backup não foi enviado")
        with destino.open("rb") as arquivo:
            if arquivo.read(len(AGE_HEADER)) != AGE_HEADER:
                raise BackupError("age produziu um arquivo inválido")
        return destino
    except BackupError:
        destino.unlink(missing_ok=True)
        raise
    finally:
        caminho_temporario.unlink(missing_ok=True)
        caminho_senha.unlink(missing_ok=True)


def files_to_prune(files: Iterable[Mapping[str, Any]], keep: int = RETENTION_COUNT) -> list[str]:
    ordenados = sorted(
        files,
        key=lambda item: str(item.get("createdTime", "")),
        reverse=True,
    )
    return [str(item["id"]) for item in ordenados[keep:] if item.get("id")]


def validar_acl_privada(permissions: Iterable[Mapping[str, Any]], *, owner_email: str) -> None:
    """Só aceita a conta proprietária; backup não herda acesso de destinatários."""

    dono = owner_email.strip().lower()
    encontrou_dono = False
    for permission in permissions:
        tipo = str(permission.get("type", "")).lower()
        papel = str(permission.get("role", "")).lower()
        email = str(permission.get("emailAddress", "")).strip().lower()
        if tipo != "user" or email != dono:
            raise BackupError("ACL do Drive contém acesso além da conta proprietária")
        if papel != "owner":
            raise BackupError("ACL do Drive não confirma a conta proprietária")
        encontrou_dono = True
    if not encontrou_dono:
        raise BackupError("ACL do Drive não contém a conta proprietária")


def _list_all_files(service: Any, query: str) -> list[dict[str, Any]]:
    arquivos: list[dict[str, Any]] = []
    page_token: str | None = None
    while True:
        resposta = (
            service.files()
            .list(
                q=query,
                spaces="drive",
                fields="nextPageToken,files(id,name,createdTime,appProperties)",
                pageSize=1000,
                pageToken=page_token,
            )
            .execute()
        )
        arquivos.extend(resposta.get("files", []))
        page_token = resposta.get("nextPageToken")
        if not page_token:
            return arquivos


def _permissions(service: Any, file_id: str) -> list[dict[str, Any]]:
    permissoes: list[dict[str, Any]] = []
    page_token: str | None = None
    while True:
        resposta = (
            service.permissions()
            .list(
                fileId=file_id,
                fields="nextPageToken,permissions(type,role,emailAddress)",
                pageSize=100,
                pageToken=page_token,
            )
            .execute()
        )
        permissoes.extend(resposta.get("permissions", []))
        page_token = resposta.get("nextPageToken")
        if not page_token:
            return permissoes


class DriveBackupPublisher:
    def __init__(
        self,
        service: Any,
        *,
        media_factory: Callable[..., Any] | None = None,
        keep: int = RETENTION_COUNT,
    ) -> None:
        self.service = service
        self.media_factory = media_factory
        self.keep = keep

    def _media(self, path: Path) -> Any:
        factory = self.media_factory
        if factory is None:
            try:
                from googleapiclient.http import MediaFileUpload
            except ImportError:
                raise BackupError("dependência google-api-python-client ausente") from None
            factory = MediaFileUpload
        return factory(str(path), mimetype="application/octet-stream", resumable=True)

    def publish(
        self,
        arquivo: Path,
        *,
        folder_id: str,
        owner_email: str,
        file_name: str,
        run_id: str,
    ) -> None:
        validar_acl_privada(_permissions(self.service, folder_id), owner_email=owner_email)
        query = (
            "trashed = false and "
            f"{_drive_query_value(folder_id)} in parents and "
            f"appProperties has {{ key = {_drive_query_value(BACKUP_PROPERTY)} "
            "and value = 'true' }"
        )
        arquivos = _list_all_files(self.service, query)
        existente = next(
            (item for item in arquivos if item.get("appProperties", {}).get("run_id") == run_id),
            None,
        )
        if existente:
            validar_acl_privada(
                _permissions(self.service, str(existente["id"])),
                owner_email=owner_email,
            )
        metadata = {
            "name": file_name,
            "mimeType": "application/octet-stream",
            "appProperties": {BACKUP_PROPERTY: "true", "run_id": run_id},
        }
        criado = existente is None
        try:
            if existente:
                resposta = (
                    self.service.files()
                    .update(
                        fileId=existente["id"],
                        body=metadata,
                        media_body=self._media(arquivo),
                        fields="id,name,createdTime",
                    )
                    .execute()
                )
            else:
                resposta = (
                    self.service.files()
                    .create(
                        body={**metadata, "parents": [folder_id]},
                        media_body=self._media(arquivo),
                        fields="id,name,createdTime",
                    )
                    .execute()
                )
            file_id = str(resposta["id"])
            validar_acl_privada(_permissions(self.service, file_id), owner_email=owner_email)
        except BackupError:
            if criado and "file_id" in locals():
                with suppress(Exception):
                    self.service.files().delete(fileId=file_id).execute()
            raise
        except Exception:
            if criado and "file_id" in locals():
                with suppress(Exception):
                    self.service.files().delete(fileId=file_id).execute()
            raise BackupError("falha ao enviar ou validar o backup no Drive") from None

        arquivos_atualizados = _list_all_files(self.service, query)
        for file_id in files_to_prune(arquivos_atualizados, self.keep):
            if file_id != str(resposta["id"]):
                self.service.files().delete(fileId=file_id).execute()


def _drive_service_from_secrets() -> Any:
    try:
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from googleapiclient.discovery import build
    except ImportError:
        raise BackupError("dependências Google ausentes") from None
    try:
        client = json.loads(required_env("GOOGLE_DRIVE_OAUTH_CLIENT_JSON"))
    except json.JSONDecodeError:
        raise BackupError("GOOGLE_DRIVE_OAUTH_CLIENT_JSON inválido") from None
    config = client.get("installed") or client.get("web") or client
    client_id = str(config.get("client_id", "")).strip()
    client_secret = str(config.get("client_secret", "")).strip()
    token_uri = str(config.get("token_uri", "https://oauth2.googleapis.com/token")).strip()
    if not client_id or not client_secret:
        raise BackupError("JSON OAuth sem client_id/client_secret")
    credentials = Credentials(
        token=None,
        refresh_token=required_env("GOOGLE_DRIVE_REFRESH_TOKEN"),
        token_uri=token_uri,
        client_id=client_id,
        client_secret=client_secret,
        scopes=[DRIVE_FILE_SCOPE],
    )
    credentials.refresh(Request())
    return build("drive", "v3", credentials=credentials, cache_discovery=False)


def _owner_email(service: Any) -> str:
    resposta = service.about().get(fields="user(emailAddress)").execute()
    email = str(resposta.get("user", {}).get("emailAddress", "")).strip()
    if not email:
        raise BackupError("Google Drive não informou a conta proprietária")
    return email


def _folder_query() -> str:
    return (
        "trashed = false and mimeType = "
        f"{_drive_query_value(DRIVE_FOLDER_MIME)} and "
        f"appProperties has {{ key = {_drive_query_value(FOLDER_PROPERTY)} "
        "and value = 'true' }"
    )


def _bootstrap(service: Any) -> int:
    owner = _owner_email(service)
    pastas = _list_all_files(service, _folder_query())
    if len(pastas) > 1:
        raise BackupError("há mais de uma pasta de backup marcada; resolva manualmente")
    if pastas:
        pasta = pastas[0]
    else:
        pasta = (
            service.files()
            .create(
                body={
                    "name": "Radar — backups Neon criptografados",
                    "mimeType": DRIVE_FOLDER_MIME,
                    "appProperties": {FOLDER_PROPERTY: "true"},
                },
                fields="id,name",
            )
            .execute()
        )
    folder_id = str(pasta["id"])
    validar_acl_privada(_permissions(service, folder_id), owner_email=owner)
    print(f"Pasta privada criada/conferida para {owner}: {pasta.get('name', 'backup Neon')}")
    print(f"GOOGLE_DRIVE_BACKUP_FOLDER_ID={folder_id}")
    return 0


def _backup(args: argparse.Namespace, service: Any) -> int:
    owner = _owner_email(service)
    nome = datetime.now(UTC).strftime("radar-neon-%Y%m%dT%H%M%SZ.dump.age")
    with tempfile.TemporaryDirectory(prefix="radar-neon-backup-") as diretorio:
        caminho = Path(diretorio) / nome
        gerar_backup_criptografado(
            required_env("NEON_BACKUP_DATABASE_URL"),
            required_env("BACKUP_AGE_RECIPIENT"),
            caminho,
        )
        DriveBackupPublisher(service).publish(
            caminho,
            folder_id=required_env("GOOGLE_DRIVE_BACKUP_FOLDER_ID"),
            owner_email=owner,
            file_name=nome,
            run_id=args.run_id,
        )
    print(f"Backup criptografado enviado; retenção={RETENTION_COUNT} cópias semanais")
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("bootstrap", help="cria/conferir a pasta privada no Drive")
    backup = subparsers.add_parser("backup", help="faz e publica um dump criptografado")
    backup.add_argument("--run-id", required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        service = _drive_service_from_secrets()
        if args.command == "bootstrap":
            return _bootstrap(service)
        return _backup(args, service)
    except BackupError as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
