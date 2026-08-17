"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";

type PropriedadesBuscaProgressiva = {
  acao: string;
  valorInicial: string;
  placeholder: string;
  rotulo: string;
  parametrosFixos?: Record<string, string>;
  classeFormulario?: "busca" | "busca-produtos";
  idDoCampo?: string;
  textoDoBotao?: string;
  tituloDoCampo?: string;
};

/**
 * Busca progressiva com melhoria gradual: com JavaScript, atualiza os
 * resultados depois de uma pausa curta; sem JavaScript, o formulario e o
 * botao continuam funcionando normalmente.
 */
export function BuscaProgressiva({
  acao,
  valorInicial,
  placeholder,
  rotulo,
  parametrosFixos = {},
  classeFormulario = "busca",
  idDoCampo,
  textoDoBotao = "Procurar",
  tituloDoCampo,
}: PropriedadesBuscaProgressiva) {
  const roteador = useRouter();
  const [valor, definirValor] = useState(valorInicial);
  const temporizador = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    definirValor(valorInicial);
  }, [valorInicial]);

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
      } else {
        parametros.delete("q");
      }
      const consulta = parametros.toString();
      roteador.replace(consulta ? `${acao}?${consulta}` : acao, { scroll: false });
    }, 350);
  }

  const campo = (
    <input
      id={idDoCampo}
      type="search"
      name="q"
      value={valor}
      onChange={(evento) => atualizar(evento.target.value)}
      placeholder={placeholder}
      aria-label={rotulo}
      autoComplete="off"
    />
  );

  return (
    <form className={classeFormulario} action={acao} method="get" role="search">
      {Object.entries(parametrosFixos).map(([nome, conteudo]) => (
        <input key={nome} type="hidden" name={nome} value={conteudo} />
      ))}
      {tituloDoCampo && idDoCampo ? (
        <>
          <label htmlFor={idDoCampo}>{tituloDoCampo}</label>
          <div>
            {campo}
            <button type="submit" className="botao">
              {textoDoBotao}
            </button>
          </div>
        </>
      ) : (
        <>
          {campo}
          <button type="submit" className="secundario">
            {textoDoBotao}
          </button>
        </>
      )}
    </form>
  );
}
