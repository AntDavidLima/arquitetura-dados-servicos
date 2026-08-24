# Proposta de Trabalho

## Visao Geral
Este projeto integra Arquitetura de Servicos (Docker, Docker Compose, Nginx, CI/CD, DNS) e Arquitetura de Dados (Data Lake, Data Warehouse, Data Mart e consultas SQL) em um fluxo ponta a ponta.

## Integrantes
Trabalho em grupo de ate 3 pessoas.

## Parte 1 - Arquitetura de Servicos e Aplicacao (CRUD de Produtos)

### Arquitetura

```text
[ Cliente / Browser ]
        |
        v
[ Proxy Reverso ] (Nginx) - Porta 80
        |
        +--> [ Web Server / Frontend ] (HTML/JS)
        |
        +--> [ Application Server / API ] (Python/FastAPI)
                    |
                    v
          [ Banco de Dados OLTP ] (PostgreSQL/MySQL)
```

### Requisitos
- Nginx como ponto unico de entrada na porta `80`.
- Roteamento web para frontend e chamadas `/api/*` para API.
- Frontend com operacoes de produto: listar, adicionar, editar e deletar.
- API REST com endpoints:
  - `GET /api/products`
  - `GET /api/products/{id}`
  - `POST /api/products`
  - `PUT /api/products/{id}`
  - `DELETE /api/products/{id}`
- Banco relacional com tabela `product`:
  - `id` (INT, PK, auto increment/serial)
  - `name` (VARCHAR(50), NOT NULL)

### Implementacao atual (neste repositorio)
- Proxy: Nginx
- Frontend: HTML + JavaScript
- Backend: Python + FastAPI + SQLAlchemy
- OLTP: PostgreSQL no Compose e SQLite no modo local sem Docker

### Estrutura do projeto

```text
.
|-- docker-compose.yml
|-- nginx/
|   |-- Dockerfile
|   `-- nginx.conf
|-- frontend/
|   |-- Dockerfile
|   `-- index.html
|-- backend/
|   |-- Dockerfile
|   |-- requirements.txt
|   |-- app/
|   |   |-- main.py
|   |   |-- db.py
|   |   |-- models.py
|   |   |-- schemas.py
|   |   |-- crud.py
|   |   `-- routers/products.py
|   `-- tests/test_products.py
`-- db/
    `-- init/001_create_product.sql
```

### Execucao com Docker

```bash
docker compose up --build
```

Acessos esperados:
- `http://localhost/`
- `http://localhost/api/products`
- `http://localhost/health`

### Execucao sem Docker (fallback local)

Terminal 1 (backend):

```bash
cd backend
python -m pip install -r requirements.txt
set DATABASE_URL=sqlite:///./products.db
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Terminal 2 (frontend):

```bash
cd frontend
python -m http.server 5500
```

Acessos esperados:
- `http://localhost:5500`
- `http://localhost:8000/api/products`

### Validacao
- Teste automatizado do CRUD no backend: `backend/tests/test_products.py`.
- Resultado local obtido: `1 passed`.

## Parte 2 - Esteira de CI/CD e Gestao de Containers

Pipeline automatizada (exemplo: GitHub Actions), com:
- Trigger em push.
- Build das imagens Docker.
- Smoke test basico de disponibilidade.
- Push para Docker Hub.

## Parte 3 - Ecossistema de Dados (MovieFlix)

Arquitetura em 3 camadas:
- Data Lake (CSV brutos: `movies.csv`, `users.csv`, `ratings.csv`).
- Data Warehouse (dados tratados via ETL).
- Data Marts (views SQL de negocio).

Views esperadas:
- Top 10 filmes mais bem avaliados por genero.
- Nota media por faixa etaria.
- Numero de avaliacoes por pais.

## Parte 4 - Consultas Analiticas

Perguntas de negocio:
- Quais sao os 5 filmes mais populares?
- Qual genero tem melhor media de avaliacao?
- Qual pais avalia mais filmes?

## Parte 5 - Bonus (DNS)

Apontar dominio/subdominio gratuito para a aplicacao (ex.: DuckDNS, No-IP).

## Entregaveis
- Repositorio com codigo-fonte, Dockerfiles, `docker-compose.yml`, pipeline CI/CD, scripts SQL/ETL e documentacao.
- Demonstracao da aplicacao e resultados analiticos.


