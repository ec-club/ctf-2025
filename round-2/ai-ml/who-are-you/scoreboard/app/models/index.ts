import { drizzle } from "drizzle-orm/libsql";
import { migrate } from "drizzle-orm/libsql/migrator";

import * as schema from "./schema";

const config = useRuntimeConfig();
const db = drizzle({
  connection: {
    url: config.dbPath,
  },
  schema,
});

let migrated = false;
export async function getDB() {
  if (!migrated) {
    await migrate(db, { migrationsFolder: "drizzle" });
    migrated = true;
  }
  return db;
}
