# MCP — MinIO read-only

A minimal MCP server to inspect the BLT bucket with no risk of change.

## Tools

| Tool | Returns |
|---|---|
| `list_buckets` | names of visible buckets |
| `list_objects(prefix, limit, bucket)` | key, size and last modified |
| `object_metadata(bucket, key)` | content type, size, etag, date |
| `presigned_url(bucket, key, expires_minutes)` | temporary GET URL |

There is no `put`, `delete` or `policy`, and the credential must be the read-only MinIO
user created by `minio-init` (`MINIO_RO_ACCESS_KEY`), never the root keys.

## Variables

In the BLT `.env` (documented in `.env.example`):

```
MINIO_ENDPOINT=http://127.0.0.1:9200
MINIO_ACCESS_KEY=...
MINIO_SECRET_KEY=...
MINIO_BUCKET=blt-media
```

## Run

```sh
bash .opencode/bin/minio-mcp.sh
```

The launcher creates an ephemeral `uv` environment
with `mcp` and `boto3`; nothing needs to be installed in the API virtualenv.
