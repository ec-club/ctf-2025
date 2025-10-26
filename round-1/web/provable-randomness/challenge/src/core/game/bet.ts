"use server";
import z from "zod";
import { eq, sql } from "drizzle-orm";

import { db } from "@/models/db";
import { users } from "@/models/user";
import { rouletteSections } from "@/data/roulette";
import { getVerifiedSession } from "@/core/auth/verify";

import { betSchema } from "./bet.schema";
import { generateSpinResult } from "./randomness";

export async function placeBet(data: z.infer<typeof betSchema>) {
  if (!betSchema.safeParse(data).success) {
    return { error: "Bad request" };
  }
  const claims = await getVerifiedSession();
  if (!claims) {
    return { error: "Unauthorized" };
  }

  return await db.transaction(async (tx) => {
    const user = await tx.query.users.findFirst({
      where: eq(users.id, claims.userId),
      columns: {
        balance: true,
        roundSeed: true,
      },
    });
    if (!user) {
      return { error: "Unauthorized" };
    }
    if (user.balance < data.amount) {
      return { error: "Insufficient balance" };
    }

    await tx
      .update(users)
      .set({
        roundSeed: sql`${users.roundSeed} + 1`,
      })
      .where(eq(users.id, claims.userId));

    const roundSeed = Buffer.from(
      await crypto.subtle.digest(
        "SHA-256",
        new TextEncoder().encode(user.roundSeed.toString())
      )
    ).toString("hex");
    const spinResult = await generateSpinResult(
      Buffer.from(roundSeed, "ascii")
    );
    if (rouletteSections[spinResult].color !== data.color) {
      const [{ newBalance }] = await tx
        .update(users)
        .set({ balance: sql`${users.balance} - ${data.amount}` })
        .where(eq(users.id, claims.userId))
        .returning({ newBalance: users.balance });
      return {
        win: false,
        roundSeed,
        spinResult,
        newBalance,
      };
    }

    const winnings = data.color === "green" ? data.amount * 6 : data.amount;
    const [{ newBalance }] = await tx
      .update(users)
      .set({ balance: sql`${users.balance} + ${winnings}` })
      .where(eq(users.id, claims.userId))
      .returning({ newBalance: users.balance });
    return {
      win: true,
      roundSeed,
      spinResult,
      newBalance,
    };
  });
}
