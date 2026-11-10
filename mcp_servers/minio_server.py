"""Read-only MinIO/S3 MCP server for the BLT orchestrator.

Exposes listing, metadata and presigned GET URLs. There is no put, delete or
policy tool on purpose: an agent inspecting a bucket should not be able to
change it.
"""

import asyncio
import os
from datetime import timedelta

import boto3
from botocore.config import Config
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("blt-minio")

DEFAULT_BUCKET = os.getenv("MINIO_BUCKET", "blt-media")


def _client():
    return boto3.client(
        "s3",
        endpoint_url=os.getenv("MINIO_ENDPOINT", "http://127.0.0.1:9200"),
        aws_access_key_id=os.getenv("MINIO_ACCESS_KEY", ""),
        aws_secret_access_key=os.getenv("MINIO_SECRET_KEY", ""),
        region_name="us-east-1",
        config=Config(signature_version="s3v4", s3={"addressing_style": "path"}),
    )


def _list_buckets() -> list[str]:
    return [bucket["Name"] for bucket in _client().list_buckets()["Buckets"]]


def _list_objects(prefix: str, limit: int, bucket: str) -> list[dict]:
    response = _client().list_objects_v2(Bucket=bucket, Prefix=prefix, MaxKeys=limit)
    return [
        {
            "key": item["Key"],
            "size": item["Size"],
            "last_modified": item["LastModified"].isoformat(),
        }
        for item in response.get("Contents", [])
    ]


def _metadata(bucket: str, key: str) -> dict:
    head = _client().head_object(Bucket=bucket, Key=key)
    return {
        "bucket": bucket,
        "key": key,
        "size": head["ContentLength"],
        "content_type": head.get("ContentType"),
        "etag": head.get("ETag", "").strip('"'),
        "last_modified": head["LastModified"].isoformat(),
    }


def _presign(bucket: str, key: str, expires_minutes: int) -> str:
    return _client().generate_presigned_url(
        "get_object",
        Params={"Bucket": bucket, "Key": key},
        ExpiresIn=int(timedelta(minutes=expires_minutes).total_seconds()),
    )


@mcp.tool()
async def list_buckets() -> list[str]:
    """List buckets visible to the read-only MinIO credentials."""
    return await asyncio.to_thread(_list_buckets)


@mcp.tool()
async def list_objects(prefix: str = "", limit: int = 50, bucket: str = DEFAULT_BUCKET) -> list[dict]:
    """List objects under a prefix, up to 200 per call."""
    return await asyncio.to_thread(_list_objects, prefix, min(max(limit, 1), 200), bucket)


@mcp.tool()
async def object_metadata(bucket: str, key: str) -> dict:
    """Return size, content type, etag and last modification for one object."""
    return await asyncio.to_thread(_metadata, bucket, key)


@mcp.tool()
async def presigned_url(bucket: str, key: str, expires_minutes: int = 15) -> str:
    """Create a temporary GET URL for one object. Read-only."""
    return await asyncio.to_thread(
        _presign, bucket, key, min(max(expires_minutes, 1), 1440)
    )


if __name__ == "__main__":
    mcp.run()
