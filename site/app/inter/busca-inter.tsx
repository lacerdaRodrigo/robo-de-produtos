"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";

type PropriedadesBuscaInter = {
  acao: string;
  valorInicial: string;
  placeholder: string;
  rotulo: string;
  parametrosFixos?: Record<string, string>;
};

/**
 * Busca progressiva do Inter: com JavaScript, atualiza depois de uma pausa
 * curta na digitacao; sem JavaScript, o mesmo formulario funciona pelo botao.
 */
export function BuscaInter({
  acao,
  valorInicial,
  placeholder,
  rotulo,
  parametrosFixos = {},
}: PropriedadesBuscaInter) {
  const roteador = useRouter();
  const [valor, definirValor] = useState(valorInicial);
  const temporizador = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(
    () => () => {
      if (temporizador.current) {
        clearTimeout(temporizador.current);
      }
    },
    [],
  );

  function atualizar(novoValor: string) {
    definirValor(novoValor);
    if (temporizador.current) {
      clearTimeout(temporizador.current);
    }
    temporizador.current = setTimeout(() => {
      const parametros = new URLSearchParams(parametrosFixos);
      const busca = novoValor.trim();
      if (busca) {
        parametros.set("q", busca);
      }
      const consulta = parametros.toString();
      roteador.replace(consulta ? `${acao}?${consulta}` : acao, { scroll: false });
    }, 350);
  }

  return (
    <form className="busca" action={acao} method="get" role="search">
      {Object.entries(parametrosFixos).map(([nome, conteudo]) => (
        <input key={nome} type="hidden" name={nome} value={conteudo} />
      ))}
      <input
        type="search"
        name="q"
        value={valor}
        onChange={(evento) => atualizar(evento.target.value)}
        placeholder={placeholder}
        aria-label={rotulo}
      />
      <button type="submit" className="secundario">
        Procurar
      </button>
    </form>
  );
}
