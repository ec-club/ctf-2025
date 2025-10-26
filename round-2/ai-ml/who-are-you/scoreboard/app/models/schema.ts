import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

export const solutions = sqliteTable("solutions", {
  id: integer().primaryKey({ autoIncrement: true }),
  user: text().notNull(),
  score: integer().notNull(),
  submission: text().notNull(),
  timestamp: integer({ mode: "timestamp_ms" })
    .notNull()
    .$defaultFn(() => new Date()),
});
