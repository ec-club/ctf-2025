import "server-only";
import { decryptJWT } from "./jwt";
import { getSessionCookie } from "./cookie";

export async function getVerifiedSession() {
  const authToken = await getSessionCookie();
  if (!authToken) {
    return null;
  }
  return await decryptJWT(authToken).catch(() => null);
}
