import z from "zod";

export const registerSchema = z.strictObject({
  username: z.string().min(3).max(32),
  password: z.string().min(8).max(64),
});
