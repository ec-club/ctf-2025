import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "sqlite",
  schema: "./app/models/schema.ts",
  out: "./drizzle",
});
