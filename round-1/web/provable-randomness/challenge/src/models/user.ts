import { nanoid } from "nanoid";
import { integer, sqliteTable, text } from "drizzle-orm/sqlite-core";

export const users = sqliteTable("users", {
  id: text()
    .primaryKey()
    .$defaultFn(() => nanoid()),
  username: text().notNull().unique(),
  passwordHash: text().notNull(),
  balance: integer().notNull().default(10),
  roundSeed: integer().notNull().default(0),
});
