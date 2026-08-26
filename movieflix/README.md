# MovieFlix - Ecossistema de dados

Este projeto simula uma arquitetura em tres camadas:

* **Data Lake:** CSVs brutos em `data/raw/`.
* **Data Warehouse:** PostgreSQL com as tabelas `movies`, `users` e `ratings`.
* **Data Marts:** views `mart_top_10_movies_by_genre`, `mart_average_rating_by_age_group` e `mart_ratings_by_country`.

## Executar com Docker

Na raiz do projeto:

```bash
docker compose up --build
```

O banco fica disponivel em `localhost:5432` (database `movieflix`, user/password `movieflix`). O servico `loader` carrega os CSVs automaticamente e pode ser executado novamente sem duplicar dados:

```bash
docker compose run --rm loader
```

Para abrir um terminal SQL:

```bash
docker compose exec postgres psql -U movieflix -d movieflix
```

Depois, execute `\i /...` apenas se o arquivo estiver montado; a forma mais simples e copiar o conteudo de `queries/analytics.sql`, ou usar:

```bash
Get-Content queries\analytics.sql | docker compose exec -T postgres psql -U movieflix -d movieflix
```

Para reiniciar totalmente o ambiente apos alterar o schema:

```bash
docker compose down -v
docker compose up --build
```

## Executar o carregador localmente

Com PostgreSQL acessivel e Python instalado:

```bash
psql -U movieflix -d movieflix -f warehouse/schema.sql
pip install -r requirements.txt
python scripts/load_data.py
```

As credenciais podem ser alteradas pelas variaveis `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` e `DB_PASSWORD`.

As tres queries de negocio e a consulta das views estao em `queries/analytics.sql`.
