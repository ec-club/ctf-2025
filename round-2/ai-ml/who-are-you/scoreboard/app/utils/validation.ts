import z from "zod";

export const submitSolutionSchema = z.strictObject({
  data: z
    .string("Data is required")
    .length(1000, "Length must be exactly 1000 characters")
    .regex(/^[01]+$/, "Data must be a binary string"),
});
export type SubmitSolutionSchema = z.infer<typeof submitSolutionSchema>;
