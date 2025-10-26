"use server";
import { getCurrentEpoch, getEpochSeed } from "@/core/game/randomness";

export async function revealSeed(epoch: number) {
  const currentEpoch = getCurrentEpoch();
  if (currentEpoch >= epoch) {
    return { error: "It's not time yet…" } as const;
  }
  const seed = await getEpochSeed(epoch);
  return { seed: seed.toString("hex") } as const;
}
