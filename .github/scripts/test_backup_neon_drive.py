import importlib.util
import subprocess
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

MODULE_PATH = Path(__file__).with_name("backup_neon_drive.py")
SPEC = importlib.util.spec_from_file_location("backup_neon_drive", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class BackupNeonDriveTest(unittest.TestCase):
    def test_url_precisa_ser_postgres_com_ssl_sem_expor_credencial(self):
        with self.assertRaises(MODULE.BackupError) as contexto:
            MODULE.validate_database_url("postgresql://usuario:secreto@db.example/neon")
        self.assertNotIn("secreto", str(contexto.exception))

    def test_dump_em_claro_e_removido_depois_da_cifragem(self):
        comandos = []

        def executar(comando, **_):
            comandos.append(comando)
            if comando[0] == "pg_dump":
                Path(comando[comando.index("--file") + 1]).write_bytes(b"dump de teste")
            else:
                Path(comando[comando.index("--output") + 1]).write_bytes(
                    b"age-encryption.org/v1\nconteudo cifrado"
                )
            return subprocess.CompletedProcess(comando, 0, b"", b"")

        with TemporaryDirectory() as diretorio:
            destino = Path(diretorio) / "backup.dump.age"
            MODULE.gerar_backup_criptografado(
                "postgresql://usuario:senha@db.example/neon?sslmode=require",
                "age1" + "a" * 30,
                destino,
                executar=executar,
            )
            self.assertTrue(destino.is_file())
            self.assertEqual(destino.read_bytes()[: len(MODULE.AGE_HEADER)], MODULE.AGE_HEADER)
            self.assertEqual(list(Path(diretorio).glob(".radar-neon-*.dump")), [])
            self.assertEqual(list(Path(diretorio).glob(".radar-neon-*.pgpass")), [])

        self.assertEqual([comando[0] for comando in comandos], ["pg_dump", "age"])
        self.assertIn("--no-owner", comandos[0])
        self.assertIn("--no-acl", comandos[0])
        self.assertNotIn("senha", comandos[0][-1])

    def test_falha_no_dump_nao_deixa_arquivo_publicavel(self):
        def executar(comando, **_):
            return subprocess.CompletedProcess(comando, 1, b"", b"erro secreto")

        with TemporaryDirectory() as diretorio:
            destino = Path(diretorio) / "backup.dump.age"
            with self.assertRaises(MODULE.BackupError) as contexto:
                MODULE.gerar_backup_criptografado(
                    "postgresql://usuario:senha@db.example/neon?sslmode=require",
                    "age1" + "a" * 30,
                    destino,
                    executar=executar,
                )
            self.assertFalse(destino.exists())
            self.assertNotIn("senha", str(contexto.exception))

    def test_acl_rejeita_publico_e_qualquer_usuario_extra(self):
        for permissao in (
            {"type": "anyone", "role": "reader"},
            {"type": "user", "role": "reader", "emailAddress": "outro@example.com"},
        ):
            with self.subTest(permissao=permissao), self.assertRaises(MODULE.BackupError):
                MODULE.validar_acl_privada(
                    [
                        {"type": "user", "role": "owner", "emailAddress": "dono@example.com"},
                        permissao,
                    ],
                    owner_email="dono@example.com",
                )

    def test_retencao_mantem_as_versoes_mais_novas(self):
        arquivos = [
            {"id": str(numero), "createdTime": f"2026-09-{numero:02d}T00:00:00Z"}
            for numero in range(1, 15)
        ]
        self.assertEqual(MODULE.files_to_prune(arquivos, keep=12), ["2", "1"])


if __name__ == "__main__":
    unittest.main()
