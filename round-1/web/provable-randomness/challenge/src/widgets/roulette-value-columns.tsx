"use client";
import { ColumnDef } from "@tanstack/react-table";

export type RouletteValueData = {
  index: number;
  value: string;
  color: "red" | "black" | "green";
};
export const rouletteValueColumns: ColumnDef<RouletteValueData>[] = [
  {
    accessorKey: "index",
    header: "Index",
    cell: ({ row }) => <span>{row.original.index}</span>,
  },
  {
    accessorKey: "value",
    header: "Value",
    cell: ({ row }) => <span>{row.original.value}</span>,
  },
  {
    accessorKey: "color",
    header: "Color",
    cell: ({ row }) => (
      <span>
        {row.original.color[0].toUpperCase() + row.original.color.substring(1)}
      </span>
    ),
  },
];
