import type { Metadata } from "next";

import "./globals.css";
import "./design-system.css";

export const metadata: Metadata = {
  title: "Radar de Benefícios — Livelo e Shopping Inter",
  description: "Pontuação Livelo e cashback do Shopping Inter nas lojas favoritas.",
  // PRD-V2 9.1: a pagina e publica, mas nao precisa ser indexada. O conteudo
  // interessa a uma pessoa so.
  robots: { index: false, follow: false },
};

export default function RaizDoLayout({ children }: { children: React.ReactNode }) {
  return (
    // Interface deliberadamente clara: evita misturar superfícies quando
    // existir um cookie antigo de preferência escura no navegador.
    <html lang="pt-BR" data-tema="claro">
      <body>{children}</body>
    </html>
  );
}
