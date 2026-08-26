import { NextResponse } from "next/server";

// Health-check público. Mínimo para revelar o mínimo: nenhum nome de produto
// nem dado. O domínio aberto no navegador não devolve nada além disto e do 404
// da raiz /.
export async function GET() {
  return NextResponse.json({ saudavel: true }, { status: 200 });
}