import Link from "next/link";

const AREAS = [
  { href: "/", nome: "Livelo", descricao: "Pontos, lojas e alertas" },
  { href: "/inter", nome: "Banco Inter", descricao: "Cashback e produtos" },
];

export function SeletorDeRobos({ atual }: { atual: string }) {
  const areaAtual = atual.startsWith("/inter") ? "/inter" : atual === "/" ? "/" : "";
  return (
    <nav className="seletor-robos seletor-areas" aria-label="Escolher área">
      {AREAS.map((area) => (
        <Link key={area.href} href={area.href} className="seletor-robo" aria-current={areaAtual === area.href ? "page" : undefined}>
          <span>{area.nome}</span>
          <small>{area.descricao}</small>
        </Link>
      ))}
    </nav>
  );
}
