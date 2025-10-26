"use server";
import z from "zod";
import argon2 from "argon2";
import { eq } from "drizzle-orm";

import { db } from "@/models/db";
import { users } from "@/models/user";

import { registerSchema } from "./register.schema";

export async function registerUser(input: z.infer<typeof registerSchema>) {
  if (!registerSchema.safeParse(input).success) {
    return { error: "Bad request" };
  }

  const passwordHash = await argon2.hash(input.password);
  try {
    return await db.transaction(async (tx) => {
      const [user] = await tx
        .select({ id: users.id })
        .from(users)
        .where(eq(users.username, input.username))
        .limit(1);
      if (user) {
        return { error: "Username already taken" };
      }

      await tx.insert(users).values({
        username: input.username,
        passwordHash,
      });
      console.log("User registered:", input.username);
      return { success: true };
    });
  } catch (e) {
    console.error("Registration failed:", e);
    return { error: "Internal server error, please contact the author." };
  }
}
