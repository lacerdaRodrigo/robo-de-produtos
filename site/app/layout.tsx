import type { Metadata } from "next";

import { temaAtual } from "@/lib/tema";
import "./globals.css";

export const metadata: Metadata = {
  title: "Radar de Benefícios — Livelo e Shopping Inter",
  description: "Pontuação Livelo e cashback do Shopping Inter nas lojas favoritas.",
  // PRD-V2 9.1: a pagina e publica, mas nao precisa ser indexada. O conteudo
  // interessa a uma pessoa so.
  robots: { index: false, follow: false },
};

export default async function RaizDoLayout({ children }: { children: React.ReactNode }) {
  const tema = await temaAtual();
  return (
    // O modo automático prioriza o tema claro para manter conforto e
    // consistência no celular. O escuro só aparece quando escolhido.
    <html lang="pt-BR" data-tema={tema === "auto" ? "claro" : tema}>
      <body>{children}</body>
    </html>
  );
}
