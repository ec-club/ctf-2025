import { nanoid } from "nanoid";

import { getDB } from "~/models";
import { solutions } from "~/models/schema";

import { submitSolutionSchema } from "~/utils/validation";

function verifySolution({
  submission,
  solution,
}: {
  submission: string;
  solution: string;
}): number {
  let score = 0;
  for (let i = 0; i < submission.length; i++) {
    if (submission[i] === solution[i]) {
      score++;
    }
  }
  return score;
}

async function maskIPAddress(ip: string): Promise<string> {
  const hash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(ip)
  );
  return Buffer.from(hash).toString("base64url");
}

function getFlag(template: string) {
  return template
    .replace("$1", nanoid(8))
    .replace("$2", nanoid(16))
    .replace("$3", nanoid(8));
}

const invertData = (data: string): string =>
  data
    .split("")
    .map((char) => (char === "0" ? "1" : "0"))
    .join("");

export default defineEventHandler(async (event) => {
  const body = await readBody(event);
  const { data: submission } = submitSolutionSchema.parse(body);

  const { solution, flag } = useRuntimeConfig(event);
  const score = Math.max(
    verifySolution({ submission, solution }),
    verifySolution({ submission: invertData(submission), solution })
  );
  if (score < 700) {
    return { success: false };
  }

  const clientIP =
    getRequestIP(event, { xForwardedFor: true }) ??
    event.node.req.socket.remoteAddress;
  console.log(
    `User ${
      clientIP ?? "unknown"
    } submitted a correct solution with score: ${score}`
  );

  const db = await getDB();
  await db.insert(solutions).values({
    user: clientIP ? await maskIPAddress(clientIP) : "unknown",
    score,
    submission,
  });
  return { success: true, flag: getFlag(flag), score };
});
