# MCP — MinIO read-only

Servidor MCP mínimo para inspecionar o bucket do BLT sem risco de alteração.

## Ferramentas

| Ferramenta | Retorno |
|---|---|
| `list_buckets` | nomes dos buckets visíveis |
| `list_objects(prefix, limit, bucket)` | chave, tamanho e data de modificação |
| `object_metadata(bucket, key)` | content-type, tamanho, etag, data |
| `presigned_url(bucket, key, expires_minutes)` | URL de GET temporária |

Não existe `put`, `delete` ou `policy`. A credencial pode ser de leitura; mesmo que não
seja, o servidor não oferece a operação.

## Variáveis

```
MINIO_ENDPOINT=http://127.0.0.1:9200
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
MINIO_BUCKET=blt-media
```

## Executar

```sh
bash .opencode/bin/minio-mcp.sh
```

O launcher cria um ambiente `uv` efêmero com `mcp` e `boto3`; não é preciso instalar
nada no venv da API.
