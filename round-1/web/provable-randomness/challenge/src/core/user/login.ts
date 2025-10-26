"use server";
import z from "zod";
import argon2 from "argon2";
import { eq } from "drizzle-orm";
import { cookies } from "next/headers";

import { db } from "@/models/db";
import { users } from "@/models/user";
import { generateJWT } from "@/core/auth/jwt";
import { getSessionCookieName } from "@/core/auth/cookie";

import { loginSchema } from "./login.schema";

export async function loginUser(input: z.infer<typeof loginSchema>) {
  if (!loginSchema.safeParse(input).success) {
    return { error: "Bad request" };
  }
  try {
    const user = await db.transaction(async (tx) => {
      const [user] = await tx
        .select({
          id: users.id,
          passwordHash: users.passwordHash,
          balance: users.balance,
        })
        .from(users)
        .where(eq(users.username, input.username))
        .limit(1);
      if (!user) {
        console.error("User not found:", input.username);
        return { error: "Invalid username or password" };
      }

      const validPassword = await argon2.verify(
        user.passwordHash,
        input.password
      );
      if (!validPassword) {
        console.error("Invalid password for user:", input.username);
        return { error: "Invalid username or password" };
      }
      if (argon2.needsRehash(user.passwordHash)) {
        const newHash = await argon2.hash(input.password);
        await tx
          .update(users)
          .set({ passwordHash: newHash })
          .where(eq(users.id, user.id));
      }

      return {
        id: user.id,
        username: input.username,
        balance: user.balance,
      };
    });

    if ("error" in user) {
      return { error: user.error };
    }

    console.log("User logged in:", input.username);
    const cookieStore = await cookies();
    cookieStore.set({
      name: getSessionCookieName(),
      value: await generateJWT(user.id),
      httpOnly: true,
      path: "/",
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 60 * 60 * 24, // 1 day
    });
    return {
      success: true,
      user: { username: user.username, balance: user.balance },
    } as const;
  } catch (error) {
    console.error("Login failed:", error);
    return { error: "Something went wrong. Please try again later." };
  }
}
