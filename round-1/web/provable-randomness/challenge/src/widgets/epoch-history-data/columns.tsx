"use client";
import { format } from "date-fns";
import { ColumnDef } from "@tanstack/react-table";
import { ReactNode } from "react";

export type EpochHistoryData = {
  startTime: Date;
  endTime: Date;
  seed: ReactNode;
  proof: string;
};
export const epochHistoryColumns: ColumnDef<EpochHistoryData>[] = [
  {
    accessorKey: "startTime",
    header: "Start time",
    cell: ({ row }) => (
      <span>{format(row.original.startTime, "yyyy-MM-dd HH:mm:ss")}</span>
    ),
  },
  {
    accessorKey: "endTime",
    header: "End time",
    cell: ({ row }) => (
      <span>{format(row.original.endTime, "yyyy-MM-dd HH:mm:ss")}</span>
    ),
  },
  {
    accessorKey: "seed",
    header: "Seed",
    cell: ({ row }) =>
      typeof row.original.seed === "string" ? (
        <code>{row.original.seed}</code>
      ) : (
        row.original.seed
      ),
  },
  {
    accessorKey: "proof",
    header: "Proof",
    cell: ({ row }) => <code>{row.original.proof}</code>,
  },
];
