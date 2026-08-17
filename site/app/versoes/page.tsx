import Link from "next/link";

import { VERSAO_ATUAL } from "@/lib/versao";
import { Cabecalho } from "../componentes/cabecalho";
import { SeletorDeRobos } from "../componentes/seletor-robos";
import { Rodape } from "../rodape";

const MARCOS = [
  {
    versao: "1.22.1",
    data: "17 ago 2026",
    titulo: "Catálogo de produtos validado",
    descricao: "Contrato real do Shopping Inter validado com a primeira loja da V4.",
    tipo: "Patch",
  },
  {
    versao: "1.22.0",
    data: "17 ago 2026",
    titulo: "Produtos do Shopping Inter",
    descricao: "Catálogo paginado, busca local, histórico e workflow matricial da V4.",
    tipo: "Minor",
  },
  {
    versao: "1.21.0",
    data: "15 ago 2026",
    titulo: "Cashback do Shopping Inter",
    descricao: "Novo robô independente para acompanhar cashback e condições de lojas.",
    tipo: "Minor",
  },
  {
    versao: "1.15.0",
    data: "13 ago 2026",
    titulo: "Identidade do Radar",
    descricao: "Novo e-mail e consolidação da identidade visual do projeto.",
    tipo: "Minor",
  },
  {
    versao: "1.6.0",
    data: "12 ago 2026",
    titulo: "Site público",
    descricao: "Painel Next.js com leitura pública e edição protegida.",
    tipo: "Minor",
  },
  {
    versao: "1.0.0",
    data: "10 ago 2026",
    titulo: "Primeiro lançamento",
    descricao: "Fatia vertical funcional do robô de pontuação Livelo.",
    tipo: "Major",
  },
];

export default function PaginaDeVersoes() {
  return (
    <>
      <Cabecalho atual="/versoes" />
      <main className="pagina">
        <SeletorDeRobos atual="" />

        <section className="hero-painel hero-versoes">
          <span className="hero-rotulo">Engenharia do projeto</span>
          <h1>Histórico de versões</h1>
          <p>
            O Radar usa versionamento semântico, Conventional Commits e releases automáticos.
          </p>
          <strong className="versao-atual">Versão atual v{VERSAO_ATUAL}</strong>
        </section>

        <section className="bloco semver-explicacao">
          <div>
            <strong>MAJOR</strong>
            <span>mudança incompatível</span>
          </div>
          <div>
            <strong>MINOR</strong>
            <span>nova funcionalidade compatível</span>
          </div>
          <div>
            <strong>PATCH</strong>
            <span>correção compatível</span>
          </div>
        </section>

        <div className="linha-do-tempo">
          {MARCOS.map((marco) => (
            <article className="marco-versao" key={marco.versao}>
              <div className="marco-versao-cabecalho">
                <strong>v{marco.versao}</strong>
                <span className="etiqueta">{marco.tipo}</span>
              </div>
              <h2>{marco.titulo}</h2>
              <p>{marco.descricao}</p>
              <time>{marco.data}</time>
            </article>
          ))}
        </div>

        <p className="vazio">
          O histórico técnico completo possui todas as tags, commits e notas de lançamento.{" "}
          <a href="https://github.com/lacerdaRodrigo/robo-livelo/releases">
            Abrir Releases no GitHub
          </a>
          {" · "}
          <a href="https://github.com/lacerdaRodrigo/robo-livelo/blob/main/CHANGELOG.md">
            Abrir CHANGELOG
          </a>
        </p>

        <p>
          <Link href="/ajuda">Entender como os robôs funcionam</Link>
        </p>
        <Rodape />
      </main>
    </>
  );
}
