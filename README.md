# Arquitetura de Serviços e Dados

Implementação do trabalho final da disciplina. O enunciado completo está em
[PROPOSTA_DE_TRABALHO.md](PROPOSTA_DE_TRABALHO.md).

## Status das entregas

| Parte | Escopo | Status    |
| --- | --- |-----------|
| 1 | Proxy reverso, frontend, API REST e banco OLTP | Concluída |
| 2 | Esteira de CI/CD e publicação no Docker Hub | Concluída |
| 3 | Ecossistema de dados MovieFlix (Data Lake / DW / Data Marts) | Pendente  |
| 4 | Consultas analíticas de negócio | Pendente  |
| 5 | Bônus: apontamento de DNS | Concluída |

## Arquitetura

```text
[ Cliente / Browser ]
        |
        v
 [ Proxy Reverso ] (Nginx) - Porta 80
        |
        +---> [ Frontend ] (HTML/JS + Nginx)
        |
        +---> [ API REST ] (Python / FastAPI + SQLAlchemy)
                    |
                    v
          [ OLTP ] (PostgreSQL 15)
```

O Nginx é o **ponto único de entrada**: apenas o container `proxy_reverso` publica porta no
host. O frontend e a API não são acessíveis diretamente de fora, todo o tráfego passa pela
porta `80`.

## Endpoints da API

| Método | Rota | Descrição |
| --- | --- | --- |
| `GET` | `/api/products` | Lista todos os produtos |
| `GET` | `/api/products/{id}` | Busca um produto por ID |
| `POST` | `/api/products` | Cadastra um novo produto |
| `PUT` | `/api/products/{id}` | Atualiza um produto por ID |
| `DELETE` | `/api/products/{id}` | Remove um produto por ID |

O backend expõe ainda `GET /health` para verificação local. Ele **não** é roteado pelo proxy
e não faz parte do contrato exigido pelo enunciado.

## Estrutura do projeto

```text
.
|-- .github/
|   `-- workflows/
|       `-- main.yml           # Pipeline de CI/CD
|-- nginx/
|   |-- Dockerfile
|   `-- nginx.conf             # Configuração do proxy reverso
|-- frontend/
|   |-- Dockerfile
|   `-- index.html             # Interface web (HTML/JS)
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
|-- db/
|   `-- init/001_create_product.sql
|-- docker-compose.yml
`-- README.md
```

## Execução com Docker

```bash
docker compose up -d --build
```

Acessos:

- Aplicação web: `https://escala-tech.davidblima.com.br`
- API: `http://escala-tech.davidblima.com.br/api/products`

O serviço `backend` só inicia depois que o `db_oltp` passa no `pg_isready`, via
`healthcheck` combinado com `depends_on: condition: service_healthy`. Sem isso a API tenta
conectar antes do Postgres aceitar conexões e o container encerra com erro.

Para derrubar:

```bash
docker compose down
```

## Execução sem Docker

Terminal 1 (backend, usando SQLite):

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

Acessos: frontend em `http://localhost:5500` e API em `http://localhost:8000/api/products`.

## Testes

```bash
cd backend
python -m pytest tests -q
```

O teste cobre o fluxo CRUD completo (criar, listar, buscar, atualizar, remover e confirmar
o 404 posterior) usando SQLite em memória, com a dependência `get_db` sobrescrita. Não
precisa de Postgres no ambiente.

## CI/CD

A pipeline fica em [`.github/workflows/cicd.yml`](.github/workflows/cicd.yml) e dispara em
push e pull request para a `main`, em três jobs encadeados:

1. **`test`** — instala as dependências e roda o `pytest`.
2. **`smoke`** — builda as imagens, sobe o ambiente com o Compose, espera o proxy responder
   e valida pela porta 80: `GET /`, `GET /api/products` e um ciclo `POST` + `DELETE`.
   Em caso de falha publica os logs dos containeres.
3. **`push`** — publica as imagens no Docker Hub. Só roda em push na `main`.

As imagens são nomeadas pelo próprio `docker-compose.yml`:

```yaml
image: ${DOCKER_NAMESPACE:-local}/arqds-proxy:${IMAGE_TAG:-latest}
```

Localmente resolve para `local/arqds-*:latest`; na CI, `DOCKER_NAMESPACE` vem do secret e
`IMAGE_TAG` recebe o SHA do commit e também a tag `latest`.

### Secrets necessários

O job `push` depende de dois secrets configurados em **Settings → Secrets and variables →
Actions** do repositório:

| Secret               | Origem                                            |
|----------------------|---------------------------------------------------|
| `DOCKERHUB_USERNAME` | usuário do Docker Hub                             |
| `DOCKERHUB_TOKEN`    | access token gerado em Account Settings → Security |
| `POSTGRES_USER`      | usuário do banco de dados                         |
| `POSTGRES_PASSWORD`  | senha do banco de dados                           |

Enquanto os secrets não existirem, os jobs `test` e `smoke` continuam passando normalmente
e apenas o `push` falha.
