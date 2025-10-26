<script setup lang="ts">
import confetti from "canvas-confetti";
import type { FormSubmitEvent } from "@nuxt/ui";

import {
  submitSolutionSchema,
  type SubmitSolutionSchema,
} from "~/utils/validation";

const state = reactive<Partial<SubmitSolutionSchema>>({
  data: undefined,
});

const toast = useToast();
const solutionState = reactive<{ flag: string | null; score: number | null }>({
  flag: null,
  score: null,
});
const solutionText = computed(() =>
  solutionState.flag
    ? `Your score was ${solutionState.score}/1000 and your flag is ${solutionState.flag}`
    : ""
);

async function onSubmit(event: FormSubmitEvent<SubmitSolutionSchema>) {
  const result = await fetch("/api/submit", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(event.data),
  });
  if (!result.ok) {
    toast.add({
      color: "error",
      title: "Error",
      description: "Failed to submit solution. Please try again later.",
    });
    return;
  }

  const response = await result.json();
  if (!response.success) {
    toast.add({
      color: "warning",
      title: "Wrong solution",
      description: "The submitted solution is incorrect.",
    });
    return;
  }

  const duration = 5 * 1000;
  const animationEnd = Date.now() + duration;
  const defaults = { startVelocity: 30, spread: 360, ticks: 60, zIndex: 0 };
  const randomInRange = (min: number, max: number) =>
    Math.random() * (max - min) + min;
  const interval = window.setInterval(() => {
    const timeLeft = animationEnd - Date.now();
    if (timeLeft <= 0) {
      return clearInterval(interval);
    }
    const particleCount = 50 * (timeLeft / duration);
    confetti({
      ...defaults,
      particleCount,
      origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 },
    });
    confetti({
      ...defaults,
      particleCount,
      origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 },
    });
  }, 250);
  solutionState.flag = response.flag;
  solutionState.score = response.score;
}
</script>

<template>
  <UForm
    :schema="submitSolutionSchema"
    :state="state"
    class="space-y-4"
    @submit="onSubmit"
  >
    <UFormField label="Data" name="data">
      <UTextarea v-model="state.data" class="w-full" />
    </UFormField>
    <UButton type="submit">Submit</UButton>
    <UAlert
      v-if="solutionText"
      class="mt-4"
      title="Good job!"
      :description="solutionText"
    />
  </UForm>
</template>
