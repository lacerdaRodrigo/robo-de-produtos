"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

export function MolduraNavegacao({
  atual,
  children,
}: {
  atual: string;
  children: React.ReactNode;
}) {
  const [aberto, setAberto] = useState(false);

  useEffect(() => {
    setAberto(false);
  }, [atual]);

  useEffect(() => {
    document.body.style.overflow = aberto ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [aberto]);

  return (
    <div className={aberto ? "moldura-navegacao menu-aberto" : "moldura-navegacao"}>
      <header className="cabecalho-movel">
        <button
          type="button"
          className="cabecalho-icone"
          onClick={() => setAberto(true)}
          aria-label="Abrir menu"
          aria-expanded={aberto}
        >
          <IconeMenu />
        </button>
        <Link href="/" className="cabecalho-marca" aria-label="Radar de Benefícios — início">
          <img src="/logo.png" alt="" width={30} height={30} />
          <span>Radar de Benefícios</span>
        </Link>
        <a
          className="cabecalho-icone"
          href={`${atual}#busca-principal`}
          aria-label="Ir para a busca"
        >
          <IconeBusca />
        </a>
      </header>

      <button
        type="button"
        className="menu-fundo"
        onClick={() => setAberto(false)}
        aria-label="Fechar menu"
        tabIndex={aberto ? 0 : -1}
      />
      <button
        type="button"
        className="menu-fechar"
        onClick={() => setAberto(false)}
        aria-label="Fechar menu"
        tabIndex={aberto ? 0 : -1}
      >
        <IconeFechar />
      </button>
      {children}
    </div>
  );
}

function IconeMenu() {
  return (
    <svg width="25" height="25" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 7h16M4 12h16M4 17h16" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

function IconeBusca() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="11" cy="11" r="6.5" stroke="currentColor" strokeWidth="2" />
      <path d="m16 16 4 4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}

function IconeFechar() {
  return (
    <svg width="25" height="25" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="m5 5 14 14M19 5 5 19" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
    </svg>
  );
}
