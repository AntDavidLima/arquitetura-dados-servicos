# Trabalho Final: Arquitetura de Serviços e Dados

> Registro fiel do enunciado da disciplina. O que este repositório já implementa
> está documentado no [README.md](README.md).

## Visão Geral

Este trabalho tem como objetivo integrar de forma prática os conceitos de Arquitetura de
Serviços (Docker, Docker Compose, Nginx, CI/CD, DNS) e Arquitetura de Dados (Data Lake,
Data Warehouse, Data Mart, Consultas SQL) em um ecossistema ponta a ponta.

## Grupos

Esse trabalho poderá ser feito em grupos de 3 pessoas.

## Parte 1: Arquitetura de Serviços e Aplicação (CRUD de Produtos)

A infraestrutura do ecossistema de aplicação será orquestrada via Docker Compose e conterá
4 serviços:

```text
[ Cliente / Browser ]
        |
        v
 [ Proxy Reverso ] (Nginx) - Porta 80
        |
        +---> [ Web Server / Frontend ] (HTML/JS)
        |
        +---> [ Application Server / API ] (Node, Python, Go, Java, etc.)
                    |
                    v
          [ Banco de Dados OLTP ] (PostgreSQL / MySQL)
```

### Requisitos da Infraestrutura

**1. Proxy Reverso (Nginx)**

- Ponto único de entrada na porta `80`.
- Redireciona requisições web para o container Frontend e chamadas `/api/*` para o
  container da API.

**2. Web Server (Frontend)**

- Interface web simples para gerenciamento de produtos (Listar, Adicionar, Editar e
  Deletar).

**3. Application Server (API REST)**

Endpoints obrigatórios:

- `GET /api/products` — Lista todos os produtos
- `GET /api/products/{id}` — Busca um produto por ID
- `POST /api/products` — Cadastra um novo produto
- `PUT /api/products/{id}` — Atualiza um produto por ID
- `DELETE /api/products/{id}` — Remove um produto por ID

**4. Banco de Dados Operacional (OLTP)**

SGBD relacional com a tabela `product`:

- `id` (INT, Primary Key, Auto Increment/Serial)
- `name` (VARCHAR(50), NOT NULL)

## Parte 2: Esteira de CI/CD e Gestão de Containeres

Configurar uma pipeline de CI/CD (ex: GitHub Actions) automatizada.

Fluxo da pipeline:

- **Trigger:** push no repositório.
- **Etapas:**
  1. **Build:** construção das imagens Docker dos serviços.
  2. **Test:** teste simples de fumaça (ex: verificar se os containeres sobem e respondem
     na porta correta).
  3. **Push:** publicação das imagens no Docker Hub.

## Parte 3: Ecossistema de Dados — MovieFlix

Simular a arquitetura de dados em 3 camadas:

1. **Data Lake (Dados Brutos):** arquivos CSV armazenados em diretório local/volume
   (`movies.csv`, `users.csv`, `ratings.csv`).
2. **Data Warehouse (Dados Tratados):** banco de dados analítico (ex: PostgreSQL) populado
   via script de carga (Python/SQL).
3. **Data Marts (Visões de Negócio):** criação de `VIEWS` SQL:
   - View 1: Top 10 filmes mais bem avaliados por gênero.
   - View 2: Nota média por faixa etária dos usuários.
   - View 3: Número de avaliações por país.

## Parte 4: Consultas Analíticas (Negócio)

Queries SQL diretas para responder:

1. Quais são os 5 filmes mais populares (maior número de avaliações)?
2. Qual gênero possui a melhor avaliação média?
3. Qual país assiste/avalia mais filmes?

## Parte 5: Bônus (DNS)

- Apontamento de um domínio ou subdomínio gratuito (ex: DuckDNS, No-IP) para a aplicação.

## Entregáveis do Projeto

1. **Repositório GitHub:** código-fonte, `Dockerfiles`, `docker-compose.yml`, pipeline de
   CI/CD, scripts de carga/SQL e `README.md` explicativo.
2. **Demonstração Prática:** pipeline funcionando no GitHub Actions, imagens no Docker Hub,
   aplicação acessível via Proxy/DNS e resultados das consultas analíticas.

## Estrutura de Pastas Recomendada

```text
meu-projeto/
|-- .github/
|   `-- workflows/
|       `-- main.yml           # Pipeline de CI/CD
|-- nginx/
|   |-- Dockerfile
|   `-- nginx.conf             # Configuração do Proxy Reverso
|-- frontend/
|   |-- Dockerfile
|   `-- index.html             # Interface web simples (HTML/JS)
|-- backend/
|   |-- Dockerfile
|   `-- ...                    # Código da API (Node, Python, etc.)
|-- data-ecosystem/
|   |-- datalake/              # Dados brutos (.csv)
|   |   |-- movies.csv
|   |   |-- users.csv
|   |   `-- ratings.csv
|   |-- etl/                   # Scripts de carga (ex: Python ou Bash)
|   |   `-- load_dw.py
|   `-- sql/                   # DDLs, Views do Data Mart e Queries
|       |-- 01_dw_schema.sql
|       |-- 02_datamarts.sql
|       `-- 03_analytics.sql
|-- docker-compose.yml         # Orquestração local dos containeres
`-- README.md
```

## Modelo de `docker-compose.yml` (Gabarito)

O gabarito prevê **5 serviços**: além dos 4 da Parte 1, um segundo banco `db_dw` na porta
`5433` para o Data Warehouse do MovieFlix (Parte 3), com o diretório do Data Lake montado
como volume.

```yaml
services:
  proxy:                      # 1. PROXY REVERSO (Nginx)
    build: ./nginx
    container_name: proxy_reverso
    ports:
      - "80:80"
    depends_on:
      - frontend
      - backend
    networks:
      - app-network

  frontend:                   # 2. WEB SERVER (Frontend)
    build: ./frontend
    container_name: web_frontend
    networks:
      - app-network

  backend:                    # 3. APPLICATION SERVER (API REST)
    build: ./backend
    container_name: api_backend
    environment:
      - DB_HOST=db_oltp
      - DB_USER=app_user
      - DB_PASSWORD=app_pass
      - DB_NAME=products_db
      - DB_PORT=5432
    depends_on:
      - db_oltp
    networks:
      - app-network

  db_oltp:                    # 4. BANCO OPERACIONAL (OLTP)
    image: postgres:15-alpine
    container_name: db_oltp
    environment:
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD: app_pass
      POSTGRES_DB: products_db
    ports:
      - "5432:5432"
    volumes:
      - oltp_data:/var/lib/postgresql/data
    networks:
      - app-network

  db_dw:                      # 5. BANCO ANALÍTICO (Data Warehouse - MovieFlix)
    image: postgres:15-alpine
    container_name: db_dw
    environment:
      POSTGRES_USER: dw_user
      POSTGRES_PASSWORD: dw_pass
      POSTGRES_DB: movieflix_dw
    ports:
      - "5433:5432"
    volumes:
      - dw_data:/var/lib/postgresql/data
      - ./data-ecosystem/datalake:/datalake
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  oltp_data:
  dw_data:
```

## Modelo de `nginx/nginx.conf` (Gabarito)

```nginx
server {
    listen 80;

    # Frontend (Página Web)
    location / {
        proxy_pass http://frontend:80;
    }

    # Backend (API REST)
    location /api/ {
        proxy_pass http://backend:3000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```
