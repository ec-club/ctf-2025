import httpx
import logging
from fastapi import Request, Response
from urllib.parse import urlparse

logger = logging.getLogger(__name__)

proxy_client = httpx.AsyncClient()
proxy_headers = [
    "x-forwarded-for",
    "x-forwarded-host",
    "x-forwarded-port",
    "x-real-ip",
    "x-forwarded-server",
    "x-forwarded-proto",
]


async def send_request(url: str, request: Request) -> Response:
    method = request.method
    headers = dict(request.headers)
    for h in proxy_headers:
        if h in headers:
            del headers[h]
    body = await request.body()
    parsed_url = urlparse(url)
    headers["host"] = parsed_url.netloc
    logger.info(
        f"Sending {method} request to {headers['host']} with headers {headers} and body {body}"
    )
    response = await proxy_client.request(
        method=method,
        url=url,
        headers=headers,
        content=body,
    )
    return Response(
        content=response.content,
        status_code=response.status_code,
        headers=dict(response.headers),
    )
