import z from "zod";

export const betSchema = z.strictObject({
  color: z.enum(["red", "green", "black"], { error: "Please select a color" }),
  amount: z.number().min(1).int("Amount must be an integer"),
});
