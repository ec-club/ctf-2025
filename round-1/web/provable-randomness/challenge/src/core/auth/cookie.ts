import "server-only";
import { cookies } from "next/headers";

export function getSessionCookieName() {
  return process.env.APP_ENV === "production" ? "__Host-auth" : "auth";
}
export async function getSessionCookie() {
  const cookieStore = await cookies();
  return cookieStore.get(getSessionCookieName())?.value;
}
