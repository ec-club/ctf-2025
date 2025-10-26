import "server-only";
import { drizzle } from "drizzle-orm/libsql";
import { migrate } from "drizzle-orm/libsql/migrator";

import * as schema from "./schema";

export const db = drizzle({
  connection: {
    url: `file:${process.env.DB_PATH ?? "./app.db"}`,
  },
  schema,
});
await migrate(db, { migrationsFolder: "./migrations" });
