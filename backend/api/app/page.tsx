import { notFound } from "next/navigation";

/**
 * Raiz da API. Não expõe nada além de um 404 vazio: acessar o domínio no
 * navegador não devolve página nem dado. Todo conteúdo vive somente sob
 * /api/*, protegido por autenticação.
 */
export default function Raiz() {
  notFound();
}