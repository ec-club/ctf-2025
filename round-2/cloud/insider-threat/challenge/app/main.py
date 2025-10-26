import os
import socket
import ipaddress
from fastapi import FastAPI, Request, Response, Depends
from pydantic import BaseModel
from urllib.parse import urlparse
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from auth import verify_token, generate_token
from meta import router as meta_router
from magic import generate_flag
from proxy import send_request

app = FastAPI()
security = HTTPBearer()


@app.get("/", dependencies=[Depends(security)])
def flag(
    request: Request,
    response: Response,
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    token = credentials.credentials
    is_valid = verify_token(token)
    if not is_valid:
        response.status_code = 403
        return "Forbidden…"
    flag = generate_flag(request.client.host)
    return {"flag": flag}


class LoginRequest(BaseModel):
    username: str
    password: str


@app.post("/login")
def login(request: LoginRequest):
    token = generate_token(request.username)
    return {"token": token}


ALLOWED_NETWORK = os.getenv("ALLOWED_NETWORK")


def is_allowed(url: str) -> bool:
    parsed_url = urlparse(url)
    if parsed_url.scheme not in ["http", "https"]:
        return Response(
            content="Invalid URL scheme. Only http and https are allowed.",
            status_code=400,
        )
    if parsed_url.port not in [None, 80, 443]:
        return Response(
            content="Invalid URL port. Only default ports are allowed.",
            status_code=400,
        )
    if not parsed_url.hostname:
        return Response(
            content="Invalid URL. Hostname is required.",
            status_code=400,
        )
    ip_address = ipaddress.ip_address(
        socket.getaddrinfo(parsed_url.hostname, None)[0][4][0]
    )
    if isinstance(ip_address, ipaddress.IPv6Address):
        return True
    return ip_address in ipaddress.ip_network(ALLOWED_NETWORK)


@app.api_route(
    "/proxy",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"],
)
async def proxy(url: str, request: Request):
    try:
        if not is_allowed(url):
            return Response(
                content=f"Invalid URL. Only IPv6 or {ALLOWED_NETWORK} addresses are allowed.",
                status_code=400,
            )
        return await send_request(url, request)
    except Exception as e:
        print(e)
        return Response(
            content="Error proxying request…",
            status_code=500,
        )


app.include_router(meta_router)
