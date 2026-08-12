import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pontuação Livelo — minhas lojas",
  description: "Pontuação atual das lojas favoritas, atualizada pelo robô 3x ao dia.",
  // PRD-V2 9.1: a pagina e publica, mas nao precisa ser indexada. O conteudo
  // interessa a uma pessoa so.
  robots: { index: false, follow: false },
};

export default function RaizDoLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>
        <div className="pagina">{children}</div>
      </body>
    </html>
  );
}
