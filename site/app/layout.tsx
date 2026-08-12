import type { Metadata } from "next";

import { temaAtual } from "@/lib/tema";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pontuação Livelo — minhas lojas",
  description: "Pontuação atual das lojas favoritas, atualizada pelo robô 3x ao dia.",
  // PRD-V2 9.1: a pagina e publica, mas nao precisa ser indexada. O conteudo
  // interessa a uma pessoa so.
  robots: { index: false, follow: false },
};

export default async function RaizDoLayout({ children }: { children: React.ReactNode }) {
  const tema = await temaAtual();
  return (
    // "auto" nao vira atributo: sem ele, o CSS segue prefers-color-scheme
    // do sistema, que e o padrao quando ninguem escolheu nada.
    <html lang="pt-BR" data-tema={tema === "auto" ? undefined : tema}>
      <body>{children}</body>
    </html>
  );
}
