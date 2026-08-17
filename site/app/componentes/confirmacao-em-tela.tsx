"use client";

import { useId, useRef, type ReactNode } from "react";

type PropriedadesConfirmacaoEmTela = {
  titulo: string;
  mensagem: string;
  rotuloAbrir: string;
  children: ReactNode;
};

export function ConfirmacaoEmTela({
  titulo,
  mensagem,
  rotuloAbrir,
  children,
}: PropriedadesConfirmacaoEmTela) {
  const dialogo = useRef<HTMLDialogElement>(null);
  const tituloId = useId();
  const mensagemId = useId();

  function abrir() {
    dialogo.current?.showModal();
  }

  function fechar() {
    dialogo.current?.close();
  }

  return (
    <>
      <button className="botao perigoso" type="button" onClick={abrir}>
        {rotuloAbrir}
      </button>
      <dialog
        ref={dialogo}
        className="dialogo-confirmacao"
        aria-labelledby={tituloId}
        aria-describedby={mensagemId}
        onClick={(evento) => {
          if (evento.target === evento.currentTarget) {
            fechar();
          }
        }}
      >
        <div className="dialogo-confirmacao-conteudo">
          <span className="dialogo-confirmacao-icone" aria-hidden="true">
            !
          </span>
          <div>
            <p className="dialogo-confirmacao-rotulo">Confirme a ação</p>
            <h2 id={tituloId}>{titulo}</h2>
            <p id={mensagemId} className="dialogo-confirmacao-mensagem">
              {mensagem}
            </p>
          </div>
          <div className="dialogo-confirmacao-acoes">
            <button className="botao secundario" type="button" onClick={fechar}>
              Cancelar
            </button>
            {children}
          </div>
        </div>
      </dialog>
    </>
  );
}
