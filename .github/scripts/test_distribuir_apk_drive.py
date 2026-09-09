import importlib.util
import sys
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("distribuir_apk_drive.py")
SPEC = importlib.util.spec_from_file_location("distribuir_apk_drive", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class DistribuirApkDriveTest(unittest.TestCase):
    def test_escape_query_preserva_id_com_aspas(self):
        self.assertEqual(MODULE._drive_query_value("a'b"), "'a\\'b'")

    def test_consultas_de_propriedade_tem_chave_balanceada(self):
        folder_query = MODULE._folder_query()
        file_query = MODULE._tagged_file_query("folder-id")
        self.assertIn("appProperties has { key = 'radar_apk_folder' and value = 'true' }", folder_query)
        self.assertIn("appProperties has { key = 'radar_apk' and value = 'true' }", file_query)
        self.assertNotIn("'true' }}", folder_query + file_query)

    def test_retencao_remove_somente_arquivos_mais_antigos(self):
        arquivos = [
            {"id": str(numero), "createdTime": f"2026-09-{numero:02d}T00:00:00Z"}
            for numero in range(1, 13)
        ]
        self.assertEqual(
            MODULE.files_to_prune(arquivos),
            ["2", "1"],
        )

    def test_acl_permite_somente_dono_e_destinatario(self):
        MODULE.validate_private_permissions(
            [
                {"type": "user", "role": "owner", "emailAddress": "owner@gmail.com"},
                {"type": "user", "role": "reader", "emailAddress": "destino@gmail.com"},
            ],
            owner_email="owner@gmail.com",
            destination_email="destino@gmail.com",
        )

    def test_acl_rejeita_link_publico(self):
        with self.assertRaises(MODULE.DistributionError):
            MODULE.validate_private_permissions(
                [
                    {"type": "user", "role": "owner", "emailAddress": "owner@gmail.com"},
                    {"type": "anyone", "role": "reader"},
                    {"type": "user", "role": "reader", "emailAddress": "destino@gmail.com"},
                ],
                owner_email="owner@gmail.com",
                destination_email="destino@gmail.com",
            )

    def test_acl_rejeita_usuario_desconhecido(self):
        with self.assertRaises(MODULE.DistributionError):
            MODULE.validate_private_permissions(
                [
                    {"type": "user", "role": "owner", "emailAddress": "owner@gmail.com"},
                    {"type": "user", "role": "reader", "emailAddress": "outra@gmail.com"},
                ],
                owner_email="owner@gmail.com",
                destination_email="destino@gmail.com",
            )

    def test_acl_rejeita_destinatario_com_permissao_de_escrita(self):
        with self.assertRaises(MODULE.DistributionError):
            MODULE.validate_private_permissions(
                [
                    {"type": "user", "role": "owner", "emailAddress": "owner@gmail.com"},
                    {"type": "user", "role": "writer", "emailAddress": "destino@gmail.com"},
                ],
                owner_email="owner@gmail.com",
                destination_email="destino@gmail.com",
            )

    def test_permissao_existente_de_escrita_nao_e_reutilizada(self):
        class Execute:
            def execute(self):
                return {
                    "permissions": [
                        {
                            "type": "user",
                            "role": "writer",
                            "emailAddress": "destino@gmail.com",
                        }
                    ]
                }

        class Permissions:
            def list(self, **_kwargs):
                return Execute()

        class Service:
            def permissions(self):
                return Permissions()

        with self.assertRaises(MODULE.DistributionError):
            MODULE._ensure_destination_permission(
                Service(),
                "arquivo-id",
                owner_email="owner@gmail.com",
                destination_email="destino@gmail.com",
            )


if __name__ == "__main__":
    unittest.main()
