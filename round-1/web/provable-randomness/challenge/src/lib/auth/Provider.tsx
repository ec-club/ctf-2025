import "server-only";
import { eq } from "drizzle-orm";
import { ReactNode } from "react";

import { db } from "@/models/db";
import { users } from "@/models/user";

import { AuthContextProvider } from "./Context";
import { getVerifiedSession } from "@/core/auth/verify";

export async function getAuthState() {
  const claims = await getVerifiedSession();
  if (!claims) {
    return null;
  }

  const user = await db.query.users.findFirst({
    where: eq(users.id, claims.userId),
    columns: { username: true, balance: true },
  });
  if (!user) {
    return null;
  }
  return { username: user.username, balance: user.balance };
}

export async function AuthProvider({ children }: { children: ReactNode }) {
  const authState = await getAuthState();
  return (
    <AuthContextProvider initialValue={authState}>
      {children}
    </AuthContextProvider>
  );
}
