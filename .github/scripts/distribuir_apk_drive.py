#!/usr/bin/env python3
"""Publica uma APK em uma pasta privada do Google Drive e envia o aviso.

O módulo não cria credenciais nem imprime segredos no modo de distribuição.
O modo ``--bootstrap`` é executado somente localmente uma vez para autorizar a
conta proprietária, criar a pasta da automação e salvar o refresh token em um
arquivo local com permissão 0600.
"""

from __future__ import annotations

import argparse
import json
import os
import secrets
import smtplib
import ssl
import sys
from dataclasses import dataclass
from email.message import EmailMessage
from pathlib import Path
from typing import Any, Callable, Iterable, Mapping


DRIVE_FILE_SCOPE = "https://www.googleapis.com/auth/drive.file"
DRIVE_FOLDER_MIME = "application/vnd.google-apps.folder"
APK_MIME = "application/vnd.android.package-archive"
APK_PROPERTY = "radar_apk"
FOLDER_PROPERTY = "radar_apk_folder"
RETENTION_COUNT = 10


class DistributionError(RuntimeError):
    """Erro seguro para exibir no CI sem incluir credenciais."""


@dataclass(frozen=True)
class PublishedFile:
    file_id: str
    name: str
    web_view_link: str
    created_time: str | None
    reused: bool


def required_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise DistributionError(f"variável obrigatória ausente: {name}")
    return value


def _drive_query_value(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "\\'") + "'"


def _lower_email(value: str | None) -> str:
    return (value or "").strip().lower()


def _permission_email(permission: Mapping[str, Any]) -> str:
    return _lower_email(permission.get("emailAddress"))


def validate_private_permissions(
    permissions: Iterable[Mapping[str, Any]],
    *,
    owner_email: str,
    destination_email: str,
) -> None:
    """Confirma que o arquivo só tem o dono e o destinatário pretendido."""

    allowed = {_lower_email(owner_email), _lower_email(destination_email)}
    seen_owner = False
    seen_destination = _lower_email(owner_email) == _lower_email(destination_email)

    for permission in permissions:
        permission_type = str(permission.get("type", "")).lower()
        role = str(permission.get("role", "")).lower()
        if permission_type in {"anyone", "domain", "group"}:
            raise DistributionError(
                "ACL do Drive contém compartilhamento público, por domínio ou grupo"
            )
        if permission_type != "user":
            raise DistributionError("ACL do Drive contém permissão não reconhecida")

        email = _permission_email(permission)
        if email not in allowed:
            raise DistributionError("ACL do Drive contém usuário não autorizado")
        if email == _lower_email(owner_email):
            if role != "owner":
                raise DistributionError("ACL do Drive não identifica o proprietário")
            seen_owner = True
        if email == _lower_email(destination_email):
            if email != _lower_email(owner_email) and role != "reader":
                raise DistributionError(
                    "destinatário possui acesso superior ao modo somente leitura"
                )
            seen_destination = True

    if not seen_owner:
        raise DistributionError("ACL do Drive não contém o proprietário esperado")
    if not seen_destination:
        raise DistributionError("destinatário não recebeu acesso de leitura")


def _tagged_file_query(folder_id: str) -> str:
    return (
        "trashed = false and "
        f"{_drive_query_value(folder_id)} in parents and "
        f"appProperties has {{ key = {_drive_query_value(APK_PROPERTY)} "
        "and value = 'true' }"
    )


def _folder_query() -> str:
    return (
        "trashed = false and mimeType = "
        f"{_drive_query_value(DRIVE_FOLDER_MIME)} and "
        f"appProperties has {{ key = {_drive_query_value(FOLDER_PROPERTY)} "
        "and value = 'true' }"
    )


def files_to_prune(files: Iterable[Mapping[str, Any]], keep: int = RETENTION_COUNT) -> list[str]:
    tagged = sorted(
        files,
        key=lambda item: str(item.get("createdTime", "")),
        reverse=True,
    )
    return [str(item["id"]) for item in tagged[keep:] if item.get("id")]


def _list_all_files(service: Any, query: str) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    page_token: str | None = None
    while True:
        response = (
            service.files()
            .list(
                q=query,
                spaces="drive",
                fields="nextPageToken,files(id,name,webViewLink,createdTime,appProperties)",
                pageSize=1000,
                pageToken=page_token,
            )
            .execute()
        )
        result.extend(response.get("files", []))
        page_token = response.get("nextPageToken")
        if not page_token:
            return result


def _permissions(service: Any, file_id: str) -> list[dict[str, Any]]:
    response = (
        service.permissions()
        .list(
            fileId=file_id,
            fields="permissions(id,type,role,emailAddress,domain,allowFileDiscovery)",
            pageSize=100,
        )
        .execute()
    )
    return list(response.get("permissions", []))


def _ensure_destination_permission(
    service: Any,
    file_id: str,
    *,
    owner_email: str,
    destination_email: str,
) -> None:
    destination = _lower_email(destination_email)
    if destination == _lower_email(owner_email):
        return
    current = _permissions(service, file_id)
    for item in current:
        if _permission_email(item) != destination:
            continue
        if str(item.get("role", "")).lower() != "reader":
            raise DistributionError(
                "destinatário já possui acesso superior ao modo somente leitura"
            )
        return
    (
        service.permissions()
        .create(
            fileId=file_id,
            body={"type": "user", "role": "reader", "emailAddress": destination_email},
            fields="id,type,role,emailAddress",
            sendNotificationEmail=False,
        )
        .execute()
    )


class DrivePublisher:
    def __init__(
        self,
        service: Any,
        *,
        media_factory: Callable[..., Any] | None = None,
    ) -> None:
        self.service = service
        self._media_factory = media_factory

    def _media(self, apk_path: Path) -> Any:
        factory = self._media_factory
        if factory is None:
            try:
                from googleapiclient.http import MediaFileUpload
            except ImportError as error:  # pragma: no cover - CI gives the dependency
                raise DistributionError(
                    "dependências Google ausentes; instale google-api-python-client"
                ) from error
            factory = MediaFileUpload
        return factory(str(apk_path), mimetype=APK_MIME, resumable=True)

    def _find_run(self, folder_id: str, run_key: str) -> dict[str, Any] | None:
        query = (
            f"{_tagged_file_query(folder_id)} and "
            f"appProperties has {{ key = 'run_key' and value = "
            f"{_drive_query_value(run_key)} }}"
        )
        files = _list_all_files(self.service, query)
        return files[0] if files else None

    def publish(
        self,
        apk_path: Path,
        *,
        folder_id: str,
        file_name: str,
        run_key: str,
        run_id: str,
        sha: str,
        owner_email: str,
        destination_email: str,
    ) -> PublishedFile:
        if not apk_path.is_file():
            raise DistributionError(f"APK não encontrada: {apk_path}")

        existing = self._find_run(folder_id, run_key)
        created = existing is None
        metadata = {
            "name": file_name,
            "mimeType": APK_MIME,
            "appProperties": {
                APK_PROPERTY: "true",
                "run_key": run_key,
                "run_id": run_id,
                "sha": sha,
            },
        }
        try:
            if existing:
                response = (
                    self.service.files()
                    .update(
                        fileId=existing["id"],
                        body=metadata,
                        media_body=self._media(apk_path),
                        fields="id,name,webViewLink,createdTime",
                    )
                    .execute()
                )
            else:
                response = (
                    self.service.files()
                    .create(
                        body={**metadata, "parents": [folder_id]},
                        media_body=self._media(apk_path),
                        fields="id,name,webViewLink,createdTime",
                    )
                    .execute()
                )
            file_id = str(response["id"])
            _ensure_destination_permission(
                self.service,
                file_id,
                owner_email=owner_email,
                destination_email=destination_email,
            )
            validate_private_permissions(
                _permissions(self.service, file_id),
                owner_email=owner_email,
                destination_email=destination_email,
            )
        except DistributionError:
            if created and "file_id" in locals():
                try:
                    self.service.files().delete(fileId=file_id).execute()
                except Exception:
                    pass
            raise
        except Exception as error:
            if created and "file_id" in locals():
                try:
                    self.service.files().delete(fileId=file_id).execute()
                except Exception:
                    pass
            raise DistributionError("falha ao publicar ou validar a ACL do Drive") from error

        for old_id in files_to_prune(_list_all_files(self.service, _tagged_file_query(folder_id))):
            if old_id != file_id:
                self.service.files().delete(fileId=old_id).execute()

        return PublishedFile(
            file_id=file_id,
            name=str(response.get("name", file_name)),
            web_view_link=str(response.get("webViewLink", "")),
            created_time=response.get("createdTime"),
            reused=not created,
        )


def _drive_service_from_secrets() -> Any:
    try:
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from googleapiclient.discovery import build
    except ImportError as error:  # pragma: no cover - CI gives the dependency
        raise DistributionError(
            "dependências Google ausentes; instale google-auth e google-api-python-client"
        ) from error

    try:
        client = json.loads(required_env("GOOGLE_DRIVE_OAUTH_CLIENT_JSON"))
        refresh_token = required_env("GOOGLE_DRIVE_REFRESH_TOKEN")
    except json.JSONDecodeError as error:
        raise DistributionError("GOOGLE_DRIVE_OAUTH_CLIENT_JSON não contém JSON válido") from error
    config = client.get("installed") or client.get("web") or client
    client_id = str(config.get("client_id", "")).strip()
    client_secret = str(config.get("client_secret", "")).strip()
    token_uri = str(config.get("token_uri", "https://oauth2.googleapis.com/token")).strip()
    if not client_id or not client_secret:
        raise DistributionError("JSON OAuth não contém client_id/client_secret")

    credentials = Credentials(
        token=None,
        refresh_token=refresh_token,
        token_uri=token_uri,
        client_id=client_id,
        client_secret=client_secret,
        scopes=[DRIVE_FILE_SCOPE],
    )
    credentials.refresh(Request())
    return build("drive", "v3", credentials=credentials, cache_discovery=False)


def send_gmail_message(
    *,
    sender: str,
    password: str,
    destination: str,
    subject: str,
    text_body: str,
    html_body: str,
) -> None:
    message = EmailMessage()
    message["From"] = sender
    message["To"] = destination
    message["Subject"] = subject
    message.set_content(text_body)
    message.add_alternative(html_body, subtype="html")
    try:
        context = ssl.create_default_context()
        with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=context, timeout=60) as smtp:
            smtp.login(sender, password)
            smtp.send_message(message)
    except Exception as error:
        raise DistributionError("falha ao enviar a notificação SMTP do Gmail") from error


def _bootstrap(args: argparse.Namespace) -> int:
    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
    except ImportError as error:  # pragma: no cover - local bootstrap installs it
        raise DistributionError(
            "dependências Google ausentes; instale google-auth-oauthlib e google-api-python-client"
        ) from error

    client_path = Path(args.client_json).expanduser().resolve()
    if not client_path.is_file():
        raise DistributionError(f"JSON OAuth não encontrado: {client_path}")
    flow = InstalledAppFlow.from_client_secrets_file(str(client_path), [DRIVE_FILE_SCOPE])
    credentials = flow.run_local_server(
        port=0,
        access_type="offline",
        prompt="consent",
        authorization_prompt_message=(
            "Autorize o Radar APK Interno no navegador. Se outra conta aparecer, "
            "selecione EMAIL_REMETENTE."
        ),
    )
    service = build("drive", "v3", credentials=credentials, cache_discovery=False)
    owner = (
        service.about()
        .get(fields="user(emailAddress)")
        .execute()
        .get("user", {})
        .get("emailAddress", "")
    )
    expected_owner = args.owner_email.strip().lower()
    if _lower_email(owner) != expected_owner:
        raise DistributionError(
            "OAuth autorizou uma conta diferente de EMAIL_REMETENTE; nenhum secret foi gerado"
        )

    folders = _list_all_files(service, _folder_query())
    if folders:
        folder = folders[0]
    else:
        folder = (
            service.files()
            .create(
                body={
                    "name": args.folder_name,
                    "mimeType": DRIVE_FOLDER_MIME,
                    "appProperties": {FOLDER_PROPERTY: "true"},
                },
                fields="id,name,webViewLink,createdTime",
            )
            .execute()
        )
    folder_id = str(folder["id"])
    validate_private_permissions(
        _permissions(service, folder_id),
        owner_email=owner,
        destination_email=owner,
    )

    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(credentials.refresh_token or "", encoding="utf-8")
    output_path.chmod(0o600)
    if not credentials.refresh_token:
        raise DistributionError("Google não retornou refresh token; bootstrap não concluído")
    print(f"Conta autorizada: {owner}")
    print(f"Pasta privada: {folder.get('name', args.folder_name)}")
    print(f"GOOGLE_DRIVE_FOLDER_ID={folder_id}")
    print(f"GOOGLE_DRIVE_REFRESH_TOKEN foi salvo em: {output_path}")
    print("Não compartilhe o arquivo do token nem o JSON OAuth.")
    return 0


def _distribution(args: argparse.Namespace) -> int:
    owner = required_env("EMAIL_REMETENTE")
    destination = required_env("EMAIL_DESTINO")
    publisher = DrivePublisher(_drive_service_from_secrets())
    published = publisher.publish(
        Path(args.apk).expanduser().resolve(),
        folder_id=required_env("GOOGLE_DRIVE_FOLDER_ID"),
        file_name=args.file_name,
        run_key=args.run_key,
        run_id=args.run_id,
        sha=args.sha,
        owner_email=owner,
        destination_email=destination,
    )
    if not published.web_view_link:
        raise DistributionError("Drive não retornou link privado para a APK")
    subject = f"APK interna Radar pronta — {args.version} — {args.sha[:8]}"
    text_body = (
        "A nova APK interna do Radar de Benefícios está pronta.\n\n"
        f"Versão: {args.version}\n"
        f"Execução: {args.run_id}\n"
        f"Commit: {args.sha}\n"
        "Tipo: debug interna\n"
        "API: https://robo-de-produtos.vercel.app\n\n"
        f"Download privado: {published.web_view_link}\n\n"
        "A APK pode substituir a instalada no Samsung somente se o application "
        "id e a assinatura forem compatíveis."
    )
    html_body = (
        "<p>A nova APK interna do Radar de Benefícios está pronta.</p>"
        f"<p><b>Versão:</b> {args.version}<br>"
        f"<b>Execução:</b> {args.run_id}<br>"
        f"<b>Commit:</b> {args.sha}<br>"
        "<b>Tipo:</b> debug interna<br>"
        "<b>API:</b> https://robo-de-produtos.vercel.app</p>"
        f'<p><a href="{published.web_view_link}">Baixar APK privada</a></p>'
        "<p>A atualização depende de application id e assinatura compatíveis.</p>"
    )
    send_gmail_message(
        sender=owner,
        password=required_env("SENHA_APP_GMAIL"),
        destination=destination,
        subject=subject,
        text_body=text_body,
        html_body=html_body,
    )
    print(
        f"APK distribuída com sucesso: nome={published.name} "
        f"reutilizada={published.reused} retencao={RETENTION_COUNT}"
    )
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    bootstrap = subparsers.add_parser("bootstrap", help="autoriza o Drive localmente")
    bootstrap.add_argument("--client-json", required=True)
    bootstrap.add_argument("--owner-email", required=True)
    bootstrap.add_argument("--output", required=True, help="arquivo local 0600 para o refresh token")
    bootstrap.add_argument("--folder-name", default="Radar APKs privadas")

    distribute = subparsers.add_parser("distribute", help="publica e notifica no CI")
    distribute.add_argument("--apk", required=True)
    distribute.add_argument("--file-name", required=True)
    distribute.add_argument("--run-key", required=True)
    distribute.add_argument("--run-id", required=True)
    distribute.add_argument("--sha", required=True)
    distribute.add_argument("--version", required=True)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    try:
        if args.command == "bootstrap":
            return _bootstrap(args)
        return _distribution(args)
    except DistributionError as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
