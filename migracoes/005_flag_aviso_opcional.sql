-- Feature flag: aviso opcional no cadastro de loja (V2.3.4).
--
-- A calibragem do limiar global (V2.2, ver docs/PENDENCIAS.md) ainda esta
-- em andamento. Ate ela fechar, decidir o limiar de cada loja no momento
-- do cadastro nao faz sentido — e a armadilha de configurar 132 regras na
-- largada que o PRD-V2 §6.1 ja avisa para evitar. O campo continua
-- existindo no codigo, so comeca desligado; liga-se em /configuracoes.
--
-- Mesma tabela `preferencia` da migracao 001: e uma flag, tem a mesma
-- forma chave/valor, nao precisa de tabela propria para um booleano so.

INSERT INTO preferencia (chave, valor) VALUES
    ('aviso_opcional_no_cadastro', 'false')
ON CONFLICT (chave) DO NOTHING;
