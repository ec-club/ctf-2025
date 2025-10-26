import { asc, desc } from "drizzle-orm";

import { getDB } from "~/models";
import { solutions } from "~/models/schema";

export type ScoreboardDataItem = {
  id: number;
  user: string;
  score: number;
  timestamp: Date;
};
export async function getScoreboardData() {
  const db = await getDB();
  const rankings = await db.query.solutions.findMany({
    columns: {
      submission: false,
    },
    limit: 100,
    orderBy: [desc(solutions.score), asc(solutions.timestamp)],
  });

  const seenUsers = new Set<string>();
  const scoreboardData: ScoreboardDataItem[] = [];

  for (const entry of rankings) {
    if (entry.user === "unknown") {
      scoreboardData.push(entry);
      continue;
    }
    if (seenUsers.has(entry.user)) {
      continue;
    }
    seenUsers.add(entry.user);
    scoreboardData.push(entry);
  }
  return scoreboardData;
}
