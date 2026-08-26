# Arquitetura de dados do MovieFlix

## Objetivo

Este projeto simula um ecossistema de dados em três camadas para permitir que os dados do MovieFlix sejam armazenados, tratados e consultados para apoiar decisões de negócio.

## Camadas implementadas

### 1. Data Lake: dados brutos

Os arquivos CSV estão em `data/raw/`:

- `movies.csv`: catálogo de filmes, gêneros e ano de lançamento.
- `users.csv`: usuários, idade e país.
- `ratings.csv`: avaliações, usuários, filmes, notas e datas.

Essa camada mantém o formato original e simples dos dados. CSV foi escolhido porque é fácil de inspecionar, versionar, substituir e utilizar durante a etapa de aprendizado, sem depender inicialmente de um banco de dados.

### 2. Data Warehouse: dados tratados

O PostgreSQL é executado pelo Docker e recebe os dados nas tabelas:

- `movies`
- `users`
- `ratings`

O schema está em `warehouse/schema.sql`. Ele define chaves primárias, relacionamentos entre tabelas, validações para idade, ano e nota, além de índices nas colunas mais usadas nos relacionamentos.

O PostgreSQL foi escolhido por ser um banco relacional amplamente utilizado, possuir suporte completo a SQL analítico e permitir que a arquitetura seja executada localmente de forma muito próxima a um ambiente real.

O carregamento é feito por `scripts/load_data.py`. O script lê os CSVs e usa as variáveis `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` e `DB_PASSWORD`, permitindo executar a mesma carga dentro ou fora do Docker.

Antes da carga, as tabelas são limpas com `TRUNCATE ... CASCADE`. Essa decisão torna o processo idempotente: executar o carregador novamente não duplica os dados e sempre reproduz o estado dos arquivos brutos.

### 3. Data Marts: visões de negócio

As views são criadas no schema do banco:

- `mart_top_10_movies_by_genre`: classifica os filmes por nota média dentro de cada gênero e limita o resultado aos dez primeiros.
- `mart_average_rating_by_age_group`: agrupa a nota média pelas faixas `13-17`, `18-25`, `26-35`, `36-50` e `51+`.
- `mart_ratings_by_country`: apresenta quantidade de avaliações, usuários ativos e nota média por país.

Views foram usadas porque encapsulam regras de negócio em SQL, evitam duplicação de consultas e permitem que ferramentas de BI ou clientes SQL consumam os mesmos resultados.

## Orquestração local

O `docker-compose.yml` define dois serviços:

1. `postgres`: banco persistente em um volume Docker.
2. `loader`: ambiente Python temporário que aguarda o banco ficar saudável e executa a carga dos CSVs.

O healthcheck do PostgreSQL evita que o carregador tente inserir dados antes de o banco estar pronto. O volume mantém os dados entre reinicializações, enquanto `docker compose down -v` permite recriar o ambiente do zero quando necessário.

## Consultas analíticas

As consultas solicitadas estão em `queries/analytics.sql`:

- cinco filmes com maior número de avaliações;
- gênero com melhor nota média;
- país com maior número de avaliações;
- consulta das três views de Data Mart.

Como não existe uma tabela de eventos de visualização, “país que mais assiste” é representado pelo país com mais avaliações. Para medir visualizações reais, seria necessário adicionar uma tabela de eventos, como `watch_events`, com usuário, filme, data e duração assistida.

## Como executar

Na raiz do projeto:

```powershell
docker compose up --build
```

Depois, para consultar os Data Marts e as perguntas de negócio:

```powershell
Get-Content queries\analytics.sql | docker compose exec -T postgres psql -U movieflix -d movieflix
```

Para abrir um terminal interativo no banco:

```powershell
docker compose exec postgres psql -U movieflix -d movieflix
```

Essa organização separa armazenamento bruto, persistência tratada e consumo analítico, mantendo o projeto pequeno o suficiente para ser executado localmente e demonstrando conceitos aplicáveis a arquiteturas de dados maiores.
