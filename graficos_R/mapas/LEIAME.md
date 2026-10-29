# Mapas (para trabalhar offline)

Arquivos que o Cinabro vai usar nos mapas coloridos (coropleto). Ficam no repositório e no ZIP: **não precisam de internet** e podem ser editados.

| Arquivo | O que é |
|---|---|
| `mundo_paises.geojson` | Contorno de 243 países/territórios (escala 1:50 milhões). Cada país traz `name` (nome em **inglês**), `iso3`, `continent` e `region`. |
| `mundo_regioes.csv` | A tabela de países e regiões comerciais, **para editar no Excel** (separador `;`, UTF-8). Coluna `country` = nome em inglês, `region` = região. |
| `brasil_estados.geojson` | Contorno dos 27 estados (1:50 milhões), com `name`, `uf` (sigla) e `region` (região do IBGE). |
| `brasil_estados.csv` | Tabela dos estados: `uf`, `state`, `region`. |

## Regiões comerciais do mapa-múndi

`Brazil`, `LATAM`, `North America`, `Western Europe`, `Asia Pacific` e `Other` (o que não entra nas cinco).

- **Brazil:** só o Brasil.
- **LATAM:** América do Sul (sem o Brasil), América Central, Caribe **e o México**.
- **North America:** Estados Unidos, Canadá, Groenlândia, Bermudas, Saint-Pierre e Miquelon.
- **Western Europe:** Europa Ocidental, do Norte e do Sul (Reino Unido, Irlanda, França, Alemanha, Países Baixos, Bélgica, Luxemburgo, Suíça, Áustria, Espanha, Portugal, Itália, Grécia, Chipre, países nórdicos...). Fora: Leste Europeu e Balcãs.
- **Asia Pacific:** Leste, Sudeste e Sul da Ásia, Austrália, Nova Zelândia e ilhas do Pacífico. Fora: Ásia Central, Oriente Médio e Rússia.
- **Other:** África, Oriente Médio, Ásia Central, Leste Europeu e Rússia.

Essa divisão é uma convenção comercial comum, não uma norma. **Para mudar um país de região, edite a coluna `region` do `mundo_regioes.csv`** (por exemplo, o México para North America ou a África do Sul para outra região). Para criar uma região nova (ex.: `MEA`), basta escrever o nome na coluna.

Observações:
- `French Guiana` agrupa a Guiana Francesa e os departamentos franceses do Caribe (Martinica, Guadalupe...), separados da França europeia para ficarem na LATAM.
- Os nomes são os do Natural Earth (ex.: `United States of America`, `Dem. Rep. Congo`, `Bosnia and Herz.`). Se um país não casar com a sua planilha, ajuste o nome na planilha ou no `mundo_regioes.csv`.
- Ver `mundo_regioes.csv` para a lista completa de nomes aceitos.

## Origem e licença

- Mundo e estados: **Natural Earth** (naturalearthdata.com), escala 50m, `ne_50m_admin_0_countries` e `ne_50m_admin_1_states_provinces`, **domínio público** (sem restrição de uso, nem comercial). As fronteiras seguem a visão do Natural Earth, que pode diferir da de cada país em áreas disputadas.
- Coordenadas arredondadas a 3 casas decimais (~100 m) para o arquivo ficar leve.
- Para mais detalhe nos estados ou municípios do Brasil (malhas do IBGE), é preciso baixar outro arquivo; avise.
