# Catálogo do Inter — inventário e agrupamento de navegação proposto

**Estado:** estudo de produto. Não implementado no Flutter, API, banco ou robô.

**Fonte e data:** leitura `READ ONLY` do catálogo de produtos diretos do Inter em
04/09/2026. A fotografia considerou os produtos ativos das **seis** lojas Inter
que estavam ativas e selecionadas naquele instante.

> As seis lojas, as contagens abaixo e as 513 entradas observadas **não são uma
> configuração nem um limite do produto**. São evidência pontual da leitura. O
> catálogo deve funcionar da mesma forma com uma, nove, dez, doze, vinte ou
> qualquer outra quantidade de lojas Inter elegíveis.

## Resultado da leitura

| Medida | Valor |
|---|---:|
| Produtos ativos consultáveis | 9.436 |
| Categorias externas distintas, incluindo o fallback `Sem categoria` | 513 |
| Categorias com 10 ou mais produtos | 204 |
| Categorias com somente um produto | 88 |
| Categorias com menos de cinco produtos | 226 |
| Categorias em uma única loja | 295 |
| Categorias necessárias para cobrir 80% dos produtos | 138 |

`Sem categoria` representa 18 produtos cuja categoria de origem era nula, vazia
ou composta apenas por espaços; não é uma categoria gravada nem inventada para o
produto.

Não basta exibir as mais frequentes: as 40 primeiras cobrem apenas 48,88% dos
produtos. Também não é seguro usar o texto bruto como árvore: há atributos
(`2 Portas`, `4 Bocas`, `Android`, `Horizontal`, `Vertical`), departamentos
genéricos (`Mercado`, `Moda`, `Móveis`, `Diversos`) e inclusive rótulos cujo
produto de exemplo pertence a outro tipo (`Celulares` possui fones no catálogo
atual).

## Decisão de experiência proposta

A melhor evolução não é uma taxonomia rígida nem uma lista com 513 chips. É uma
**navegação por intenção que termina em busca contextual**:

```text
Produtos
  └─ Eletrônicos
      └─ Celulares e smartphones
          └─ Buscar neste recorte: "Samsung Galaxy"
              └─ consulta paginada ao banco local
```

Em vez de despejar 100 TVs, celulares ou geladeiras logo ao abrir uma categoria,
a pessoa escolhe o assunto e descreve o modelo, marca ou característica que quer.
O resultado continua sendo uma consulta ao banco/API já coletado pelo robô; nunca
consulta o Inter enquanto a pessoa digita.

Também deve existir **“Buscar em todo o catálogo”** como rota de escape. Ela é
necessária para itens mal classificados pela origem, novidades e quem já sabe
exatamente o que procura.

### O que é e o que não é agrupamento

- O grupo e o subgrupo existem somente na navegação.
- `categoria` externa continua preservada exatamente como veio do Inter em cada
  produto; não se renomeia, move ou regrava produto algum.
- Ao abrir um subgrupo, a API filtra por um conjunto declarado de categorias
  externas daquele recorte e pela busca textual informada pela pessoa.
- Não haverá aprovação humana item a item nem classificação por IA do produto em
  tempo de consulta.
- Categorias ambíguas não entram à força em um subgrupo específico: ficam em
  **Outros daquele departamento** ou são alcançadas pela busca global até haver
  evidência suficiente para um recorte seguro.

### Catálogo e lojas são dinâmicos

O escopo consultável é calculado a cada consulta a partir das lojas Inter
**ativas e selecionadas**. Não pode existir lista, condição, migração ou tela
que dependa de haver seis lojas, de seus IDs atuais ou de uma quantidade fixa de
produtos.

- Ao entrar uma loja elegível, seus produtos e categorias passam a compor a
  busca e as contagens sem mudança no Flutter ou publicação de uma nova versão.
- Quando uma loja deixa de estar ativa ou selecionada, ela deixa de participar do
  resultado e das contagens pelo mesmo critério dinâmico já usado no catálogo.
- A mesma categoria externa em duas ou mais lojas é um único valor de
  navegação. O resultado reúne os produtos das lojas que estiverem no escopo;
  filtro de loja continua podendo reduzi-lo depois.
- Uma categoria nova não pode ser perdida por não constar do mapeamento. Ela
  fica disponível em **Outros / novas categorias** e pela busca global até que
  amostras reais justifiquem seu mapeamento editorial.
- Se uma categoria ficar sem produtos ativos em todas as lojas elegíveis depois
  de uma coleta, ela sai apenas da disponibilidade do **catálogo atual**, para
  não abrir um recorte vazio. Seu mapeamento permanece versionado; se produto
  compatível voltar em coleta futura, a categoria e o recorte reaparecem sem
  recriação manual.
- O mapeamento não referencia uma quantidade de lojas nem IDs de lojas. Sua
  chave mínima é a origem `Inter` mais o texto exato da categoria externa. Uma
  exceção por loja só poderá existir se for documentada, justificada por
  evidência e não substituir o fallback global.

## Estrutura inicial sugerida

| Departamento | Subgrupos de entrada | Exemplos de categorias externas que dão base ao recorte |
|---|---|---|
| Eletrônicos | Celulares, TV e imagem, Computadores, Áudio, Acessórios | `Android`, `Smartphones`, `Smart TV`, `TVs`, `Notebooks`, `Tablet`, `Monitores`, `Caixas Acústicas` |
| Casa e cozinha | Cozinhas e móveis, Eletroportáteis, Linha branca, Mesa e utilidades | `Cozinha Modulada`, `Cozinhas`, `Fritadeiras`, `Liquidificadores`, `Geladeira / Refrigerador`, `Panelas` |
| Móveis e decoração | Sala, Quarto, Escritório, Organização, Decoração | `Sofás`, `Guarda-roupas e Roupeiros`, `Racks e Painéis`, `Escrivaninhas`, `Organização` |
| Beleza e cuidados pessoais | Maquiagem, Cabelos, Pele, Perfumaria, Barbear | `Base`, `Batom`, `Cabelos`, `Cuidados Faciais`, `Perfumes`, `Aparelhos de Depilação` |
| Saúde e bem-estar | Cuidados de saúde, Farmácia, Mobilidade, Fitness | `Saúde`, `Medicamentos`, `Primeiros Socorros`, `Ortopedia`, `Esteiras Ergométricas` |
| Mercado | Alimentos, Bebidas, Doces e snacks, Suplementos | `Biscoito`, `Chocolate`, `Balas e Drops`, `Bebidas`, `Suplementos e Vitaminas` |
| Bebês, crianças e brinquedos | Bebê, Brinquedos, Infantil | `Mamadeiras`, `Fralda`, `Bonecas`, `Brinquedos`, `Berços e Cercados Portáteis` |
| Pet | Alimentação, Higiene, Saúde, Acessórios | `Ração`, `Antipulgas`, `Areia Higiênica`, `Farmácia pet` |
| Esporte e lazer | Bicicletas, Fitness, Praia e camping, Jogos | `Bicicletas`, `Patinetes`, `Pilates e Yoga`, `Piscinas`, `Jogos` |
| Ferramentas, construção e jardim | Ferramentas, Elétrica, Banheiro, Jardim | `Furadeiras`, `Parafusadeiras`, `Lâmpadas`, `Torneiras`, `Jardinagem` |
| Auto | Pneus, Limpeza e acessórios automotivos | `Pneus`, `Pneus, Rodas e Calotas`, `Limpeza de Automóveis` |
| Moda | Roupas, Calçados e acessórios | `Blusas e Camisetas`, `Casacos e Jaquetas`, `Chinelos`, `Mochilas` |

Os nomes de departamento não substituem nem aparecem como nova categoria do
produto. São portas de entrada. O subgrupo apresenta campo de busca e, se fizer
sentido na tela, poucos atalhos de famílias — nunca uma lista completa de
produtos sem intenção de busca.

## Inventário integral das categorias externas observadas

Os números entre parênteses são produtos ativos no instante da leitura. A lista
é deliberadamente literal: nomes duplicados, grafia inconsistente e categorias
genéricas foram preservados para não esconder um problema da fonte.

### 0–A

`2 Portas` (90), `4 Bocas` (8), `5 Bocas` (9), `Absorvente` (135), `Absorventes` (23), `Academias e Estações de Ginástica` (2), `Acessórios` (20), `Acessórios de Jardinagem` (4), `Acessórios de Limpeza` (21), `Acessórios de Moda` (2), `Acessórios e Equipamentos` (1), `Acessórios e Kits para Limpeza` (2), `Acessórios e Periféricos` (12), `Acessórios e Utensílios` (3), `Acessórios externos` (1), `Acessórios internos` (1), `Acessórios para Barbear` (2), `Acessórios para Celulares` (6), `Acessórios para aplicação` (1), `Acima de 10 kg` (22), `Adega de Vinhos` (4), `Alarmes, Sensores e Fechaduras` (2), `Alimentação` (42), `Almofada` (1), `Almofadas` (1), `Amamentação` (8), `Ambiente Completo Dormitório` (2), `Analgésico` (1), `Android` (272), `Antenas e Receptores` (9), `Anti Rugas` (1), `Anti-Sépticos e Desinfetantes` (2), `Anti-idade` (8), `Antiacne` (12), `Antigripal` (1), `Antipulgas` (11), `Aparadores` (2), `Aparadores de Grama` (1), `Aparadores de Pelos` (26), `Aparelhos de Depilação` (132), `Aparelhos de Jantar` (23), `Apontador` (2), `Aquecedores` (10), `Ar-Condicionado` (2), `Areia Higiênica` (5), `Armazenagem e Organização` (8), `Armários Multiuso` (6), `Aro 12` (4), `Aro 16` (6), `Aro 20` (4), `Aro 24` (5), `Artes e Atividades` (1), `Artigos para Festas` (36), `Aspirador Nasal e Dosador de Medicamento` (3), `Aspirador de Pó` (74), `Aspirador Água e Pó` (32), `Assadura` (21), `Assentos Sanitários` (3), `Ativador de cachos` (14), `Até 30 peças` (10), `Até 75 peças` (10), `Autobronzeadores` (1), `Automotivo` (5), `Autoramas e Pistas` (2), `Avulsas` (1), `Açúcar e Adoçante` (42), `BB Cream` (9).

### B

`Babadores` (2), `Baixelas e Travessas` (3), `Balanças` (8), `Balas e Drops` (197), `Balcões e Fruteiras` (127), `Baleiros e Bombonieres` (2), `Balões e Acessórios` (3), `Bancos e Banquetas` (4), `Bandejas` (1), `Banheiro e Acessórios` (4), `Barba e Depilação` (1), `Barbeadores Elétricos` (10), `Barzinho` (2), `Base` (91), `Base Cama Box Casal` (32), `Base Cama Box King` (17), `Base Cama Box Queen` (18), `Base Cama Box Solteiro` (27), `Base para Unhas` (6), `Batedeira` (8), `Batedeiras e Acessórios` (3), `Batom` (96), `Bebedouro` (1), `Bebedouros e Purificadores` (4), `Bebidas` (11), `Bebês e Infantil` (3), `Beleza e perfumaria` (18), `Beliche e Treliche` (4), `Bengala` (4), `Berços e Cercados Portáteis` (10), `Bicicletas` (29), `Bicicletas Ergométricas` (11), `Bicicletas Infantojuvenis` (6), `Biscoito` (258), `Biscoitos e Petiscos para Gato` (2), `Biscoitos, Petiscos e Ossos` (2), `Biscoitos, Petiscos e Ossos para Cachorro` (25), `Blusas e Camisetas` (8), `Blush` (32), `Boias e Infláveis` (2), `Bolos` (2), `Bolsa térmica` (6), `Bombas, Filtros e Pressurizadores` (3), `Bomboniere` (10), `Bonecas` (33), `Bonecos` (11), `Borrachas` (1), `Bowls` (1), `Brincadeiras` (4), `Brinquedos` (62), `Brinquedos Educativos` (8), `Brinquedos de Praia` (1), `Brinquedos para Cachorros` (2), `Bronzeadores` (9), `Buffets` (6).

### C

`Cabeceiras` (54), `Cabelos` (37), `Cabides` (6), `Cabo para celular` (10), `Cadeira de Jantar` (21), `Cadeira de roda e Muleta` (15), `Cadeiras` (6), `Cadeiras de Escritório` (6), `Cafeteiras` (7), `Cafeteiras Dolce Gusto` (12), `Cafeteiras Elétricas` (54), `Cafeteiras Expresso` (18), `Café e cappuccino` (28), `Caixas Acústicas` (94), `Cama Box  King` (8), `Cama Box  Queen` (20), `Cama Box  Solteiro` (8), `Cama Box Casal` (34), `Camas e Colchões` (18), `Camisas` (1), `Canecas` (16), `Canetas` (3), `Capacho` (2), `Capas` (2), `Capas para sofá` (6), `Carregador de celular` (5), `Carregadores e Baterias` (9), `Carrinhos e Miniaturas` (19), `Casa e Construção` (13), `Casacos e Jaquetas` (1), `Caçarolas e Caldeirões` (3), `Celulares` (4), `Cera e pomada` (4), `Ceras, Silicone e Multiusos` (1), `Cereais` (2), `Cervejeiras` (1), `Cestos e Lixeiras` (13), `Chaleiras Elétricas` (31), `Chaves` (8), `Chiclete` (54), `Chinelos` (4), `Chocalhos` (2), `Chocolate` (140), `Churrasqueiras` (4), `Churrasqueiras Elétricas` (15), `Churrasqueiras e Acessórios` (9), `Chás` (27), `Cicatrizantes` (10), `Cirúrgico` (11), `Climatizadores` (4), `Cobertor e Manta` (19), `Colchão Infantil` (6), `Colchão King` (14), `Colchão Queen` (28), `Colchão de Casal` (44), `Colchão de Solteiro` (40), `Colchões Infláveis e Colchonetes` (6), `Coloração` (1), `Condicionadores` (2), `Conjunto de Xícaras` (4), `Conjuntos de Mesas e Cadeiras de Jantar` (83), `Conjuntos de Panela` (63), `Cooktop` (2), `Coolers e bolsas térmicas` (13), `Copos` (39), `Corpo e Banho` (84), `Corretivo` (1), `Cortadores, Moedores e Raladores` (1), `Cortinas` (8), `Costura` (14), `Cozinha` (35), `Cozinha Compacta` (120), `Cozinha Modulada` (215), `Cozinhas` (121), `Creme Dental` (2), `Cubos e Prateleiras` (9), `Cuidados Específicos` (1), `Cuidados Faciais` (27), `Cuidados Pós-Barba` (8), `Cuidados com a Barba` (2), `Cuidados com a área dos Olhos` (1), `Cuidados para a Depilação` (2), `Cuidados para o Barbear` (1), `Cômoda Infantil` (10), `Cômodas` (30).

### D–F

`Delineador` (7), `Demaquilante` (4), `Depuradores de Ar` (4), `Descolorante` (15), `Desodorante` (32), `Diabetes` (5), `Digestivo` (4), `Diversos` (4), `Doces` (5), `Duchas e Chuveiros` (5), `E-reader` (2), `Eletrodomésticos` (1), `Eletroportáteis` (14), `Elétrica` (4), `Energético` (5), `Enfeites e Decoração` (50), `Enlatados e Conservas` (3), `Entre 7kg e 9kg` (1), `Enxaguante Bucal` (13), `Escolar / Escritório` (21), `Escrivaninhas` (28), `Esmaltes` (60), `Esmerilhadeiras e Moto-Esmeris` (3), `Esponja de Banho` (2), `Esporte e Lazer` (2), `Espremedores de Frutas` (19), `Estantes` (6), `Estantes e Armários` (1), `Esteiras Ergométricas` (16), `Expositores e Ilhas` (1), `Facas` (2), `Fantasias e Acessórios` (76), `Faqueiros` (2), `Farinhas e Grãos` (9), `Farmácia pet` (5), `Feminino` (53), `Ferramentas Elétricas` (9), `Ferramentas Manuais` (12), `Ferramentas de Medição` (1), `Ferro a Seco` (4), `Ferro a Vapor` (58), `Ferro de Passar` (22), `Finalizador` (11), `Fitness Acessórios` (3), `Fogões` (5), `Fones de Ouvido` (38), `Formas e Assadeiras` (23), `Forno Elétrico` (14), `Fornos` (6), `Fralda` (2), `Freezer` (1), `Freezer Horizontal` (5), `Frigideiras` (22), `Frigobar` (14), `Fritadeiras` (133), `Fronha` (6), `Fruteiras` (1), `Furadeiras` (11).

### G–L

`Galheteiros` (1), `Gaveteiros` (4), `Geladeira / Refrigerador` (4), `Gloss` (17), `Grill` (17), `Grill e Sanduicheiras` (20), `Guarda-Chuvas e Sombrinhas` (1), `Guarda-roupa e Roupeiro Infantil` (10), `Guarda-roupas Modulados` (55), `Guarda-roupas e Roupeiros` (85), `Guarda-sol e Ombrelone` (2), `Headset` (2), `Hidratantes` (3), `Hidratantes Corpo` (45), `Hidratantes Faciais` (18), `Hidratantes Labiais` (4), `Hidratação` (12), `Higiene e Saúde` (24), `Horizontal` (5), `Hospitais, Clínicas e Laboratórios` (5), `Impressoras` (8), `Injetores` (22), `Inseticida` (1), `Instrumentos Musicais Infantis` (3), `Janela` (3), `Jardinagem` (1), `Jato de Tinta` (2), `Jogo Americano` (5), `Jogo de Cama` (1), `Jogos` (9), `Jogos e Kits` (13), `Lançadores` (7), `Laser Colorida` (1), `Lava e Seca` (20), `Lava-Louças` (4), `Lavadoras de Pressão` (32), `Leite` (3), `Leiteiras` (1), `Lençol` (2), `Lenços Umedecidos` (1), `Limpadores Faciais` (46), `Limpeza da Casa` (16), `Limpeza de Automóveis` (6), `Limpeza de Pele` (38), `Liquidificadores` (85), `Liquidificadores e Acessórios` (60), `Livros` (1), `Lixadeiras e Serras` (27), `Lubrificantes e Preservativos` (1), `Luminárias` (1), `Lápis` (1), `Lâmpadas` (8).

### M–P

`Mamadeiras` (35), `Manta Siliconizada` (11), `Manteigueiras` (2), `Maquiagem` (28), `Martelos e Marteletes Elétricos` (1), `Martelos e Serrotes` (1), `Masculino` (25), `Massageadores` (1), `Massas` (1), `Massas para Modelar` (9), `Mecânica e performance` (1), `Medicamentos` (10), `Medidores` (1), `Medidores de Pressão` (9), `Mercado` (331), `Mesa` (4), `Mesa de Cabeceira` (11), `Mesa de Escritório` (6), `Mesa de Jantar` (11), `Mesas` (4), `Mesas Laterais` (8), `Mesas de Centro` (12), `Mesas para Áreas Externas` (2), `Micro e Mini System` (2), `Micro-ondas` (58), `Miniveículos` (10), `Mixer` (56), `Mochilas` (1), `Moda` (16), `Modeladores e Escovas Rotativas` (46), `Monitores` (66), `Mordedores` (1), `Mouses` (3), `Máquina de Gelo` (4), `Máquina de Lavar` (1), `Máquinas de Cortar Cabelo` (25), `Máquinas de Crepe` (2), `Máquinas de Cupcake e Bolos` (2), `Máquinas de Waffle` (2), `Máscaras Faciais` (1), `Móveis` (1), `Natação e Hidroginástica` (1), `Nebulizadores e Inaladores` (4), `Nespresso` (9), `Notebooks` (40), `Notebooks gamer` (14), `Nutricosméticos` (2), `Nécessaire` (1), `Objetos Decorativos` (1), `Olhos` (3), `Omeleteira` (1), `Organização` (69), `Ortopedia` (7), `Osteoporose` (1), `Outros Acessórios para celular` (4), `Outros Consoles` (1), `Palmilhas e calcanheiras` (2), `Panelas` (7), `Panelas Elétricas` (71), `Panelas de Pressão` (20), `Panificadora (Máquina de Pão)` (2), `Papel / Blocos` (2), `Papelaria` (11), `Parafusadeiras` (16), `Patinetes` (17), `Patins` (2), `Pelúcias` (4), `Perfume para o Corpo` (2), `Perfumes` (180), `Perfumes para Ambiente` (2), `Pet Shop` (4), `Petisqueiras` (2), `Peças Avulsas` (13), `Pias e Cubas` (1), `Pias, Cubas e Lavatórios` (1), `Pilates e Yoga` (10), `Pilhas e Baterias` (19), `Pilhas, Baterias e Carregadores` (4), `Pipoqueiras` (4), `Piscinas` (7), `Piso 4 Bocas` (28), `Piso 5 Bocas` (18), `Planetária` (18), `Pneus` (91), `Pneus, Rodas e Calotas` (90), `Poltronas` (12), `Porta Condimentos` (1), `Porta-retratos` (3), `Potes e Tigelas` (25), `Pranchas (Chapinhas)` (37), `Pratos e Taças de Sobremesa` (2), `Primeiros Socorros` (39), `Processador de Alimentos` (43), `Produtos de Limpeza` (3), `Produtos para Lente de Contato` (2), `Progressiva e Alisamento` (7), `Protetor / Capa para Colchão` (1), `Protetor Solar` (26), `Protetor Solar Labial` (6), `Proteção Elétrica` (4), `Puffs` (6), `Purificador de Água` (1), `Pães e Torradas` (2), `Pés` (1), `Pós-Sol` (1).

### Q–S

`Quadros e Molduras` (2), `Quarto Infantil e Bebê` (32), `Quebra-cabeça` (6), `Racks e Painéis` (80), `Ralos e Grelhas` (2), `Ração` (2), `Ração para Pássaros` (1), `Rechaud e Fondue` (1), `Refil de Tinta` (4), `Refil e Filtro de Água` (1), `Repelentes` (3), `Rosto` (4), `Roteadores` (1), `Sabonete` (23), `Saboneteiras` (2), `Sala de Estar` (8), `Saladeiras` (2), `Salgadinhos e snacks` (122), `Sanduicheira Grill` (12), `Sanduicheiras` (17), `Sapateiras` (8), `Saúde` (18), `Secadora de Parede` (2), `Secadoras de Roupas` (2), `Secadores de Cabelo` (113), `Shampoo` (5), `Side by Side` (4), `Skate` (1), `Smart TV` (124), `Smartband` (3), `Smartphones` (37), `Smartwatch` (26), `Smartwatch e smartband` (3), `Softwares e Programas` (2), `Sofás` (103), `Sofás-camas` (8), `Som Portátil` (30), `Sombra` (3), `Soundbar` (14), `Split` (28), `Spray` (1), `Sucos e Refrescos` (4), `Suplementação` (1), `Suplementos e Vitaminas` (103), `Suportes para Tv` (16).

### T–Ó

`TVs` (46), `Tablet` (43), `Tabuleiro` (1), `Talheres Avulsos` (10), `Tanquinho` (10), `Tapete` (3), `Taças` (30), `Teclados` (3), `Temperos, Pastas e Molhos` (3), `Tendas e Gazebos` (1), `Termômetros` (3), `Toalhas` (8), `Toalhas de Banho` (18), `Toalhas de Rosto` (12), `Tocas e Barracas Infantis` (1), `Tonalizante` (1), `Torneiras` (7), `Torradeiras` (15), `Tratamento Acne` (5), `Tratamento e Máscaras` (25), `Travessas` (2), `Travesseiro` (19), `Troca do Bebê` (2), `Tábua de Passar` (4), `Tônicos Faciais` (1), `Umidificador e Desumidificador` (15), `Unhas` (5), `Utilidades Domésticas` (24), `Vaporizador` (17), `Varal` (8), `Vasos e Cachepots` (1), `Velas e Castiçais` (1), `Ventilador de Coluna` (26), `Ventilador de Mesa` (50), `Ventilador de Parede` (6), `Ventilador de Teto` (1), `Vertical` (1), `Vitamina` (15), `Água Termal` (2), `Água de coco` (6), `Água mineral` (33), `Áudio` (3), `Áudio Aparelhos` (10), `Óleo` (2), `Órtese` (9).

**Fallback funcional:** `Sem categoria` (18). São os produtos cuja categoria
externa é ausente; o rótulo existe somente na consulta e na interface.

## Regras de montagem antes de codificar

1. Criar um arquivo versionado de mapeamento de **categoria externa →
   departamento/subgrupo de navegação**, e nunca atualizar a coluna de origem
   do produto para isso.
2. Só colocar uma categoria em um subgrupo específico quando amostras reais
   confirmarem o tipo. Exemplo: `Android` e `Smartphones` sustentam “Celulares”;
   `Celulares` não deve ser incluída automaticamente nesse recorte porque a
   amostra atual é fone de ouvido.
3. Atributos como `2 Portas`, `4 Bocas`, `Acima de 10 kg`, `Horizontal` e
   `Vertical` não podem ser porta de navegação isolada. Enquanto não houver
   contexto confiável, ficam em “Outros” e são recuperáveis pela busca global.
4. Departamentos genéricos como `Mercado`, `Moda`, `Móveis`, `Feminino`,
   `Masculino`, `Acessórios` e `Diversos` não podem ser usados para inferir um
   produto específico; devem ser tratados como recortes amplos ou de fallback.
5. A busca contextual precisa somar o filtro de lojas e a faixa de preço já
   existentes, preservar paginação e pesquisar somente o catálogo local.
6. Mudança na coleta ou entrada de loja pode introduzir categoria nova. Ela deve
   aparecer primeiro em “Outros / novas categorias” e nunca desaparecer por
   falta de atualização do app.
7. Quantidade de lojas, de produtos e de categorias é dado de consulta, não
   constante de código, configuração manual do aplicativo ou premissa de teste.
   Uma categoria compartilhada por várias lojas é agregada uma vez na navegação,
   mantendo seus produtos e lojas de origem no resultado.

## Próximo passo proposto

Antes de desenhar a tela, transformar este inventário em uma tabela de
mapeamento inicial e testável, começando pelos subgrupos de maior intenção:
Celulares, TVs, Notebooks, Geladeiras, Fogões, Cozinha, Móveis, Beleza, Mercado
e Saúde. A tabela precisa cobrir explicitamente: categoria compartilhada por
mais de uma loja; chegada de loja nova; categoria nova sem mapeamento;
desativação ou remoção da seleção de uma loja; e `Sem categoria`. Os demais
entram por departamento e busca global desde o primeiro lançamento, sem bloquear
produto raro nem exigir revisão manual.
