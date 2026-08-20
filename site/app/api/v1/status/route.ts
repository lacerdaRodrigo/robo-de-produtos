import { NextResponse } from "next/server";

// API v1 — status e versão. Leitura pública; sem banco.
export async function GET() {
  return NextResponse.json(
    { api: "v1", produto: "Radar de Benefícios", saudavel: true },
    { status: 200 },
  );
}