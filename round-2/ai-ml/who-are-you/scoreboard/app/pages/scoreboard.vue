<script setup lang="ts">
import { format } from "date-fns";
import type { TableColumn } from "@nuxt/ui";

import type { ScoreboardDataItem } from "~~/server/utils/scoreboard";

const { data: scoreboard, status } = await useFetch<ScoreboardDataItem[]>(
  "/api/scoreboard"
);

const columns: TableColumn<ScoreboardDataItem>[] = [
  {
    header: "Rank",
    cell: ({ row }) => row.index + 1,
  },
  {
    header: "User",
    accessorKey: "user",
  },
  {
    header: "Score",
    accessorKey: "score",
  },
  {
    header: "Submitted at",
    accessorFn: (row) => format(row.timestamp, "HH:mm:ss.SSS"),
  },
];
</script>

<template>
  <UContainer>
    <UCard class="max-w-4xl mx-auto my-8" flat>
      <div class="p-6">
        <section class="mt-6 w-full">
          <UTable v-if="scoreboard" :data="scoreboard" :columns="columns" />
          <p v-else-if="status === 'pending'">Loading...</p>
          <p v-else-if="status === 'error'">Failed to load scoreboard.</p>
        </section>
      </div>
    </UCard>
  </UContainer>
</template>
