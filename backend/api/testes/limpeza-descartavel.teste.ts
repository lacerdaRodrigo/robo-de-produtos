import { neon } from "@neondatabase/serverless";
import { describe, expect, it, vi } from "vitest";

vi.mock("server-only", () => ({}));

import {
  apagarDadosLivelo,
  resetarDadosInter,
  resumoDadosInter,
  resumoDadosLivelo,
} from "../lib/limpeza";

const habilitado = process.env.ACEITE_F5_DESCARTAVEL === "true";

function conectarDescartavel() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error("DATABASE_URL ausente no aceite descartavel");
  const banco = decodeURIComponent(new URL(url).pathname.replace(/^\//, ""));
  if (!banco.startsWith("radar_aceite_f5_")) {
    throw new Error("aceite destrutivo recusado fora de banco descartavel");
  }
  return neon(url);
}

async function popularBanco() {
  const sql = conectarDescartavel();
  await sql("INSERT INTO loja (id, nome, categoria) VALUES (1, 'Loja aceite', 'Teste')");
  await sql("INSERT INTO apelido (id, loja_id, texto) VALUES (1, 1, 'Loja A')");
  await sql(
    "INSERT INTO execucao (id, momento, parceiros_lidos, alertas, versao) " +
      "VALUES (1, now(), 1, 1, 'aceite')",
  );
  await sql(
    "INSERT INTO parceiro_livelo (id, id_externo, nome, pontos_atuais, moeda, " +
      "atualizado_execucao_id) VALUES (1, 'LIV-1', 'Loja aceite', 2.90, 'R$', 1)",
  );
  await sql("UPDATE loja SET parceiro_livelo_id = 1 WHERE id = 1");
  await sql(
    "INSERT INTO pontuacao (id, execucao_id, loja_id, nome, pontos_atuais) " +
      "VALUES (1, 1, 1, 'Loja aceite', 2.90)",
  );
  await sql("INSERT INTO disparo_manual (id) VALUES (1)");

  await sql(
    "INSERT INTO loja_inter (id, id_externo, slug, nome, nome_busca, slug_busca, " +
      "cashback_principal_texto, vista_em) " +
      "VALUES (1, 'inter-1', 'inter-1', 'Inter aceite', 'inter aceite', 'inter 1', '5%', now())",
  );
  await sql("INSERT INTO favorita_inter (loja_inter_id) VALUES (1)");
  await sql(
    "INSERT INTO execucao_inter (id, iniciada_em, concluida_em, estado, lojas_lidas, " +
      "lojas_validas, favoritas_encontradas, versao) " +
      "VALUES (1, now(), now(), 'sucesso', 1, 1, 1, 'aceite')",
  );
  await sql(
    "INSERT INTO cashback_inter (id, execucao_inter_id, loja_inter_id, nome, encontrada) " +
      "VALUES (1, 1, 1, 'Inter aceite', true)",
  );
  await sql("INSERT INTO disparo_manual_inter (id) VALUES (1)");

  await sql(
    "INSERT INTO loja_direta_inter (id, id_externo, slug, nome, nome_busca, selecionada, " +
      "vista_em) VALUES (1, 'direta-1', 'direta-1', 'Direta aceite', 'direta aceite', true, now())",
  );
  await sql(
    "INSERT INTO execucao_produtos_inter (id, iniciada_em, concluida_em, estado, " +
      "lojas_planejadas, lojas_sucesso, versao) " +
      "VALUES (1, now(), now(), 'sucesso', 1, 1, 'aceite')",
  );
  await sql(
    "INSERT INTO execucao_loja_produtos_inter (id, execucao_produtos_inter_id, " +
      "loja_direta_inter_id, iniciada_em, concluida_em, estado, paginas, produtos_lidos, " +
      "produtos_unicos, duplicados, qualidade, tentativas) " +
      "VALUES (1, 1, 1, now(), now(), 'sucesso', 1, 1, 1, 0, 'completa', 1)",
  );
  await sql(
    "INSERT INTO estagio_produto_inter (execucao_loja_produtos_inter_id, id_externo, " +
      "nome, nome_busca, caminho, preco_atual_texto, preco_atual) " +
      "VALUES (1, 'produto-1', 'Produto aceite', 'produto aceite', '/produto-1', 'R$ 10,00', 10)",
  );
  await sql(
    "INSERT INTO produto_direto_inter (id, loja_direta_inter_id, id_externo, nome, " +
      "nome_busca, caminho) VALUES (1, 1, 'produto-1', 'Produto aceite', " +
      "'produto aceite', '/produto-1')",
  );
  await sql(
    "INSERT INTO oferta_direta_inter_atual (produto_direto_inter_id, " +
      "execucao_loja_produtos_inter_id, momento, preco_atual_texto, preco_atual) " +
      "VALUES (1, 1, now(), 'R$ 10,00', 10)",
  );
  await sql(
    "INSERT INTO medicao_produto_direto_inter (id, produto_direto_inter_id, " +
      "execucao_loja_produtos_inter_id, momento, preco_atual_texto, preco_atual) " +
      "VALUES (1, 1, 1, now(), 'R$ 10,00', 10)",
  );

  await sql("INSERT INTO tentativa_login (id, origem) VALUES (1, 'aceite')");
  await sql(
    "INSERT INTO usuario_app (id, email, firebase_uid, papel) " +
      "VALUES (1, 'aceite@example.com', 'uid-aceite', 'admin')",
  );
  await sql(
    "INSERT INTO limite_requisicao_app (chave_hash) VALUES (repeat('a', 64))",
  );
  await sql(
    "INSERT INTO auditoria_app (id, usuario_app_id, identidade_hash, origem_hash, " +
      "requisicao_id, acao, resultado, codigo) VALUES " +
      "(1, 1, repeat('b', 64), repeat('c', 64), 'aceite', 'aceite', 'sucesso', 'ok')",
  );
  await sql(
    "INSERT INTO solicitacao_disparo_app (dominio, chave_idempotencia, usuario_app_id, " +
      "estado, ativa) VALUES " +
      "('livelo', 'aceite-livelo-1234', 1, 'aceita', false), " +
      "('inter', 'aceite-inter-12345', 1, 'aceita', false), " +
      "('produtos_inter', 'aceite-produtos-12', 1, 'aceita', false)",
  );
}

async function contagensPreservadas() {
  const sql = conectarDescartavel();
  const [linha] = (await sql(
    "SELECT (SELECT count(*)::int FROM tentativa_login) AS login, " +
      "(SELECT count(*)::int FROM usuario_app) AS usuarios, " +
      "(SELECT count(*)::int FROM limite_requisicao_app) AS limites, " +
      "(SELECT count(*)::int FROM auditoria_app) AS auditorias, " +
      "(SELECT count(*)::int FROM solicitacao_disparo_app) AS solicitacoes",
  )) as Array<Record<string, number>>;
  return linha;
}

describe.skipIf(!habilitado)("aceite destrutivo Fase 5 em banco descartável", () => {
  it(
    "valida rollback, isolamento, repetição e preservação técnica",
    async () => {
      const sql = conectarDescartavel();
      await popularBanco();

      expect(await resumoDadosLivelo()).toEqual({
        parceirosCatalogo: 1,
        lojas: 1,
        apelidos: 1,
        execucoes: 1,
        pontuacoes: 1,
        disparos: 1,
      });
      expect(await resumoDadosInter()).toEqual({
        lojasParceiras: 1,
        favoritas: 1,
        execucoesParceiras: 1,
        cashbacks: 1,
        vendedoresDiretos: 1,
        selecionadas: 1,
        produtos: 1,
        ofertasAtuais: 1,
        medicoes: 1,
        execucoesProdutos: 1,
      });
      expect(await contagensPreservadas()).toEqual({
        login: 1,
        usuarios: 1,
        limites: 1,
        auditorias: 1,
        solicitacoes: 3,
      });

      await sql(
        "ALTER TABLE preferencia ADD CONSTRAINT aceite_forcar_rollback " +
          "CHECK (chave <> 'multiplicador_padrao') NOT VALID",
      );
      await expect(apagarDadosLivelo()).rejects.toBeDefined();
      expect((await resumoDadosLivelo()).lojas).toBe(1);
      await sql("ALTER TABLE preferencia DROP CONSTRAINT aceite_forcar_rollback");

      await apagarDadosLivelo();
      expect(await resumoDadosLivelo()).toEqual({
        parceirosCatalogo: 0,
        lojas: 0,
        apelidos: 0,
        execucoes: 0,
        pontuacoes: 0,
        disparos: 0,
      });
      expect((await resumoDadosInter()).produtos).toBe(1);
      const preferencias = await sql("SELECT chave, valor FROM preferencia ORDER BY chave");
      expect(preferencias).toEqual([
        { chave: "assinante_clube", valor: "false" },
        { chave: "multiplicador_padrao", valor: "2.0" },
        { chave: "piso_pontos_padrao", valor: "4" },
      ]);
      expect(await contagensPreservadas()).toEqual({
        login: 1,
        usuarios: 1,
        limites: 1,
        auditorias: 1,
        solicitacoes: 3,
      });
      const disparoLivelo = await sql("INSERT INTO disparo_manual DEFAULT VALUES RETURNING id");
      expect(String(disparoLivelo[0]?.id)).toBe("1");
      await apagarDadosLivelo();
      expect((await resumoDadosLivelo()).disparos).toBe(0);

      await sql("INSERT INTO loja (id, nome, categoria) VALUES (1, 'Livelo preservada', 'Teste')");
      await sql(
        "CREATE TABLE aceite_bloqueio_inter (loja_id BIGINT REFERENCES loja_inter(id))",
      );
      await sql("INSERT INTO aceite_bloqueio_inter (loja_id) VALUES (1)");
      await expect(resetarDadosInter()).rejects.toBeDefined();
      expect((await resumoDadosInter()).lojasParceiras).toBe(1);
      await sql("DROP TABLE aceite_bloqueio_inter");

      await resetarDadosInter();
      expect(await resumoDadosInter()).toEqual({
        lojasParceiras: 0,
        favoritas: 0,
        execucoesParceiras: 0,
        cashbacks: 0,
        vendedoresDiretos: 0,
        selecionadas: 0,
        produtos: 0,
        ofertasAtuais: 0,
        medicoes: 0,
        execucoesProdutos: 0,
      });
      expect((await resumoDadosLivelo()).lojas).toBe(1);
      expect(await contagensPreservadas()).toEqual({
        login: 1,
        usuarios: 1,
        limites: 1,
        auditorias: 1,
        solicitacoes: 3,
      });
      const disparoInter = await sql(
        "INSERT INTO disparo_manual_inter DEFAULT VALUES RETURNING id",
      );
      expect(String(disparoInter[0]?.id)).toBe("1");
      await resetarDadosInter();
      expect((await resumoDadosInter()).lojasParceiras).toBe(0);

      await sql(
        "INSERT INTO solicitacao_disparo_app (dominio, chave_idempotencia, usuario_app_id, " +
          "estado) VALUES " +
          "('livelo', 'novo-livelo-12345', 1, 'reservada'), " +
          "('inter', 'novo-inter-123456', 1, 'reservada'), " +
          "('produtos_inter', 'novo-produtos-123', 1, 'reservada')",
      );
    },
    120_000,
  );
});
