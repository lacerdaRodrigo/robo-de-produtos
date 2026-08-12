-- Texto livre da campanha (legalTerms), por pontuacao de execucao.
--
-- E a letra miuda que a propria Livelo mostra na tela do parceiro: "Campanha
-- valida de X a Y. Ganhe N pontos em itens selecionados...". O site passa a
-- exibir isso no Painel para responder "essa promocao serve pro que eu vou
-- comprar?" sem abrir o app da Livelo (O5, mesmo motivo de RN24).
--
-- NULL quando a Livelo nao publicou letra miuda para aquele parceiro (o caso
-- mais comum: "<p><br></p>" no payload) — o extrator ja trata isso como
-- ausencia, nao como texto vazio.

ALTER TABLE pontuacao ADD COLUMN IF NOT EXISTS descricao_campanha TEXT;
