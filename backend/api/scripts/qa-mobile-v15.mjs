#!/usr/bin/env node

/**
 * Fixture controlada do reteste Mobile V15.
 *
 * Este arquivo só pode escrever com todas as travas abaixo. O banco deve ser
 * uma conexão direta/unpooled do ambiente de teste, nunca o pooler de
 * produção. O backup fica fora do repositório e é removido somente depois de
 * uma restauração confirmada.
 */
import { mkdir, readFile, writeFile, unlink } from "node:fs/promises";
import { dirname, isAbsolute, relative, resolve } from "node:path";
import process from "node:process";
import { Pool } from "@neondatabase/serverless";

const CONFIRMACAO = "I_UNDERSTAND_QA_FIXTURE";
const RAIZ_REPO = resolve(new URL("../../../..", import.meta.url).pathname);

function falhar(mensagem) {
  throw new Error(`[QA V15 bloqueado] ${mensagem}`);
}

function ambienteSeguro({ escreve = false } = {}) {
  const url = process.env.DATABASE_URL?.trim();
  const runId = process.env.QA_RUN_ID?.trim();
  const ambiente = process.env.QA_ENVIRONMENT?.trim();
  const conta = process.env.QA_ACCOUNT_ID?.trim();
  if (!url) falhar("DATABASE_URL ausente.");
  if (url.includes("-pooler.")) falhar("use DATABASE_URL direta/unpooled.");
  if (!runId || !/^[A-Za-z0-9][A-Za-z0-9_-]{5,59}$/.test(runId)) {
    falhar("QA_RUN_ID ausente ou fora do formato seguro.");
  }
  if (ambiente !== "test") falhar("QA_ENVIRONMENT precisa ser exatamente test.");
  if (!conta || !/^\d+$/.test(conta)) falhar("QA_ACCOUNT_ID precisa ser numérico.");
  if (escreve && process.env.QA_CONFIRM !== CONFIRMACAO) {
    falhar(`escrita exige QA_CONFIRM=${CONFIRMACAO}.`);
  }
  return { url, runId, conta };
}

function caminhoBackup(runId) {
  const informado = process.env.QA_BACKUP_PATH?.trim();
  const caminho = resolve(informado || `/tmp/radar-qa-${runId}.json`);
  if (!isAbsolute(caminho)) falhar("QA_BACKUP_PATH precisa ser absoluto.");
  if (relative(RAIZ_REPO, caminho) && !relative(RAIZ_REPO, caminho).startsWith("..")) {
    falhar("backup não pode ficar dentro do repositório.");
  }
  return caminho;
}

async function consultar(executor, texto, valores = []) {
  const resposta = await executor.query(texto, valores);
  return resposta.rows;
}

async function preflight() {
  const { url, conta, runId } = ambienteSeguro();
  const pool = new Pool({ connectionString: url, max: 1 });
  try {
    const tabelas = await consultar(
      pool,
      `SELECT to_regclass(x) AS nome
         FROM unnest(ARRAY['public.usuario_app', 'public.acompanhamento_usuario',
           'public.evento_alerta', 'public.notificacao_outbox_alerta']) AS x`,
    );
    const ausentes = tabelas.filter((linha) => linha.nome === null);
    if (ausentes.length) falhar("schema de alertas incompleto; migration anterior ausente.");
    const contaExiste = await consultar(pool, "SELECT 1 FROM usuario_app WHERE id = $1", [conta]);
    if (!contaExiste.length) falhar("QA_ACCOUNT_ID não existe no ambiente de teste.");
    const duplicadas = await consultar(
      pool,
      "SELECT count(*)::int AS total FROM evento_alerta WHERE usuario_app_id = $1 AND coleta_id LIKE $2",
      [conta, `${runId}-%`],
    );
    console.log(JSON.stringify({ ok: true, ambiente: "test", runId, eventosDoCiclo: duplicadas[0]?.total ?? 0 }));
  } finally {
    await pool.end();
  }
}

async function preparar() {
  const { url, conta, runId } = ambienteSeguro({ escreve: true });
  const backup = caminhoBackup(runId);
  await mkdir(dirname(backup), { recursive: true, mode: 0o700 });
  const pool = new Pool({ connectionString: url, max: 1 });
  const cliente = await pool.connect();
  try {
    await cliente.query("BEGIN");
    const original = {
      runId,
      conta,
      acompanhamentos: await consultar(cliente, "SELECT * FROM acompanhamento_usuario WHERE usuario_app_id = $1 ORDER BY id", [conta]),
      alertas: await consultar(cliente, "SELECT * FROM evento_alerta WHERE usuario_app_id = $1 ORDER BY id", [conta]),
      preferencia: await consultar(cliente, "SELECT * FROM preferencia_alerta WHERE usuario_app_id = $1", [conta]),
      registradoEm: new Date().toISOString(),
    };
    const fontes = await consultar(
      cliente,
      `(SELECT 'livelo'::text AS origem, id::text AS entidade_id, nome
          FROM parceiro_livelo WHERE ativo = TRUE ORDER BY id LIMIT 8)
       UNION ALL
       (SELECT 'inter_cashback', id::text, nome
          FROM loja_inter WHERE ativa = TRUE ORDER BY id LIMIT 8)
       UNION ALL
       (SELECT 'inter_produto', id::text, nome
          FROM produto_direto_inter WHERE ativo = TRUE ORDER BY id LIMIT 8)
       UNION ALL
       (SELECT 'pichau', id::text, nome
          FROM pichau_produto WHERE presente_no_catalogo = TRUE ORDER BY id LIMIT 8)`,
    );
    if (fontes.length < 4) falhar("menos de uma entidade real por origem disponível.");
    await writeFile(backup, JSON.stringify({ ...original, fontes }, null, 2), { mode: 0o600 });

    for (const fonte of fontes) {
      await cliente.query(
        `INSERT INTO acompanhamento_usuario (usuario_app_id, origem, entidade_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (usuario_app_id, origem, entidade_id) DO NOTHING`,
        [conta, fonte.origem, fonte.entidade_id],
      );
    }
    const acompanhamentos = await consultar(
      cliente,
      `SELECT a.id, a.origem, a.entidade_id, coalesce(p.nome, l.nome, i.nome, pi.nome) AS nome
         FROM acompanhamento_usuario a
         LEFT JOIN parceiro_livelo p ON a.origem = 'livelo' AND p.id = a.entidade_id
         LEFT JOIN loja_inter l ON a.origem = 'inter_cashback' AND l.id = a.entidade_id
         LEFT JOIN produto_direto_inter i ON a.origem = 'inter_produto' AND i.id = a.entidade_id
         LEFT JOIN pichau_produto pi ON a.origem = 'pichau' AND pi.id = a.entidade_id
        WHERE a.usuario_app_id = $1`,
      [conta],
    );
    if (acompanhamentos.length === 0) falhar("nenhum acompanhamento real foi preparado.");
    for (let indice = 0; indice < 25; indice += 1) {
      const item = acompanhamentos[indice % acompanhamentos.length];
      const tipo = item.origem === "livelo" ? "pontuacao" : item.origem === "inter_cashback" ? "cashback" : "preco";
      await cliente.query(
        `INSERT INTO evento_alerta
          (usuario_app_id, acompanhamento_id, origem, tipo, entidade_id,
           entidade_nome, coleta_id, valor_anterior, valor_atual, unidade,
           direcao, lido, notificar_push)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, FALSE)
         ON CONFLICT (usuario_app_id, origem, tipo, entidade_id, coleta_id) DO NOTHING`,
        [conta, item.id, item.origem, tipo, item.entidade_id, item.nome || "Fixture QA",
          `${runId}-evento-${String(indice + 1).padStart(2, "0")}`, "10.00", "11.00",
          tipo === "pontuacao" ? "pontos_por_real" : tipo === "cashback" ? "percentual" : "reais", "aumento"],
      );
    }
    await cliente.query(
      "UPDATE notificacao_outbox_alerta SET estado = 'enviada', atualizado_em = now() WHERE usuario_app_id = $1 AND coleta_id LIKE $2",
      [conta, `${runId}-%`],
    );
    await cliente.query("COMMIT");
    console.log(JSON.stringify({ ok: true, acao: "preparado", runId, backup }));
  } catch (erro) {
    await cliente.query("ROLLBACK");
    throw erro;
  } finally {
    cliente.release();
    await pool.end();
  }
}

async function restaurar() {
  const { url, conta, runId } = ambienteSeguro({ escreve: true });
  const backup = caminhoBackup(runId);
  const conteudo = JSON.parse(await readFile(backup, "utf8"));
  if (conteudo.runId !== runId || String(conteudo.conta) !== conta) {
    falhar("backup não corresponde ao QA_RUN_ID ou QA_ACCOUNT_ID atual.");
  }
  const pool = new Pool({ connectionString: url, max: 1 });
  const cliente = await pool.connect();
  try {
    await cliente.query("BEGIN");
    await cliente.query("DELETE FROM evento_alerta WHERE usuario_app_id = $1 AND coleta_id LIKE $2", [conta, `${runId}-%`]);
    await cliente.query("DELETE FROM notificacao_outbox_alerta WHERE usuario_app_id = $1 AND coleta_id LIKE $2", [conta, `${runId}-%`]);
    const idsOriginais = (conteudo.acompanhamentos || []).map((linha) => linha.id);
    if (idsOriginais.length) {
      await cliente.query(
        "DELETE FROM acompanhamento_usuario WHERE usuario_app_id = $1 AND NOT (id = ANY($2::bigint[]))",
        [conta, idsOriginais],
      );
    } else {
      await cliente.query("DELETE FROM acompanhamento_usuario WHERE usuario_app_id = $1", [conta]);
    }
    await cliente.query("COMMIT");
    if (process.env.QA_DELETE_BACKUP === "true") await unlink(backup);
    console.log(JSON.stringify({ ok: true, acao: "restaurado", runId, backupMantido: process.env.QA_DELETE_BACKUP !== "true" }));
  } catch (erro) {
    await cliente.query("ROLLBACK");
    throw erro;
  } finally {
    cliente.release();
    await pool.end();
  }
}

const acao = process.argv[2];
try {
  if (acao === "--preflight") await preflight();
  else if (acao === "--prepare") await preparar();
  else if (acao === "--restore") await restaurar();
  else falhar("use --preflight, --prepare ou --restore.");
} catch (erro) {
  console.error(erro instanceof Error ? erro.message : erro);
  process.exitCode = 1;
}
