# BLT — regras para agentes

## Contexto

`BLT` orquestra; `blt-project` implementa. `blt-project/api` é Django 6 + DRF,
`blt-project/web` é React + Vite + TypeScript, e `blt-project/api/hypermedia` é o
cliente server-rendered com HTMX + Alpine.js.

## Fronteiras de código

- `tasks/views.py` só valida entrada, chama serviço e devolve resposta.
- Regra de negócio vive em `tasks/services.py`. Nunca em view, serializer ou template.
- Consulta e filtro vivem em `tasks/selectors.py` e `tasks/filters.py`.
- `hypermedia/views.py` chama os mesmos `services` e `selectors` da API. Proibido duplicar regra.
- `web/src/lib/api.ts` é o único lugar que fala HTTP. Componente não monta URL.
- `web/src/features/<área>/` agrupa hook, componente e tipos daquela área.

## Contrato

- O schema OpenAPI é gerado pelo `drf-spectacular`; o cliente React é escrito à mão
  sobre os tipos em `web/src/lib/types.ts`. Se o contrato mudar, atualize os dois.
- Erros seguem o formato do DRF (`detail`, ou mapa campo → lista). O front lê os dois.

## Testes

- `pytest` com `pytest-django`. Toda regra nova tem teste de serviço e de endpoint.
- Cobertura mínima: 80% (`make test` falha abaixo disso).
- Não use `time.sleep`, relógio real ou rede em teste. Congele datas com `freezegun`
  quando o comportamento depender de "hoje".

## Estilo

- Python: ruff, line-length 100, aspas duplas, imports ordenados.
- TypeScript: sem `any` implícito; funções pequenas; estado de servidor no TanStack Query.
- CSS: um único `index.css` com variáveis; sem framework de UI.
- Comentário só para o "porquê" que o código não mostra.

## MCP

- Um servidor por fonte; credencial no `.env`, nunca em `opencode.json` ou `.mcp.json`.
- `postgres-blt` e `minio-blt` são read-only por construção. Não adicione ferramenta de
  escrita sem revisar o contrato e o role do banco.
- `blt-specs` escreve apenas issues, e só com `GITHUB_TOKEN` configurado.
- O padrão de escala é o gateway do FRETE-E; aqui os launchers fazem o papel de roteamento.

## Proibido

- Commitar sem autorização.
- Colocar segredo, token ou chave em código versionado.
- Adicionar dependência para tarefa de três linhas.
- Deixar warning no console do navegador ou `manage.py check` com aviso.
