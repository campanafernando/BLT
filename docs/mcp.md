# MCP servers do BLT

O orquestrador expõe cinco conexões MCP. Quatro são ferramentas de leitura sobre a
infraestrutura; uma é a ferramenta de produto (specs), que também escreve — mas só
issues, e de forma explícita.

| Servidor | Fonte | Modo | Ferramentas |
|---|---|---|---|
| `codegraph-api` | índice do `blt-project/api` | leitura | símbolos, callers, callees, impacto, contexto |
| `codegraph-web` | índice do `blt-project/web` | leitura | símbolos, callers, callees, impacto, contexto |
| `postgres-blt` | Postgres do compose | **read-only** | schemas, tabelas, descrição, SQL restrito |
| `minio-blt` | MinIO do compose | **read-only** | buckets, objetos, metadata, URL assinada |
| `blt-specs` | API do BLT | leitura + escrita de issue | listar issues, gerar spec, listar specs, publicar |

## Por que um servidor por fonte

Credencial é o motivo principal. O MCP de Postgres usa `blt_mcp`, um role com `SELECT` e
nada mais; o de MinIO não tem `put` nem `delete` no código. Se tudo fosse um servidor só,
uma credencial de escrita vazaria para ferramentas de leitura.

Os outros motivos são operacionais: um servidor lento não derruba os demais, cada um
reindexa/reinicia sozinho, e o dono do dado define o contrato (o CodeGraph expõe
navegação, o Postgres expõe SQL, o MinIO expõe objeto).

## Como rodar

```sh
cp .env.example .env      # preencha BLT_PG_PASSWORD e MINIO_SECRET_KEY

# 1. Banco e MinIO do projeto
cd blt-project
make up                   # postgres, redis, mailpit, api, web
docker compose --profile storage up -d minio minio-init

# 2. Role read-only (uma vez)
cd ..
docker compose -f blt-project/compose.yaml exec -T db psql -U blt -d blt \
  -v mcp_password="$(grep '^BLT_PG_PASSWORD=' .env | cut -d= -f2-)" \
  -f - < mcp_servers/postgres-readonly.sql

# 3. Índices do CodeGraph (o launcher cria se faltar)
bash .opencode/bin/codegraph-mcp.sh api   # bloqueia; use outro terminal
```

Os clientes leem `opencode.json` (OpenCode) ou `.mcp.json` (Claude Code, Cursor e
qualquer cliente MCP). Nenhum segredo fica nesses arquivos: os launchers leem `.env`.

## O caso FRETE-E como gateway

O BLT é a versão compacta do que o FRETE-E faz em escala. Lá, o número de repositórios,
bancos e índices não cabe em um arquivo por cliente, então existe um **MCP gateway**:
um único ponto de conexão que roteia para o servidor certo conforme o projeto, mantém
as credenciais no servidor e permite trocar a implementação sem reconfigurar cada
cliente.

Aqui não há gateway porque há um projeto só. A estrutura já é a mesma:

- um launcher por fonte (`postgres-mcp.sh`, `minio-mcp.sh`, `codegraph-mcp.sh`);
- credenciais por fonte, não globais;
- o servidor de produto mora no repositório do produto (`blt-project/mcp_server`);
- o cliente só conhece nomes de servidor.

Quando o segundo projeto entrar, o próximo passo natural é o gateway: os launchers viram
implementações internas e o cliente passa a falar com um único endpoint que resolve
`project + source`. É exatamente a evolução do FRETE-E.

## Segurança

- `postgres-blt` roda com `--access-mode restricted`; o role `blt_mcp` não tem `CREATE`,
  `INSERT`, `UPDATE` nem `DELETE` (testado: `InsufficientPrivilege`).
- `minio-blt` não implementa escrita: só `list`, `head` e `presign` de GET.
- `blt-specs` escreve apenas issues no repositório de origem da spec, e só quando
  `GITHUB_TOKEN` está configurado.
- Chaves ficam em `.env` (gitignored). `.mcp.json` e `opencode.json` são versionados
  porque não contêm segredo.

## Troubleshooting

| Sintoma | Causa provável |
|---|---|
| `Missing .env` | copie `.env.example` na raiz do BLT |
| Postgres 401 | role não criado ou senha diferente de `BLT_PG_PASSWORD` |
| MinIO ConnectionError | profile `storage` não subiu, ou endpoint na porta errada |
| CodeGraph "index not found" | rode `codegraph init` + `index` no repo alvo |
| `blt-specs` falha | o branch `feat/spec-from-issue` precisa estar checkout no `blt-project` |
