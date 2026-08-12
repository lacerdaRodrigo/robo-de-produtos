import { pontuacoes, ultimaExecucao, type PontuacaoDeLoja } from "@/lib/banco";
import { dia, idade, dataHora, pontos, rotuloDoClube, terminaHoje } from "@/lib/formato";
import { Rodape } from "./rodape";

// O robo roda 3x ao dia; revalidar de 5 em 5 minutos deixa a pagina fresca
// sem transformar cada visita numa consulta ao banco (C08).
export const revalidate = 300;

function Validade({ fim }: { fim: string | null }) {
  if (!fim) {
    return null;
  }
  return terminaHoje(fim) ? (
    <span className="etiqueta hoje">Termina hoje!</span>
  ) : (
    <span className="etiqueta">Válido até {dia(fim)}</span>
  );
}

function Loja({ loja }: { loja: PontuacaoDeLoja }) {
  const rotuloClube = rotuloDoClube(loja.campanha);
  const naoEncontrada = loja.pontos_atuais === null;

  return (
    <article className={loja.alertou ? "cartao alertou" : "cartao"}>
      <div className="linha">
        <span className="nome">
          {loja.link ? <a href={loja.link}>{loja.nome}</a> : loja.nome}
        </span>
        <span className="pontos">
          {naoEncontrada
            ? "não encontrada"
            : `${loja.prefixo_ate ? "Até " : ""}${pontos(loja.pontos_atuais)} pontos por ${loja.moeda} 1`}
        </span>
      </div>

      {!naoEncontrada && (
        // RN30: atual, base e o valor que dispara o alerta, lado a lado.
        // Sem os tres, o limiar desregula em silencio.
        <p className="detalhe">
          base {pontos(loja.pontos_base)} · dispara em {pontos(loja.valor_de_disparo)}
          {loja.pontos_clube !== null && (
            <> · Clube {pontos(loja.pontos_clube)}{rotuloClube ? ` (${rotuloClube})` : ""}</>
          )}
        </p>
      )}

      <p className="detalhe">
        {loja.alertou && <span className="etiqueta alerta">alerta</span>}{" "}
        <Validade fim={loja.fim_promocao} />
      </p>
    </article>
  );
}

export default async function Pagina() {
  let execucao: Awaited<ReturnType<typeof ultimaExecucao>> = null;
  let falhaNoBanco = false;
  try {
    execucao = await ultimaExecucao();
  } catch {
    // Banco fora do ar vira pagina que diz isso, nao erro 500 mudo. Mesma
    // linha do robo: falha nunca e silenciosa (O3).
    falhaNoBanco = true;
  }

  if (falhaNoBanco) {
    return (
      <main>
        <h1>Pontuação Livelo</h1>
        <p className="aviso">
          Não deu para ler o banco agora. A página volta sozinha quando ele responder — nada
          foi perdido, o robô continua registrando cada execução.
        </p>
        <Rodape />
      </main>
    );
  }

  if (!execucao) {
    return (
      <main>
        <h1>Pontuação Livelo</h1>
        <p className="aviso">
          Nenhuma execução registrada ainda. A página fica assim até o robô rodar pela
          primeira vez com o banco configurado — melhor dizer isso do que mostrar uma lista
          vazia que parece atualizada.
        </p>
        <Rodape />
      </main>
    );
  }

  const lojas = await pontuacoes(execucao.id);
  const alertadas = lojas.filter((l) => l.alertou);
  const carimbo = idade(execucao.momento);

  const porCategoria = new Map<string, PontuacaoDeLoja[]>();
  for (const loja of lojas) {
    const categoria = loja.categoria ?? "Sem categoria";
    porCategoria.set(categoria, [...(porCategoria.get(categoria) ?? []), loja]);
  }

  return (
    <main>
      <h1>Pontuação Livelo</h1>
      {/* RN26: o carimbo e obrigatorio e sempre visivel. E o que sustenta MS6
          — sem ele, pagina velha e pagina mentirosa. */}
      <p className={carimbo.velho ? "carimbo velho" : "carimbo"}>
        Atualizado {carimbo.texto} · {dataHora(execucao.momento)} · {execucao.parceiros_lidos}{" "}
        parceiros lidos · {lojas.length} favoritas
      </p>

      <h2>
        {alertadas.length > 0
          ? `${alertadas.length} ${alertadas.length === 1 ? "loja turbinada" : "lojas turbinadas"}`
          : "Nenhuma loja turbinada agora"}
      </h2>
      {alertadas.length === 0 ? (
        <p className="detalhe">
          Nenhuma favorita cruzou o próprio limiar nesta execução. A lista completa continua
          abaixo, com a pontuação de cada uma.
        </p>
      ) : (
        alertadas.map((loja) => <Loja key={`alerta-${loja.nome}`} loja={loja} />)
      )}

      {/* RN24: todas as favoritas, em promocao ou nao. E o motivo do site
          existir — responder "quanto a Renner da hoje?" sem abrir a Livelo. */}
      {[...porCategoria.entries()].map(([categoria, lojasDaCategoria]) => (
        <section key={categoria}>
          <h2>{categoria}</h2>
          {lojasDaCategoria.map((loja) => (
            <Loja key={loja.nome} loja={loja} />
          ))}
        </section>
      ))}

      <Rodape versao={execucao.versao} />
    </main>
  );
}
