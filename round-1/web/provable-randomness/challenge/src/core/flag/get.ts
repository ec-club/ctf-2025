"use server";
import { nanoid } from "nanoid";
import { and, eq, gte } from "drizzle-orm";

import { db } from "@/models/db";
import { users } from "@/models/user";
import { getVerifiedSession } from "@/core/auth/verify";

import { FLAG_PRICE } from "@/data/config";

export async function getFlag() {
  const claims = await getVerifiedSession();
  if (!claims) {
    return { error: "Unauthorized" };
  }

  return await db.transaction(async (tx) => {
    const user = await tx.query.users.findFirst({
      where: eq(users.id, claims.userId),
      columns: { balance: true },
    });
    if (!user) {
      return { error: "User not found" };
    }

    if (user.balance < FLAG_PRICE) {
      return {
        error: `Insufficient balance. You need ${
          FLAG_PRICE - user.balance
        } more coins.`,
      };
    }

    const updatedRows = await tx
      .update(users)
      .set({ balance: user.balance - FLAG_PRICE })
      .where(and(eq(users.id, claims.userId), gte(users.balance, FLAG_PRICE)));
    if (updatedRows.rowsAffected === 0) {
      return { error: "Failed to update balance. Do you have enough funds?" };
    }

    const generatedFlag = process.env.FLAG?.replace("$1", nanoid(8)).replace(
      "$2",
      nanoid(8)
    );
    console.log("Generated flag:", generatedFlag);
    return {
      flag:
        generatedFlag ??
        "Flag was not found. Please create a ticket in Discord.",
    };
  });
}
