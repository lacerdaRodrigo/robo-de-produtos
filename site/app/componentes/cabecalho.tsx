import Image from "next/image";
import Link from "next/link";
import { esperaAteProximoDisparo } from "@/lib/banco";
import { esperaAteProximoDisparoInter } from "@/lib/banco-inter";
import { telaDeAlertasEscondida } from "@/lib/flags";
import { temTokenDeDisparo, temTokenDeDisparoInter } from "@/lib/github";
import { temSessao } from "@/lib/sessao";
import { acaoSair } from "../acoes";
import { acaoAtualizarInter } from "../inter/lojas/acoes";
import { acaoAtualizarAgora } from "../lojas/acoes";
import { MolduraNavegacao } from "./moldura-navegacao";

type ItemDoMenu={href:string;nome:string;descricao:string;icone:()=>React.ReactNode};
function ItemMenu({item,atual}:{item:ItemDoMenu;atual:string}){return <Link href={item.href} className="bl-item bl-subitem" aria-current={item.href===atual?"page":undefined}><item.icone/><span className="bl-item-conteudo"><strong>{item.nome}</strong><small>{item.descricao}</small></span></Link>}

export async function Cabecalho({atual}:{atual:string}){
 const[logado,alertasEscondidos]=await Promise.all([temSessao(),telaDeAlertasEscondida()]);
 const livelo:ItemDoMenu[]=[
  {href:"/",nome:"Consultar pontos",descricao:"Veja as melhores ofertas",icone:IconePainel},
  ...(logado?[{href:"/lojas",nome:"Escolher minhas lojas",descricao:"Cadastre o que quer acompanhar",icone:IconeLojas},...(!alertasEscondidos?[{href:"/avisos",nome:"Configurar alertas",descricao:"Defina quando ser avisado",icone:IconeAlertas}]:[])]:[])
 ];
 const inter:ItemDoMenu[]=[
  {href:"/inter",nome:"Consultar cashback",descricao:"Compare suas lojas favoritas",icone:IconeLojas},
  ...(logado?[{href:"/inter/lojas",nome:"Escolher lojas de cashback",descricao:"Monte sua lista de interesse",icone:IconeLojas}]:[]),
  {href:"/inter/produtos",nome:"Consultar produtos",descricao:"Busque preços e histórico",icone:IconeProdutos},
  ...(logado?[{href:"/inter/produtos/lojas",nome:"Escolher lojas de produtos",descricao:"Defina onde o robô pesquisa",icone:IconeProdutos}]:[])
 ];
 const podeDisparar=logado&&temTokenDeDisparo(),podeDispararInter=logado&&temTokenDeDisparoInter();
 const falta=logado?await esperaAteProximoDisparo().catch(()=>0):0,faltaInter=logado?await esperaAteProximoDisparoInter().catch(()=>0):0;
 const liveloAtivo=atual==="/"||atual.startsWith("/lojas")||atual.startsWith("/avisos"),interAtivo=atual.startsWith("/inter");
 return <MolduraNavegacao key={atual} atual={atual}><aside className="barra-lateral">
  <Link href="/" className="bl-marca"><span className="bl-marca-icone"><Image src="/logo.png" alt="" width={22} height={22}/></span><span className="bl-marca-nome">Radar de Benefícios</span></Link>
  <nav className="bl-nav bl-nav-simples" aria-label="Benefícios">
   <details className="bl-grupo" open={liveloAtivo}><summary><span className="bl-grupo-icone"><IconePainel/></span><span><strong>Livelo</strong><small>Pontos e alertas</small></span><span className="bl-grupo-seta">⌄</span></summary><div className="bl-grupo-itens">
    {livelo.map(item=><ItemMenu key={item.href} item={item} atual={atual}/>)}
    {logado&&<form action={acaoAtualizarAgora} className="bl-form"><button type="submit" className="bl-item bl-subitem bl-executar" disabled={!podeDisparar||falta>0}><IconeExecutar/><span className="bl-item-conteudo"><strong>{falta>0?`Disponível em ${falta}s`:"Atualizar dados agora"}</strong><small>Executa uma nova consulta Livelo</small></span></button></form>}
   </div></details>
   <details className="bl-grupo" open={interAtivo}><summary><span className="bl-grupo-icone"><IconeLojas/></span><span><strong>Banco Inter</strong><small>Cashback e produtos</small></span><span className="bl-grupo-seta">⌄</span></summary><div className="bl-grupo-itens">
    {inter.map(item=><ItemMenu key={item.href} item={item} atual={atual}/>)}
    {logado&&<form action={acaoAtualizarInter} className="bl-form"><button type="submit" className="bl-item bl-subitem bl-executar" disabled={!podeDispararInter||faltaInter>0}><IconeExecutar/><span className="bl-item-conteudo"><strong>{faltaInter>0?`Disponível em ${faltaInter}s`:"Atualizar cashback agora"}</strong><small>Executa uma nova consulta Inter</small></span></button></form>}
   </div></details>
  </nav>
  <div className="bl-rodape">
   <Link href="/ajuda" className="bl-item bl-acao"><IconeAjuda/><span className="bl-item-texto">Ajuda</span></Link><Link href="/versoes" className="bl-item bl-acao"><IconePainel/><span className="bl-item-texto">Versões</span></Link>
   {logado&&<Link href="/configuracoes" className="bl-item bl-acao"><IconeDeEngrenagem/><span className="bl-item-texto">Configurações</span></Link>}
   {logado?<form action={acaoSair} className="bl-form"><button type="submit" className="bl-item bl-acao"><IconeSair/><span className="bl-item-texto">Sair</span></button></form>:<Link href={`/entrar?voltar=${encodeURIComponent(atual)}`} className="bl-item bl-acao"><SetaDeEntrada/><span className="bl-item-texto">Entrar</span></Link>}
  </div>
 </aside></MolduraNavegacao>;
}

/** RN25: icone e SVG no proprio HTML, nunca arquivo nem CDN de terceiro. */

function IconePainel() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <rect x="3" y="3" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" stroke="currentColor" strokeWidth="2" />
    </svg>
  );
}

function IconeLojas() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M4 9V4a1 1 0 0 1 1-1h14a1 1 0 0 1 1 1v5M4 9a2 2 0 0 0 2 2h.5A2.5 2.5 0 0 0 9 8.5 2.5 2.5 0 0 0 11.5 11h1A2.5 2.5 0 0 0 15 8.5 2.5 2.5 0 0 0 17.5 11H18a2 2 0 0 0 2-2M4 9v9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function IconeProdutos() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M4 7.5 12 3l8 4.5v9L12 21l-8-4.5v-9Z" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
      <path d="m4 7.5 8 4.5 8-4.5M12 12v9" stroke="currentColor" strokeWidth="2" strokeLinejoin="round" />
    </svg>
  );
}

function IconeAlertas() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M13.73 21a2 2 0 0 1-3.46 0"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
      />
    </svg>
  );
}

function IconeAjuda() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" />
      <path
        d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.29c-.83.38-1 .77-1 1.71"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <circle cx="12" cy="17" r="1" fill="currentColor" />
    </svg>
  );
}

/** Disparo manual do robô (RNF02) — triângulo de "play", mesmo peso visual
 *  dos demais ícones do menu. */
function IconeExecutar() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path d="M6 4.5v15l13-7.5-13-7.5Z" fill="currentColor" />
    </svg>
  );
}

function IconeSair() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

/** RN25: icone e SVG no proprio HTML, nunca arquivo de terceiro. */
function SetaDeEntrada() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <path
        d="M10 17l5-5-5-5M15 12H3M13 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-6"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

/** Engrenagem: leva para /configuracoes, onde ficam as flags de
 *  funcionalidade (V2.3.4) — coisas que ligam/desligam pedaço da
 *  interface, distintas das regras de alerta que moram em /avisos. */
function IconeDeEngrenagem() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
      <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="2" />
      <path
        d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
