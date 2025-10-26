import "server-only";
import ms from "ms";
import { shake256 } from "js-sha3";

import { getSecretKeyWithPurpose } from "@/core/auth/key";

import { rouletteSections } from "@/data/roulette";

async function getGameKey() {
  const rawKey = await getSecretKeyWithPurpose("game-seed");
  return await crypto.subtle.importKey(
    "raw",
    Buffer.from(rawKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
}

export function getCurrentEpoch() {
  return Math.floor(Date.now() / ms("5m"));
}

export async function getEpochSeed(epoch: number = getCurrentEpoch()) {
  const epochSeed = await crypto.subtle.sign(
    "HMAC",
    await getGameKey(),
    Buffer.from(`epoch-seed-${epoch}`, "utf-8")
  );
  return Buffer.from(epochSeed);
}
export async function getEpochProof(epoch: number = getCurrentEpoch()) {
  const epochSeed = await getEpochSeed(epoch);
  const encodedEpochSeed = new TextEncoder().encode(epochSeed.toString("hex"));
  const hash = await crypto.subtle.digest("SHA-256", encodedEpochSeed);
  return Buffer.from(hash).toString("hex");
}

export async function generateSpinResult(roundSeed: Buffer) {
  const epochSeed = await getEpochSeed();

  const hash = shake256.create(16);
  hash.update(epochSeed.toString("hex"));
  hash.update(roundSeed);
  const outputNumber = parseInt(hash.hex(), 16);
  // See: https://lemire.me/blog/2016/06/27/a-fast-alternative-to-the-modulo-reduction/
  return (outputNumber * rouletteSections.length) >> 16;
}
