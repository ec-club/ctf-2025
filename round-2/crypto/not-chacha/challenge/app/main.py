from fastapi import FastAPI, Request, Response, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel

from auth import generate_token, verify_token
from magic import generate_flag

app = FastAPI()
security = HTTPBearer()


class LoginRequest(BaseModel):
    username: str


@app.post("/login")
def login(request: LoginRequest):
    token = generate_token(request.username)
    return {"token": token}


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
