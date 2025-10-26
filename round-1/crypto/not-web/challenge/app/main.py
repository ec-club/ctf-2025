import base64
import logging
from pydantic import BaseModel
from fastapi import FastAPI, Request, Response, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

from auth import verify_token, generate_token, build_token_contents
from magic import generate_flag

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("app")

app = FastAPI()
security = HTTPBearer()


@app.get("/", dependencies=[Depends(security)])
def flag(
    request: Request,
    response: Response,
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    token = credentials.credentials
    is_valid, _ = verify_token(token)
    if not is_valid:
        response.status_code = 403
        return "Not an admin…"
    flag = generate_flag()
    logger.info(f"Releasing flag {flag} for {request.client.host}")
    return {"flag": generate_flag()}


@app.get("/cnpjbmZic2cgZWJweGYhCg/test/get-flag", dependencies=[Depends(security)])
def hidden_route(
    response: Response, credentials: HTTPAuthorizationCredentials = Depends(security)
):
    token = credentials.credentials
    is_valid, data = verify_token(token)
    if is_valid:
        return {"flag": generate_flag()}
    if data:
        response.headers["Metadata"] = (
            base64.urlsafe_b64encode(data).decode().rstrip("=")
        )
    response.status_code = 403
    return {"detail": "Invalid token"}


class LoginRequest(BaseModel):
    username: str
    password: str


@app.get("/login")
def login_page(response: Response):
    response.headers["Accept"] = "application/json"
    return {
        "message": "Please POST your username and password to this endpoint to receive a token."
    }


@app.post("/login")
def login(login_request: LoginRequest, response: Response):
    token = generate_token(login_request.username, login_request.password)
    response.headers["Token"] = build_token_contents(
        login_request.username, login_request.password
    )
    return {"access_token": token}
