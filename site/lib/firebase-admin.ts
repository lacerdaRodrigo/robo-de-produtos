import { applicationDefault, cert, getApps, initializeApp, type App } from "firebase-admin/app";
import { getAppCheck } from "firebase-admin/app-check";
import { getAuth } from "firebase-admin/auth";

export type IdentidadeFirebase = {
  uid: string;
  email: string | null;
  emailVerificado: boolean;
};

type CredencialDeServico = {
  project_id?: string;
  client_email?: string;
  private_key?: string;
};

function credencialConfigurada(): CredencialDeServico | null {
  const bruto = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!bruto) return null;

  try {
    const objeto = JSON.parse(bruto) as CredencialDeServico;
    if (!objeto.project_id || !objeto.client_email || !objeto.private_key) {
      throw new Error("campos obrigatorios ausentes");
    }
    return objeto;
  } catch {
    // Nunca inclui o JSON ou a excecao original: ambos podem conter a chave.
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON invalido.");
  }
}

function aplicativoAdmin(): App {
  const existente = getApps()[0];
  if (existente) return existente;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  if (!projectId) {
    throw new Error("Firebase Admin nao configurado no servidor.");
  }

  const conta = credencialConfigurada();
  if (conta) {
    if (conta.project_id !== projectId) {
      throw new Error("Conta Firebase pertence a outro projeto.");
    }
    return initializeApp({
      credential: cert({
        projectId: conta.project_id!,
        clientEmail: conta.client_email!,
        privateKey: conta.private_key!,
      }),
      projectId,
    });
  }

  return initializeApp({ credential: applicationDefault(), projectId });
}

/** Verifica assinatura, validade e revogacao do ID token. */
export async function verificarIdToken(token: string): Promise<IdentidadeFirebase> {
  const decodificado = await getAuth(aplicativoAdmin()).verifyIdToken(token, true);
  return {
    uid: decodificado.uid,
    email: typeof decodificado.email === "string" ? decodificado.email : null,
    emailVerificado: decodificado.email_verified === true,
  };
}

/** App Check complementa a autenticacao; nunca concede identidade de usuario. */
export async function verificarTokenAppCheck(token: string): Promise<void> {
  await getAppCheck(aplicativoAdmin()).verifyToken(token);
}
