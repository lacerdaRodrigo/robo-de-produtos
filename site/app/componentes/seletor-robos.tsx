import Link from "next/link";

const ROBOS = [
  {
    href: "/",
    nome: "Livelo",
    descricao: "Pontos e alertas",
  },
  {
    href: "/inter",
    nome: "Cashback Inter",
    descricao: "Lojas parceiras",
  },
  {
    href: "/inter/produtos",
    nome: "Produtos Inter",
    descricao: "Preços e histórico",
  },
];

export function SeletorDeRobos({ atual }: { atual: string }) {
  return (
    <nav className="seletor-robos" aria-label="Escolher robô">
      {ROBOS.map((robo) => (
        <Link
          key={robo.href}
          href={robo.href}
          className="seletor-robo"
          aria-current={atual === robo.href ? "page" : undefined}
        >
          <span>{robo.nome}</span>
          <small>{robo.descricao}</small>
        </Link>
      ))}
    </nav>
  );
}
