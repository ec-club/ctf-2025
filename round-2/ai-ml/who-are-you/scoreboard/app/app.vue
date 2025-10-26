<script setup lang="ts">
import type { NavigationMenuItem } from "@nuxt/ui";

const route = useRoute();

const items = computed<NavigationMenuItem[]>(() => [
  {
    label: "Submit solution",
    to: "/",
    active: route.path === "/",
  },
  {
    label: "Scoreboard",
    to: "/scoreboard",
    active: route.path === "/scoreboard",
  },
]);
</script>

<template>
  <UApp>
    <UHeader title="Who are you?">
      <UNavigationMenu :items="items" />
    </UHeader>
    <UMain>
      <NuxtLayout>
        <NuxtPage />
      </NuxtLayout>
    </UMain>
    <UFooter />
  </UApp>
</template>
